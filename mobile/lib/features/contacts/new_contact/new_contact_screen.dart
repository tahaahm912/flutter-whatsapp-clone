import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/theme/app_colors.dart';

class NewContactScreen extends StatefulWidget {
  const NewContactScreen({super.key});

  @override
  State<NewContactScreen> createState() => _NewContactScreenState();
}

class _NewContactScreenState extends State<NewContactScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _recentSearches = [
    'usamaahmed@example.com',
    'jabirkhan@example.com',
  ];

  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchUser() {
    final email = _searchController.text.trim();

    if (email.isEmpty) {
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Backend search will be connected here later.
    //
    // Example:
    // final response = await contactRepository.searchUser(email);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() {
        _isSearching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Searching for $email...'),
        ),
      );
    });
  }

  void _selectRecentSearch(String email) {
    _searchController.text = email;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --------------------------------
              // Search box
              // --------------------------------

              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),

                child: TextField(
                  controller: _searchController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.search,

                  onSubmitted: (_) {
                    _searchUser();
                  },

                  decoration: InputDecoration(
                    hintText: 'Search by email',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),

                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),

                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
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

              const SizedBox(height: 28),

              // --------------------------------
              // Search button
              // --------------------------------

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSearching ? null : _searchUser,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),

                  child: _isSearching
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Search User',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // --------------------------------
              // Recent searches header
              // --------------------------------

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (_recentSearches.isNotEmpty)
                    TextButton(
                      onPressed: _clearRecentSearches,
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // --------------------------------
              // Recent searches
              // --------------------------------

              if (_recentSearches.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 20,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                  ),

                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 42,
                        color: Colors.grey.shade400,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'No recent searches',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Search for a user by their email address.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
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
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.grey.shade200,
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
                                  const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 5,
                              ),

                              leading: Container(
                                width: 44,
                                height: 44,

                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withOpacity(0.10),
                                  shape: BoxShape.circle,
                                ),

                                child: const Icon(
                                  Icons.email_outlined,
                                  color: AppColors.primary,
                                  size: 21,
                                ),
                              ),

                              title: Text(
                                email,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              subtitle: const Text(
                                'Search again',
                                style: TextStyle(
                                  color:
                                      AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),

                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 19,
                                  color: Colors.grey,
                                ),

                                onPressed: () {
                                  _removeRecentSearch(email);
                                },
                              ),

                              onTap: () {
                                _selectRecentSearch(email);
                              },
                            ),

                            if (index !=
                                _recentSearches.length - 1)
                              Divider(
                                height: 1,
                                indent: 76,
                                endIndent: 16,
                                color: Colors.grey.shade200,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // --------------------------------
              // Information
              // --------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 21,
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Text(
                        'Enter the email address connected to the BluLink account to find a user and start a conversation.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
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
}