import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../core/database/app_database.dart' as database;
import '../chat/data/repositories/conversation_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedFilter = 0;
  int _selectedBottomNav = 2;

  final List<String> _filters = [
    'All',
    'Unread',
    'Groups',
    'Favorites',
  ];

  final database.AppDatabase _database = database.AppDatabase();
  late final ConversationRepository _conversationRepository;

  List<Conversation> _conversations = [];
  bool _isLoadingConversations = true;
  String? _conversationError;

  @override
  void initState() {
    super.initState();
    _conversationRepository = ConversationRepository(database: _database);
    _loadConversations();
  }

  @override
  void dispose() {
    _conversationRepository.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoadingConversations = true;
      _conversationError = null;
    });

    try {
      final cached = await _conversationRepository.getCachedConversations();
      if (mounted && cached.isNotEmpty) {
        setState(() {
          _conversations = cached.map(_toUiConversation).toList();
        });
      }

      final conversations = await _conversationRepository.syncConversations();

      if (!mounted) {
        return;
      }

      setState(() {
        _conversations = conversations.map(_toUiConversation).toList();
        _isLoadingConversations = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final cached = await _conversationRepository.getCachedConversations();

      if (!mounted) {
        return;
      }

      setState(() {
        _conversations = cached.map(_toUiConversation).toList();
        _isLoadingConversations = false;
        _conversationError = cached.isEmpty
            ? 'Unable to load conversations'
            : null;
      });
    }
  }

  Conversation _toUiConversation(
    database.Conversation conversation,
  ) {
    return Conversation(
      conversationId: conversation.conversationId,
      otherUserId: conversation.otherUserId,
      name: conversation.otherUserName,
      message: conversation.lastMessage ?? 'No messages yet',
      time: _formatConversationTime(
        conversation.lastMessageAt ?? conversation.updatedAt,
      ),
      avatar: conversation.otherUserAvatar ?? '',
      unreadCount: conversation.unreadCount,
    );
  }

  String _formatConversationTime(DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();

    if (now.year == local.year &&
        now.month == local.month &&
        now.day == local.day) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      final period = local.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == local.year &&
        yesterday.month == local.month &&
        yesterday.day == local.day) {
      return 'Yesterday';
    }

    return '${local.day}/${local.month}/${local.year}';
  }

  // --------------------------------------------------------------------------
  // FILTERED CONVERSATIONS
  // --------------------------------------------------------------------------

  List<Conversation> get filteredConversations {
    switch (_selectedFilter) {
      case 1:
        return _conversations
            .where((conversation) => conversation.unreadCount > 0)
            .toList();

      case 2:
        return _conversations
            .where((conversation) => conversation.isGroup)
            .toList();

      case 3:
        return _conversations
            .where((conversation) => conversation.isFavorite)
            .toList();

      default:
        return _conversations;
    }
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSearchBar(),
            _buildFilters(),

            Expanded(
              child: _buildConversationList(),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/new-contact');
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        child: const Icon(
          Icons.add,
          size: 28,
        ),
      ),
    );
  }

  // ==========================================================================
  // TOP BAR
  // ==========================================================================

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        2,
      ),
      child: Row(
        children: [
          // BluLink title
          const Text(
            'BluLink',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              letterSpacing: -1.2,
            ),
          ),

          const Spacer(),

          // Camera
          _topBarButton(
            icon: Icons.camera_alt_outlined,
            onTap: () {
              _showComingSoon('Camera');
            },
          ),

          const SizedBox(width: 8),

          // New contact
          _topBarButton(
            icon: Icons.person_outline,
            filled: true,
            onTap: () {
              context.push('/profile');
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TITLE
  // ==========================================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.15),
          ),
        ),
        child: const TextField(
          decoration: InputDecoration(
            border: InputBorder.none,

            prefixIcon: Icon(
              Icons.search,
              color: AppColors.textSecondary,
              size: 21,
            ),

            hintText: 'Search',

            hintStyle: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),

            contentPadding: EdgeInsets.symmetric(
              vertical: 10,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // FILTERS
  // ==========================================================================

  Widget _buildFilters() {
    return Column(
      children: [
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final selected = _selectedFilter == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  margin: const EdgeInsets.only(
                    right: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary.withOpacity(0.25)
                          : AppColors.textSecondary
                              .withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    _filters[index],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 4),
      ],
    );
  }

  // ==========================================================================
  // CONVERSATION LIST
  // ==========================================================================

  Widget _buildConversationList() {
    final conversations = filteredConversations;

    if (_isLoadingConversations && conversations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_conversationError != null && conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Unable to load conversations',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loadConversations,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (conversations.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadConversations,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Center(
              child: Text(
                'No conversations',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.only(
        top: 4,
      ),

      itemCount: conversations.length,

      separatorBuilder: (_, __) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 88,
          ),
          child: Divider(
            height: 1,
            thickness: 0.7,
            color: AppColors.textSecondary.withOpacity(0.15),
          ),
        );
      },

      itemBuilder: (context, index) {
        return _buildConversationTile(
          conversations[index],
        );
      },
      ),
    );
  }

  // ==========================================================================
  // CONVERSATION TILE
  // ==========================================================================

  Widget _buildConversationTile(
    Conversation conversation,
  ) {
    return InkWell(
      onTap: () {
        // IMPORTANT:
        // Clicking a chat opens the ChatScreen.
        //
        // The chat name and avatar are passed to ChatScreen.

        context.push(
          '/chat',
          extra: {
            'name': conversation.name,
            'avatar': conversation.avatar,
            'conversationId': conversation.conversationId,
          },
        );
      },

      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(conversation),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ----------------------------------------------------------
                  // NAME
                  // ----------------------------------------------------------

                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          conversation.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      if (conversation.isGroup) ...[
                        const SizedBox(width: 5),

                        const Icon(
                          Icons.group_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ],

                      if (conversation.isFavorite) ...[
                        const SizedBox(width: 4),

                        const Icon(
                          Icons.star,
                          size: 13,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 3),

                  // ----------------------------------------------------------
                  // MESSAGE PREVIEW
                  // ----------------------------------------------------------

                  Row(
                    children: [
                      if (conversation.isTyping)
                        const Padding(
                          padding: EdgeInsets.only(
                            right: 3,
                          ),
                          child: Icon(
                            Icons.graphic_eq,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),

                      Flexible(
                        child: Text(
                          conversation.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: conversation.isTyping
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: conversation.isTyping
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (conversation.reply != null) ...[
                    const SizedBox(height: 1),

                    Text(
                      conversation.reply!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // --------------------------------------------------------------
            // TIME + STATUS
            // --------------------------------------------------------------

            SizedBox(
              width: 54,

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,

                children: [
                  Text(
                    conversation.time,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: conversation.unreadCount > 0
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (conversation.isPinned)
                        const Icon(
                          Icons.push_pin,
                          size: 17,
                          color: AppColors.primary,
                        ),

                      if (conversation.isMuted)
                        const Icon(
                          Icons.notifications_off_outlined,
                          size: 17,
                          color: AppColors.textSecondary,
                        ),

                      if (conversation.unreadCount > 0) ...[
                        if (conversation.isPinned ||
                            conversation.isMuted)
                          const SizedBox(width: 5),

                        Container(
                          width: 21,
                          height: 21,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: AppColors.surface,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // AVATAR
  // ==========================================================================

  Widget _buildAvatar(
    Conversation conversation,
  ) {
    return Container(
      width: 53,
      height: 53,

      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.10),
      ),

      child: ClipOval(
        child: Image.asset(
          conversation.avatar,
          fit: BoxFit.cover,

          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              color: AppColors.primary.withOpacity(0.10),

              alignment: Alignment.center,

              child: Text(
                conversation.name.isNotEmpty
                    ? conversation.name[0].toUpperCase()
                    : '?',

                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // BOTTOM NAVIGATION
  // ==========================================================================

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,

        border: Border(
          top: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.15),
            width: 0.7,
          ),
        ),
      ),

      child: SafeArea(
        child: SizedBox(
          height: 64,

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: [
              _bottomNavItem(
                icon: Icons.update_outlined,
                label: 'Updates',
                index: 0,
              ),

              _bottomNavItem(
                icon: Icons.call_outlined,
                label: 'Calls',
                index: 1,
              ),

              _bottomNavItem(
                icon: Icons.chat_bubble,
                label: 'Chats',
                index: 2,
              ),

              _bottomNavItem(
                icon: Icons.people_outline,
                label: 'Groups',
                index: 3,
              ),

              _bottomNavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // BOTTOM NAV ITEM
  // ==========================================================================

  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected = _selectedBottomNav == index;

    return GestureDetector(
      onTap: () {
        if (index == 4) {
          // Settings → Profile
          context.push('/profile');
          return;
        }

        setState(() {
          _selectedBottomNav = index;
        });
      },

      child: SizedBox(
        width: 65,

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              icon,
              size: 23,
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),

            const SizedBox(height: 4),

            Text(
              label,

              style: TextStyle(
                fontSize: 10.5,

                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.w400,

                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TOP BAR BUTTON
  // ==========================================================================

  Widget _topBarButton({
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 36,
        height: 36,

        decoration: BoxDecoration(
          color: filled
              ? AppColors.primary
              : AppColors.surface,

          shape: BoxShape.circle,

          border: Border.all(
            color: AppColors.textSecondary.withOpacity(0.15),
          ),
        ),

        child: Icon(
          icon,
          size: 20,

          color: filled
              ? AppColors.surface
              : AppColors.textPrimary,
        ),
      ),
    );
  }

  // ==========================================================================
  // TEMPORARY ACTION
  // ==========================================================================

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title coming soon'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// =============================================================================
// CONVERSATION MODEL
// =============================================================================

class Conversation {
  final String conversationId;
  final String otherUserId;
  final String name;
  final String message;
  final String time;
  final String avatar;

  final int unreadCount;

  final bool isPinned;
  final bool isTyping;
  final bool isGroup;
  final bool isMuted;
  final bool isFavorite;

  final String? reply;

  Conversation({
    required this.conversationId,
    required this.otherUserId,
    required this.name,
    required this.message,
    required this.time,
    required this.avatar,

    this.unreadCount = 0,

    this.isPinned = false,
    this.isTyping = false,
    this.isGroup = false,
    this.isMuted = false,
    this.isFavorite = false,

    this.reply,
  });
}