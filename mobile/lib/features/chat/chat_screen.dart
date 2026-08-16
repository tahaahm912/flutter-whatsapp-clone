import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String name;
  final String avatar;

  const ChatScreen({
    super.key,
    required this.name,
    required this.avatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  // Temporary local messages.
  //
  // This is only for testing the chat UI.
  // It does not communicate with the backend yet.
  final List<ChatMessage> _messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isMe: true,
          time: _currentTime(),
        ),
      );
    });

    _messageController.clear();

    _scrollToBottom();
  }

  // ============================================================
  // SCROLL TO BOTTOM
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // CURRENT TIME
  // ============================================================

  String _currentTime() {
    final now = DateTime.now();

    final hour = now.hour > 12
        ? now.hour - 12
        : now.hour == 0
            ? 12
            : now.hour;

    final minute = now.minute.toString().padLeft(2, '0');

    final period = now.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        titleSpacing: 0,

        title: Row(
          children: [
            _buildAvatar(),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 2),

                  const Text(
                    'online',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.videocam_outlined,
              color: AppColors.textPrimary,
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.call_outlined,
              color: AppColors.textPrimary,
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Column(
        children: [
          Expanded(
            child: _buildMessages(),
          ),

          _buildMessageInput(),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 42,
              color: AppColors.textSecondary,
            ),

            SizedBox(height: 10),

            Text(
              'No messages yet',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        12,
      ),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];

        return _buildMessageBubble(message);
      },
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,

      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 290,
        ),

        margin: const EdgeInsets.only(
          bottom: 8,
        ),

        padding: const EdgeInsets.fromLTRB(
          14,
          9,
          10,
          7,
        ),

        decoration: BoxDecoration(
          color: message.isMe
              ? AppColors.primary
              : AppColors.surface,

          borderRadius: BorderRadius.circular(16),

          border: message.isMe
              ? null
              : Border.all(
                  color: AppColors.textSecondary.withValues(
                    alpha: 0.12,
                  ),
                ),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,

          children: [
            Flexible(
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isMe
                      ? AppColors.surface
                      : AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Text(
              message.time,
              style: TextStyle(
                color: message.isMe
                    ? AppColors.surface.withValues(
                        alpha: 0.75,
                      )
                    : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),

            if (message.isMe) ...[
              const SizedBox(width: 3),

              const Icon(
                Icons.done_all,
                size: 14,
                color: Colors.white70,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE INPUT
  // ============================================================

  Widget _buildMessageInput() {
    return SafeArea(
      top: false,

      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          10,
          6,
          10,
          8,
        ),

        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 46,
                ),

                decoration: BoxDecoration(
                  color: AppColors.surface,

                  borderRadius: BorderRadius.circular(
                    24,
                  ),

                  border: Border.all(
                    color: AppColors.textSecondary.withValues(
                      alpha: 0.10,
                    ),
                  ),
                ),

                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.add,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    Expanded(
                      child: TextField(
                        controller: _messageController,

                        textCapitalization:
                            TextCapitalization.sentences,

                        minLines: 1,
                        maxLines: 4,

                        onSubmitted: (_) {
                          _sendMessage();
                        },

                        decoration: const InputDecoration(
                          hintText: 'Message',

                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                          ),

                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            GestureDetector(
              onTap: _sendMessage,

              child: Container(
                width: 46,
                height: 46,

                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.send_rounded,
                  color: AppColors.surface,
                  size: 21,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar() {
    return Container(
      width: 40,
      height: 40,

      decoration: BoxDecoration(
        shape: BoxShape.circle,

        color: AppColors.primary.withValues(
          alpha: 0.10,
        ),
      ),

      child: ClipOval(
        child: Image.asset(
          widget.avatar,
          fit: BoxFit.cover,

          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return Center(
              child: Text(
                widget.name.isNotEmpty
                    ? widget.name[0].toUpperCase()
                    : '?',

                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// CHAT MESSAGE MODEL
// ============================================================

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
  });
}