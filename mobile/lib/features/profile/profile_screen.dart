import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/core/storage/secure_storage.dart';

import '../../core/crypto/identity_key_service.dart';
import '../../core/crypto/pre_key_service.dart';
import '../../core/network/api_client.dart';
import '../keys/data/services/key_api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SecureStorage _storage = SecureStorage();

  // Temporary profile data.
  // We will replace these with GET /users/me data.
  String _name = "Your Name";
  String _about = "Hey there! I am using BluLink.";
  String _phone = "+92 300 1234567";
  String _email = "your@email.com";

  bool _isLoggingOut = false;

  // --------------------------------------------------------------------
  // TEMPORARY DEBUG STATE (Week 6 testing only)
  // --------------------------------------------------------------------
  //
  // Forces this account's device to (re-)upload its Signal Protocol
  // keys right now, instead of waiting for whatever normally triggers
  // it (Week 4, Day 5's post-registration auto-upload). Useful for
  // confirming GET /users/:userId/keys stops returning 404/
  // NO_KEYS_AVAILABLE for an account whose automatic upload never
  // fired. Remove this section once that root cause is fixed.
  // --------------------------------------------------------------------

  bool _isUploadingKeys = false;

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    await _storage.clearTokens();

    if (!mounted) return;

    context.go('/login');
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$title coming soon"),
      ),
    );
  }

  Future<void> _forceKeyUpload() async {
    setState(() {
      _isUploadingKeys = true;
    });

    try {
      final identityKeyService = IdentityKeyService(_storage);
      final preKeyService = PreKeyService(identityKeyService);
      final keyApiService = KeyApiService(ApiClient());

      final identityPublicKey = await preKeyService.getIdentityPublicKey();
      final registrationId =
          await identityKeyService.getOrCreateRegistrationId();

      final signedPreKey = await preKeyService.generateSignedPreKey();
      final oneTimePreKeys =
          await preKeyService.generateOneTimePreKeys(count: 20);

      await keyApiService.uploadPublicKeys(
        identityKey: identityPublicKey,
        registrationId: registrationId,
        signedPreKey: preKeyService.signedPreKeyToJson(signedPreKey),
        oneTimePreKeys: oneTimePreKeys
            .map((key) => preKeyService.preKeyToJson(key))
            .toList(),
      );

      debugPrint('FORCE KEY UPLOAD: succeeded');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keys uploaded successfully ✅'),
        ),
      );
    } catch (e) {
      debugPrint('FORCE KEY UPLOAD ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Key upload failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingKeys = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.primary,
          ),
        ),

        title: const Text(
          "Profile",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        centerTitle: true,

        actions: [
          TextButton(
            onPressed: () {
              _showComingSoon("Edit profile");
            },
            child: const Text(
              "Edit",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          child: Column(
            children: [
              // ------------------------------------------------------------
              // PROFILE HEADER
              // ------------------------------------------------------------

              const SizedBox(height: 8),

              CircleAvatar(
                radius: 66,
                backgroundColor: Colors.grey.shade300,

                // Later we can replace this with the user's profile image.
                child: Icon(
                  Icons.person,
                  size: 70,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                _name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                _about,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 28),

              // ------------------------------------------------------------
              // PERSONAL INFORMATION
              // ------------------------------------------------------------

              _buildSection(
                children: [
                  _buildProfileTile(
                    icon: Icons.person_outline,
                    iconColor: const Color(0xFF34C759),
                    title: "About",
                    value: _about,
                    onTap: () {
                      _showComingSoon("About");
                    },
                  ),

                  _buildDivider(),

                  _buildProfileTile(
                    icon: Icons.phone_outlined,
                    iconColor: const Color(0xFF3478F6),
                    title: "Phone Number",
                    value: _phone,
                    onTap: () {
                      _showComingSoon("Phone Number");
                    },
                  ),

                  _buildDivider(),

                  _buildProfileTile(
                    icon: Icons.email_outlined,
                    iconColor: const Color(0xFF3478F6),
                    title: "Email",
                    value: _email,
                    onTap: () {
                      _showComingSoon("Email");
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------------------
              // SETTINGS
              // ------------------------------------------------------------

              _buildSection(
                children: [
                  _buildProfileTile(
                    icon: Icons.notifications_outlined,
                    iconColor: const Color(0xFFFF3B30),
                    title: "Notifications",
                    value: "Messages and alerts",
                    onTap: () {
                      _showComingSoon("Notifications");
                    },
                  ),

                  _buildDivider(),

                  _buildProfileTile(
                    icon: Icons.lock_outline,
                    iconColor: const Color(0xFF34C759),
                    title: "Privacy",
                    value: "Security and privacy settings",
                    onTap: () {
                      _showComingSoon("Privacy");
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ------------------------------------------------------------
              // TEMPORARY: DEVELOPER / WEEK 6 TESTING
              // ------------------------------------------------------------
              //
              // Remove this section once every account's Signal keys
              // upload automatically and reliably on registration.
              // ------------------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Developer (Week 6 testing)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade900,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Forces this account's device to upload its Signal "
                      "Protocol keys right now.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed:
                            _isUploadingKeys ? null : _forceKeyUpload,
                        child: Text(
                          _isUploadingKeys
                              ? "Uploading..."
                              : "Force Key Upload",
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------------------
              // LOGOUT
              // ------------------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isLoggingOut ? null : _logout,
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                  label: Text(
                    _isLoggingOut ? "Logging out..." : "Logout",
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.red.shade200,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "BluLink",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                "Version 1.0.0",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // SECTION CONTAINER
  // =========================================================================

  Widget _buildSection({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // =========================================================================
  // PROFILE TILE
  // =========================================================================

  Widget _buildProfileTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.chevron_right,
              size: 22,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // DIVIDER
  // =========================================================================

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Divider(
        height: 1,
        thickness: 0.7,
        color: Colors.grey.shade200,
      ),
    );
  }
}