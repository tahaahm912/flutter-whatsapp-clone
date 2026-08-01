import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();

  // Temporary email
  // Later this will come from Register Screen
  final String email = "abc123@gmail.com";

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
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
                email,
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
                onPressed: () {
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

                  // Week 3: Call Verify OTP API
                  context.go('/home');
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