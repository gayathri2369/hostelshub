import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherPersonName;
  final String productTitle;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherPersonName,
    required this.productTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markRead();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _markRead() {
    final user = context.read<AuthProvider>().currentUser!;
    context.read<ChatProvider>().markAllRead(
      conversationId: widget.conversationId,
      userId: user.id,
    );
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AuthProvider>().currentUser!;
    setState(() => _isSending = true);
    _msgCtrl.clear();
    await context.read<ChatProvider>().sendMessage(
      conversationId: widget.conversationId,
      senderId: user.id,
      senderName: user.name,
      text: text,
    );
    setState(() => _isSending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final chatProvider = context.watch<ChatProvider>();
    final conversation = chatProvider.getConversation(widget.conversationId);
    final messages = conversation?.messages ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherPersonName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text(widget.productTitle,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(widget.otherPersonName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Product context chip ─────────────────────────────────────────
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Re: ${widget.productTitle}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // ── Messages list ────────────────────────────────────────────────
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 32, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text('Start the conversation!',
                            style: TextStyle(fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary, fontSize: 15)),
                        const SizedBox(height: 6),
                        const Text('Ask about the product or make an offer.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      final isMe = msg.senderId == user.id;
                      final showDate = i == 0 ||
                          !_sameDay(messages[i - 1].timestamp, msg.timestamp);
                      return Column(
                        children: [
                          if (showDate) _DateDivider(date: msg.timestamp),
                          _MessageBubble(message: msg, isMe: isMe),
                        ],
                      );
                    },
                  ),
          ),

          // ── Input bar ────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgCtrl,
                            maxLines: 4,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: _isSending ? AppColors.textHint : AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Message Bubble ───────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                  fontSize: 14, height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_formatTime(message.timestamp),
                    style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 13,
                    color: message.isRead ? AppColors.info : AppColors.textHint,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

// ─── Date Divider ─────────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
          'Jul','Aug','Sep','Oct','Nov','Dec'];
      label = '${date.day} ${months[date.month - 1]}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600)),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}
