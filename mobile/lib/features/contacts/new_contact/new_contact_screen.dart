import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/features/contacts/data/repositories/user_repository.dart';
import 'package:mobile/features/chat/data/repositories/conversation_repository.dart';

class NewContactScreen extends StatefulWidget {
  const NewContactScreen({super.key});

  @override
  State<NewContactScreen> createState() => _NewContactScreenState();
}

class _NewContactScreenState extends State<NewContactScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final UserRepository _userRepository = UserRepository();
  final ConversationRepository _conversationRepository =
      ConversationRepository();

  final List<String> _recentSearches = [
    'usamaahmed@example.com',
    'jabirkhan@example.com',
  ];

  bool _isSearching = false;
  bool _isCreatingConversation = false;

  UserSearchResult? _searchResult;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEARCH USER
  // ============================================================

  Future<void> _searchUser() async {
    final email = _searchController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an email address.';
        _searchResult = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResult = null;
      _errorMessage = null;
    });

    try {
      final user =
          await _userRepository.searchUserByEmail(email);

      if (!mounted) return;

      setState(() {
        _searchResult = user;
        _isSearching = false;
      });

      // Add to recent searches if not already there.
      if (!_recentSearches.contains(email)) {
        setState(() {
          _recentSearches.insert(0, email);

          if (_recentSearches.length > 5) {
            _recentSearches.removeLast();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSearching = false;

        if (e.toString().contains('USER_NOT_FOUND')) {
          _errorMessage =
              'No user found with this email.';
        } else if (e.toString().contains('INVALID_SEARCH')) {
          _errorMessage =
              'Please enter a valid email address.';
        } else {
          _errorMessage =
              'Could not search for the user. Please try again.';
        }
      });
    }
  }

  // ============================================================
  // CREATE CONVERSATION
  // ============================================================

  Future<void> _openConversation() async {
    final user = _searchResult;

    if (user == null) {
      return;
    }

    setState(() {
      _isCreatingConversation = true;
      _errorMessage = null;
    });

    try {
      final conversationId =
          await _conversationRepository.createConversation(
        otherUserId: user.id,
      );

      if (!mounted) return;

      setState(() {
        _isCreatingConversation = false;
      });

      // Open ChatScreen with the conversation ID.
      context.push(
        '/chat',
        extra: {
          'conversationId': conversationId,
          'name': user.name,
          'avatar': user.profilePhotoUrl ?? '',
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCreatingConversation = false;
        _errorMessage =
            'Could not open conversation. Please try again.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create conversation: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // RECENT SEARCH
  // ============================================================

  void _selectRecentSearch(String email) {
    _searchController.text = email;

    _searchController.selection =
        TextSelection.fromPosition(
      TextPosition(
        offset: _searchController.text.length,
      ),
    );

    _searchUser();
  }

  void _removeRecentSearch(String email) {
    setState(() {
      _recentSearches.remove(email);
    });
  }

  void _clearRecentSearches() {
    setState(() {
      _recentSearches.clear();
    });
  }

  void _clearSearchResult() {
    setState(() {
      _searchResult = null;
      _errorMessage = null;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
          ),
          color: AppColors.textPrimary,
          onPressed: () {
            context.pop();
          },
        ),

        title: const Text(
          'New Contact',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            24,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ==================================================
              // SEARCH BOX
              // ==================================================

              Container(
                height: 52,

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),

                child: TextField(
                  controller: _searchController,

                  keyboardType:
                      TextInputType.emailAddress,

                  textInputAction:
                      TextInputAction.search,

                  onSubmitted: (_) {
                    _searchUser();
                  },

                  decoration: InputDecoration(
                    hintText: 'Search by email',

                    hintStyle: TextStyle(
                      color:
                          AppColors.textSecondary,
                      fontSize: 14,
                    ),

                    prefixIcon: const Icon(
                      Icons.search,
                      color:
                          AppColors.textSecondary,
                    ),

                    suffixIcon:
                        _searchController.text
                                .isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController
                                      .clear();

                                  _clearSearchResult();

                                  setState(() {});
                                },
                              )
                            : null,

                    border: InputBorder.none,

                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                  ),

                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // SEARCH BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  onPressed:
                      _isSearching ||
                              _isCreatingConversation
                          ? null
                          : _searchUser,

                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),

                  child: _isSearching
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Search User',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // SEARCH RESULT
              // ==================================================

              if (_searchResult != null)
                _buildSearchResult(),

              // ==================================================
              // ERROR
              // ==================================================

              if (_errorMessage != null)
                _buildError(),

              // ==================================================
              // RECENT SEARCHES
              // ==================================================

              if (_searchResult == null &&
                  _errorMessage == null)
                _buildRecentSearches(),

              const SizedBox(height: 32),

              // ==================================================
              // INFORMATION
              // ==================================================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.06),

                  borderRadius:
                      BorderRadius.circular(16),
                ),

                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Icon(
                      Icons.info_outline,
                      color:
                          AppColors.primary,
                      size: 21,
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Text(
                        'Enter the email address connected to the BluLink account to find a user and start a conversation.',
                        style: TextStyle(
                          color:
                              AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH RESULT WIDGET
  // ============================================================

  Widget _buildSearchResult() {
    final user = _searchResult!;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,

            decoration: BoxDecoration(
              color: AppColors.primary
                  .withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),

            child: user.profilePhotoUrl != null
                ? ClipOval(
                    child: Image.network(
                      user.profilePhotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, _, _) {
                        return const Icon(
                          Icons.person,
                          color:
                              AppColors.primary,
                          size: 28,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 28,
                  ),
          ),

          const SizedBox(width: 14),

          // User information
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color:
                        AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                if (user.about != null &&
                    user.about!.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    user.about!,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color:
                          AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ====================================================
          // CHAT BUTTON
          // ====================================================

          IconButton(
            onPressed:
                _isCreatingConversation
                    ? null
                    : _openConversation,

            icon: _isCreatingConversation
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.chat_outlined,
                    color:
                        AppColors.primary,
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR WIDGET
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color:
            Colors.red.withValues(alpha: 0.06),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.red.withValues(alpha: 0.15),
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.person_off_outlined,
            color: Colors.red,
            size: 36,
          ),

          const SizedBox(height: 10),

          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed:
                _isSearching
                    ? null
                    : _searchUser,

            child: const Text(
              'Try Again',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT SEARCHES
  // ============================================================

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(
                color:
                    AppColors.textPrimary,
                fontSize: 17,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            if (_recentSearches.isNotEmpty)
              TextButton(
                onPressed:
                    _clearRecentSearches,

                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color:
                        AppColors.primary,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        if (_recentSearches.isEmpty)
          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.symmetric(
              vertical: 40,
              horizontal: 20,
            ),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),

            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 42,
                  color:
                      Colors.grey.shade400,
                ),

                const SizedBox(height: 12),

                const Text(
                  'No recent searches',
                  style: TextStyle(
                    color:
                        AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Search for a user by their email address.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),

            child: Column(
              children: List.generate(
                _recentSearches.length,
                (index) {
                  final email =
                      _recentSearches[index];

                  return Column(
                    children: [
                      ListTile(
                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 5,
                        ),

                        leading: Container(
                          width: 44,
                          height: 44,

                          decoration:
                              BoxDecoration(
                            color: AppColors
                                .primary
                                .withValues(
                              alpha: 0.10,
                            ),
                            shape:
                                BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.email_outlined,
                            color:
                                AppColors.primary,
                            size: 21,
                          ),
                        ),

                        title: Text(
                          email,
                          style:
                              const TextStyle(
                            color:
                                AppColors
                                    .textPrimary,
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        subtitle:
                            const Text(
                          'Search again',
                          style: TextStyle(
                            color:
                                AppColors
                                    .textSecondary,
                            fontSize: 12,
                          ),
                        ),

                        trailing:
                            IconButton(
                          icon:
                              const Icon(
                            Icons.close,
                            size: 19,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _removeRecentSearch(
                              email,
                            );
                          },
                        ),

                        onTap: () {
                          _selectRecentSearch(
                            email,
                          );
                        },
                      ),

                      if (index !=
                          _recentSearches.length -
                              1)
                        Divider(
                          height: 1,
                          indent: 76,
                          endIndent: 16,
                          color:
                              Colors.grey.shade200,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}