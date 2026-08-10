class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  MessageModel copyWith({
    String? id, String? conversationId, String? senderId,
    String? senderName, String? text, DateTime? timestamp, bool? isRead,
  }) {
    return MessageModel(
      id:             id             ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId:       senderId       ?? this.senderId,
      senderName:     senderName     ?? this.senderName,
      text:           text           ?? this.text,
      timestamp:      timestamp      ?? this.timestamp,
      isRead:         isRead         ?? this.isRead,
    );
  }

  factory MessageModel.fromSupabase(Map<String, dynamic> row) {
    return MessageModel(
      id:             row['id']              as String,
      conversationId: row['conversation_id'] as String,
      senderId:       row['sender_id']       as String,
      senderName:     (row['sender_name']    as String?) ?? '',
      text:           (row['text']           as String?) ?? '',
      isRead:         (row['is_read']        as bool?)   ?? false,
      timestamp: DateTime.parse(
        (row['created_at'] as String?) ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toSupabase() => {
    'conversation_id': conversationId,
    'sender_id':       senderId,
    'sender_name':     senderName,
    'text':            text,
  };

  // Legacy helpers
  Map<String, dynamic> toMap() => {
    'id':             id,
    'conversationId': conversationId,
    'senderId':       senderId,
    'senderName':     senderName,
    'text':           text,
    'timestamp':      timestamp.toIso8601String(),
    'isRead':         isRead,
  };

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id:             (map['id']             as String?) ?? '',
      conversationId: (map['conversationId'] as String?) ?? '',
      senderId:       (map['senderId']       as String?) ?? '',
      senderName:     (map['senderName']     as String?) ?? '',
      text:           (map['text']           as String?) ?? '',
      isRead:         (map['isRead']         as bool?)   ?? false,
      timestamp: DateTime.parse(
        (map['timestamp'] as String?) ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class ConversationModel {
  final String id;
  final String productId;
  final String productTitle;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final List<MessageModel> messages;
  final DateTime lastUpdated;

  ConversationModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.messages,
    required this.lastUpdated,
  });

  MessageModel? get lastMessage =>
      messages.isNotEmpty ? messages.last : null;

  int unreadCountFor(String userId) =>
      messages.where((m) => !m.isRead && m.senderId != userId).length;

  ConversationModel copyWith({
    String? id, String? productId, String? productTitle,
    String? buyerId, String? buyerName, String? sellerId,
    String? sellerName, List<MessageModel>? messages, DateTime? lastUpdated,
  }) {
    return ConversationModel(
      id:           id           ?? this.id,
      productId:    productId    ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      buyerId:      buyerId      ?? this.buyerId,
      buyerName:    buyerName    ?? this.buyerName,
      sellerId:     sellerId     ?? this.sellerId,
      sellerName:   sellerName   ?? this.sellerName,
      messages:     messages     ?? this.messages,
      lastUpdated:  lastUpdated  ?? this.lastUpdated,
    );
  }

  factory ConversationModel.fromSupabase(
      Map<String, dynamic> row, List<MessageModel> messages) {
    return ConversationModel(
      id:           row['id']            as String,
      productId:    row['product_id']    as String,
      productTitle: (row['product_title'] as String?) ?? '',
      buyerId:      row['buyer_id']      as String,
      buyerName:    (row['buyer_name']   as String?) ?? '',
      sellerId:     row['seller_id']     as String,
      sellerName:   (row['seller_name']  as String?) ?? '',
      messages:     messages,
      lastUpdated: DateTime.parse(
        (row['last_updated'] as String?) ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toSupabase() => {
    'product_id':    productId,
    'product_title': productTitle,
    'buyer_id':      buyerId,
    'buyer_name':    buyerName,
    'seller_id':     sellerId,
    'seller_name':   sellerName,
  };
}
