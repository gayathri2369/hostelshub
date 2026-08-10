import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../utils/supabase_config.dart';

class ChatProvider extends ChangeNotifier {
  final List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _conversationsChannel;

  static const _convKey = 'conversations';

  SupabaseClient get _sb => Supabase.instance.client;

  bool get isLoading => _isLoading;
  List<ConversationModel> get conversations => List.unmodifiable(_conversations);

  List<ConversationModel> conversationsForUser(String userId) =>
      _conversations
          .where((c) => c.buyerId == userId || c.sellerId == userId)
          .toList()
        ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

  ConversationModel? getConversation(String id) {
    try { return _conversations.firstWhere((c) => c.id == id); }
    catch (_) { return null; }
  }

  ConversationModel? findConversationForProduct({
    required String productId, required String buyerId,
  }) {
    try {
      return _conversations
          .firstWhere((c) => c.productId == productId && c.buyerId == buyerId);
    } catch (_) { return null; }
  }

  int totalUnreadFor(String userId) => _conversations
      .where((c) => c.buyerId == userId || c.sellerId == userId)
      .fold(0, (s, c) => s + c.unreadCountFor(userId));

  // ── Load all conversations ──────────────────────────────────────────────────
  Future<void> loadConversations(String userId) async {
    _isLoading = true;
    notifyListeners();

    if (SupabaseConfig.isConfigured) {
      await _loadFromSupabase(userId);
      _subscribeRealtime(userId);
    } else {
      await _loadLocal();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SUPABASE PATH
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadFromSupabase(String userId) async {
    try {
      final rows = await _sb
          .from(SupabaseConfig.conversationsTable)
          .select()
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('last_updated', ascending: false);

      _conversations.clear();
      for (final row in rows as List) {
        final r = row as Map<String, dynamic>;
        final msgs = await _fetchMessages(r['id'] as String);
        _conversations.add(ConversationModel.fromSupabase(r, msgs));
      }
    } catch (_) {}
  }

  Future<List<MessageModel>> _fetchMessages(String convId) async {
    try {
      final rows = await _sb
          .from(SupabaseConfig.messagesTable)
          .select()
          .eq('conversation_id', convId)
          .order('created_at', ascending: true);
      return (rows as List)
          .map((r) => MessageModel.fromSupabase(r as Map<String, dynamic>))
          .toList();
    } catch (_) { return []; }
  }

  void _subscribeRealtime(String userId) {
    _messagesChannel?.unsubscribe();
    _conversationsChannel?.unsubscribe();

    _messagesChannel = _sb
        .channel('public:messages:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.messagesTable,
          callback: (payload) {
            final msg = MessageModel.fromSupabase(payload.newRecord);
            final idx = _conversations.indexWhere((c) => c.id == msg.conversationId);
            if (idx != -1) {
              final updated = _conversations[idx].copyWith(
                messages: [..._conversations[idx].messages, msg],
                lastUpdated: msg.timestamp,
              );
              _conversations[idx] = updated;
              final moved = _conversations.removeAt(idx);
              _conversations.insert(0, moved);
              notifyListeners();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: SupabaseConfig.messagesTable,
          callback: (payload) {
            final updated = MessageModel.fromSupabase(payload.newRecord);
            final idx = _conversations.indexWhere((c) => c.id == updated.conversationId);
            if (idx != -1) {
              final msgs = _conversations[idx].messages
                  .map((m) => m.id == updated.id ? updated : m).toList();
              _conversations[idx] = _conversations[idx].copyWith(messages: msgs);
              notifyListeners();
            }
          },
        )
        .subscribe();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOCAL FALLBACK PATH
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_convKey);
      if (json != null) {
        final List decoded = jsonDecode(json);
        _conversations.clear();
        _conversations.addAll(decoded.map((e) => _convFromMap(e as Map<String, dynamic>)));
      }
    } catch (_) {}
  }

  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_convKey,
        jsonEncode(_conversations.map((c) => _convToMap(c)).toList()));
  }

  Map<String, dynamic> _convToMap(ConversationModel c) => {
    'id': c.id, 'productId': c.productId, 'productTitle': c.productTitle,
    'buyerId': c.buyerId, 'buyerName': c.buyerName,
    'sellerId': c.sellerId, 'sellerName': c.sellerName,
    'lastUpdated': c.lastUpdated.toIso8601String(),
    'messages': c.messages.map((m) => m.toMap()).toList(),
  };

  ConversationModel _convFromMap(Map<String, dynamic> m) => ConversationModel(
    id:           m['id'] as String,
    productId:    m['productId'] as String,
    productTitle: (m['productTitle'] as String?) ?? '',
    buyerId:      m['buyerId'] as String,
    buyerName:    (m['buyerName'] as String?) ?? '',
    sellerId:     m['sellerId'] as String,
    sellerName:   (m['sellerName'] as String?) ?? '',
    lastUpdated:  DateTime.parse(m['lastUpdated'] as String),
    messages: (m['messages'] as List)
        .map((x) => MessageModel.fromMap(x as Map<String, dynamic>))
        .toList(),
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  PUBLIC OPERATIONS  (routes to Supabase or local)
  // ══════════════════════════════════════════════════════════════════════════

  Future<ConversationModel> startConversation({
    required String productId, required String productTitle,
    required String buyerId, required String buyerName,
    required String sellerId, required String sellerName,
  }) async {
    final existing = findConversationForProduct(
        productId: productId, buyerId: buyerId);
    if (existing != null) return existing;

    if (SupabaseConfig.isConfigured) {
      try {
        final row = await _sb
            .from(SupabaseConfig.conversationsTable)
            .upsert({
              'product_id': productId, 'product_title': productTitle,
              'buyer_id': buyerId, 'buyer_name': buyerName,
              'seller_id': sellerId, 'seller_name': sellerName,
            }, onConflict: 'product_id,buyer_id')
            .select()
            .single();
        final conv = ConversationModel.fromSupabase(
            (row as Map).cast<String, dynamic>(), []);
        if (!_conversations.any((c) => c.id == conv.id)) {
          _conversations.insert(0, conv);
          notifyListeners();
        }
        return conv;
      } catch (_) {}
    }

    // Local path
    final conv = ConversationModel(
      id: const Uuid().v4(),
      productId: productId, productTitle: productTitle,
      buyerId: buyerId, buyerName: buyerName,
      sellerId: sellerId, sellerName: sellerName,
      messages: [], lastUpdated: DateTime.now(),
    );
    _conversations.insert(0, conv);
    if (!SupabaseConfig.isConfigured) await _saveLocal();
    notifyListeners();
    return conv;
  }

  Future<void> sendMessage({
    required String conversationId, required String senderId,
    required String senderName, required String text,
  }) async {
    if (SupabaseConfig.isConfigured) {
      try {
        await _sb.from(SupabaseConfig.messagesTable).insert({
          'conversation_id': conversationId,
          'sender_id': senderId, 'sender_name': senderName, 'text': text,
        });
        await _sb.from(SupabaseConfig.conversationsTable)
            .update({'last_updated': DateTime.now().toIso8601String()})
            .eq('id', conversationId);
      } catch (_) {}
      return; // Realtime will update UI
    }

    // Local path
    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    final msg = MessageModel(
      id: const Uuid().v4(), conversationId: conversationId,
      senderId: senderId, senderName: senderName,
      text: text, timestamp: DateTime.now(),
    );
    final updated = _conversations[idx].copyWith(
      messages: [..._conversations[idx].messages, msg],
      lastUpdated: DateTime.now(),
    );
    _conversations[idx] = updated;
    final moved = _conversations.removeAt(idx);
    _conversations.insert(0, moved);
    await _saveLocal();
    notifyListeners();
  }

  Future<void> markAllRead({
    required String conversationId, required String userId,
  }) async {
    if (SupabaseConfig.isConfigured) {
      try {
        await _sb.from(SupabaseConfig.messagesTable)
            .update({'is_read': true})
            .eq('conversation_id', conversationId)
            .neq('sender_id', userId)
            .eq('is_read', false);
      } catch (_) {}
    }

    final idx = _conversations.indexWhere((c) => c.id == conversationId);
    if (idx != -1) {
      final msgs = _conversations[idx].messages.map((m) {
        if (m.senderId != userId && !m.isRead) return m.copyWith(isRead: true);
        return m;
      }).toList();
      _conversations[idx] = _conversations[idx].copyWith(messages: msgs);
      if (!SupabaseConfig.isConfigured) await _saveLocal();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _conversationsChannel?.unsubscribe();
    super.dispose();
  }

  /// Call on logout so next login gets a fresh load
  void reset() {
    _conversations.clear();
    _messagesChannel?.unsubscribe();
    _conversationsChannel?.unsubscribe();
    _messagesChannel = null;
    _conversationsChannel = null;
    notifyListeners();
  }
}
