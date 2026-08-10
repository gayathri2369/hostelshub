import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import '../../main.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser!;
    final conversations = context.watch<ChatProvider>().conversationsForUser(user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        actions: [
          if (conversations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${conversations.length}',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  const Text('No messages yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'When you chat with a seller or a buyer contacts you, conversations will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary,
                          fontSize: 13, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 180,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Go Back'),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              separatorBuilder: (context, index) => const Divider(
                  height: 1, indent: 80, color: AppColors.divider),
              itemBuilder: (_, i) => _ConversationTile(
                conversation: conversations[i],
                currentUserId: user.id,
              ),
            ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  const _ConversationTile({required this.conversation, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final isBuyer = conversation.buyerId == currentUserId;
    final otherName = isBuyer ? conversation.sellerName : conversation.buyerName;
    final unread = conversation.unreadCountFor(currentUserId);
    final lastMsg = conversation.lastMessage;

    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.chat, arguments: {
        'conversationId': conversation.id,
        'otherPersonName': otherName,
        'productTitle': conversation.productTitle,
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                  child: Text(otherName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
                if (unread > 0)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 18, height: 18,
                      decoration: const BoxDecoration(
                          color: AppColors.secondary, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$unread',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(otherName,
                          style: TextStyle(
                              fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 15, color: AppColors.textPrimary)),
                      if (lastMsg != null)
                        Text(_formatTime(lastMsg.timestamp),
                            style: TextStyle(
                                fontSize: 11,
                                color: unread > 0 ? AppColors.primary : AppColors.textHint,
                                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Product tag
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 11, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(conversation.productTitle,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Last message
                  if (lastMsg != null)
                    Row(
                      children: [
                        if (lastMsg.senderId == currentUserId)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              lastMsg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                              size: 13,
                              color: lastMsg.isRead ? AppColors.info : AppColors.textHint,
                            ),
                          ),
                        Expanded(
                          child: Text(lastMsg.text,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: unread > 0
                                      ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontWeight: unread > 0
                                      ? FontWeight.w600 : FontWeight.normal)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Role badge
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isBuyer
                    ? AppColors.info.withValues(alpha: 0.1)
                    : AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isBuyer ? 'Buyer' : 'Seller',
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: isBuyer ? AppColors.info : AppColors.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}';
  }
}
