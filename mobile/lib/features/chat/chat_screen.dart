import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/database/app_database.dart';
import '../../core/storage/secure_storage.dart';
import '../../features/chat/data/repositories/message_repository.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String name;
  final String avatar;

  const ChatScreen({
    super.key,
    required this.conversationId,
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

  late final AppDatabase _database;
  late final ApiClient _apiClient;
  late final MessageRepository _messageRepository;

  List<Message> _messages = [];

  bool _loading = true;
  bool _sending = false;
  bool _repositoryInitialized = false;

  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();

    _database = AppDatabase();
    _apiClient = ApiClient();

    _initializeChat();
  }

  // ============================================================
  // INITIALIZE CHAT
  // ============================================================

  Future<void> _initializeChat() async {
    try {
      final storage = SecureStorage();

      final userId = await storage.getUserId();

      // ----------------------------------------------------------
      // Make sure a logged-in user ID exists.
      // ----------------------------------------------------------

      if (userId == null || userId.trim().isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _loading = false;
          _error = 'Unable to identify logged-in user';
        });

        debugPrint(
          'CHAT ERROR: user_id not found in SecureStorage',
        );

        return;
      }

      _currentUserId = userId.trim();

      debugPrint(
        'CURRENT USER ID: $_currentUserId',
      );

      // ----------------------------------------------------------
      // Create MessageRepository using the actual logged-in user.
      // ----------------------------------------------------------

      _messageRepository = MessageRepository(
        apiClient: _apiClient,
        database: _database,
        currentUserId: _currentUserId!,
      );

      _repositoryInitialized = true;

      // ----------------------------------------------------------
      // Load messages after repository initialization.
      // ----------------------------------------------------------

      await _loadMessages();
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint('CHAT INITIALIZATION ERROR: $e');

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = 'Failed to initialize chat: $e';
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _database.close();

    super.dispose();
  }

  // ============================================================
  // LOAD MESSAGES
  // ============================================================

  Future<void> _loadMessages() async {
    if (!_repositoryInitialized) {
      return;
    }

    try {
      final messages =
          await _messageRepository.getMessages(
        widget.conversationId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = messages;
        _loading = false;
        _error = null;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) {
        return;
      }

      debugPrint('LOAD MESSAGES ERROR: $e');

      if (!mounted) {
        return;
      }
      
      setState(() {
        _loading = false;
        _error = 'Failed to load messages: $e';
      });
    }
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _sending) {
      return;
    }

    if (!_repositoryInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chat is still initializing',
          ),
        ),
      );

      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final message =
          await _messageRepository.sendMessage(
        conversationId: widget.conversationId,
        text: text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages = [
          ..._messages,
          message,
        ];

        _sending = false;
      });

      _messageController.clear();

      _scrollToBottom();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _sending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to send message',
          ),
        ),
      );

      debugPrint(
        'SEND MESSAGE ERROR: $e',
      );
    }
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 250,
        ),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // TIME
  // ============================================================

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour == 0
            ? 12
            : dateTime.hour;

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    final period =
        dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // ============================================================
  // BUILD
  // ============================================================

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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
  // MESSAGE LIST
  // ============================================================

  Widget _buildMessages() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 42,
              color: AppColors.textSecondary,
            ),

            const SizedBox(height: 10),

            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _initializeChat,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

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

  Widget _buildMessageBubble(Message message) {
    debugPrint(
  'UI MESSAGE => '
  'content=${message.content} | '
  'senderId=${message.senderId} | '
  'isMe=${message.isMe}',
);
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

          borderRadius: BorderRadius.circular(
            16,
          ),

          border: message.isMe
              ? null
              : Border.all(
                  color: AppColors.textSecondary
                      .withValues(
                    alpha: 0.12,
                  ),
                ),
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment:
              CrossAxisAlignment.end,

          children: [
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(
                  color: message.isMe
                      ? AppColors.surface
                      : AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Text(
              _formatTime(
                message.sentAt,
              ),
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
              const SizedBox(
                width: 3,
              ),

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
  // INPUT
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

                  borderRadius:
                      BorderRadius.circular(24),

                  border: Border.all(
                    color: AppColors.textSecondary
                        .withValues(
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
                        color:
                            AppColors.textSecondary,
                      ),
                    ),

                    Expanded(
                      child: TextField(
                        controller:
                            _messageController,

                        textCapitalization:
                            TextCapitalization.sentences,

                        minLines: 1,
                        maxLines: 4,

                        onSubmitted: (_) {
                          _sendMessage();
                        },

                        decoration:
                            const InputDecoration(
                          hintText: 'Message',

                          hintStyle: TextStyle(
                            color:
                                AppColors.textSecondary,
                          ),

                          border:
                              InputBorder.none,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons
                            .emoji_emotions_outlined,
                        color:
                            AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            GestureDetector(
              onTap: _sending
                  ? null
                  : _sendMessage,

              child: Container(
                width: 46,
                height: 46,

                decoration:
                    const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),

                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              AppColors.surface,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color:
                            AppColors.surface,
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