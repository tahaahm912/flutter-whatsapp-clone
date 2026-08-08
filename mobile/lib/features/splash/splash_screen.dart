import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SecureStorage storage = SecureStorage();

  bool _checkingLogin = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final token = await storage.getAccessToken();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // User is already logged in.
      context.go('/home');
      return;
    }

    // User is NOT logged in.
    // Stay on the splash screen.
    setState(() {
      _checkingLogin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingLogin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 80, 24, 80),
          child: Column(
            children: [
              const AppLogo(),

              const SizedBox(height: 20),

              const Text(
                "BluLink",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Fast • Secure • Connected",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),

              const Spacer(),

              AppButton(
                text: "Get Started",
                onPressed: () {
                  context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}