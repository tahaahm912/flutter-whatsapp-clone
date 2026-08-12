import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:pinput/pinput.dart';
import '../data/services/auth_api_service.dart';
import '../data/models/verify_otp_request.dart';
import '../data/models/login_request.dart';
import '../data/repositories/auth_repository.dart';

import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/crypto/identity_key_service.dart';
import 'package:mobile/core/crypto/pre_key_service.dart';
import 'package:mobile/features/keys/data/repositories/key_repository.dart';
import 'package:mobile/features/keys/data/services/key_api_service.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String password;

  const OtpScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
  
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();
  late final AuthRepository _authRepository;
  final SecureStorage _storage = SecureStorage();

  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository(_authApiService);
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  /// Generates this device's Signal Protocol public keys (or reuses
  /// the ones already on-device) and uploads them to the backend.
  ///
  /// Week 4, Day 5 goal: new accounts automatically upload their
  /// public keys with no manual step. Private keys never leave the
  /// device — only public material is sent to `POST /users/keys`.
  ///
  /// Failures here are logged, not surfaced as a blocking error: a
  /// flaky network right after signup shouldn't strand the user
  /// outside the app. Key upload can be retried later (e.g. next
  /// time keys are needed for a session).
  Future<void> _uploadPublicKeysSilently() async {
    try {
      final apiClient = ApiClient();
      final identityKeyService = IdentityKeyService(_storage);
      final preKeyService = PreKeyService(identityKeyService);
      final keyApiService = KeyApiService(apiClient);

      final keyRepository = KeyRepository(
        identityKeyService: identityKeyService,
        preKeyService: preKeyService,
        keyApiService: keyApiService,
      );

      await keyRepository.uploadPublicKeys();

      debugPrint('Public keys uploaded automatically after registration.');
    } catch (e) {
      debugPrint('Automatic public key upload failed (will retry later): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(
        color: AppColors.primary,
        width: 2,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 90,
                  height: 90,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              const Center(
                child: Text(
                  "Verify Your Email",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "We've sent a verification code to",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                widget.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              // OTP Input
              Pinput(
                controller: _otpController,
                length: 6,
                autofocus: true,
                keyboardType: TextInputType.number,
                mainAxisAlignment: MainAxisAlignment.center,
                separatorBuilder: (_) => const SizedBox(width: 8),

                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: defaultPinTheme,

                onCompleted: (value) {
                  debugPrint("OTP: $value");
                },
              ),

              const SizedBox(height: 24),

              // Verify Button
              AppButton(
                text: "Verify OTP",
                isLoading: _isVerifying,
                onPressed: () async {
                  if (_otpController.text.length != 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please enter the 6-digit verification code",
                        ),
                      ),
                    );
                    return;
                  }

                  if (_isVerifying) return;

                  setState(() {
                    _isVerifying = true;
                  });

                  try{
                    await _authApiService.verifyOtp(
                      VerifyOtpRequest(
                        identifier: widget.email,
                         code: _otpController.text,
                         ),
                    );

                    // Registration is now fully verified. Log the
                    // account in right away so the device has a JWT,
                    // then silently generate/upload this device's
                    // Signal Protocol public keys (Week 4, Day 5) —
                    // no manual step required from the user.
                    final loginResponse = await _authRepository.login(
                      LoginRequest(
                        identifier: widget.email,
                        password: widget.password,
                      ),
                    );

                    await _storage.saveAccessToken(loginResponse.accessToken);
                    await _storage.saveRefreshToken(loginResponse.refreshToken);

                    await _uploadPublicKeysSilently();

                    if (!mounted) return;

                    context.go('/home');
                  } on DioException catch(e) {
                    if (!mounted) return;

                    String message = "OTP verification failed";

                    if(e.response?. data != null &&
                       e.response!.data is Map &&
                       e.response!.data["message"] != null){
                        message = e.response!.data["message"];
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isVerifying = false;
                      });
                    }
                  }
                },
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Didn't receive the code? ",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Week 3: Call Resend OTP API
                    },
                    child: const Text(
                      "Resend Code",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}