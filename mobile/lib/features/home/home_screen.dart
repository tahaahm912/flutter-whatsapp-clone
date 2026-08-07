import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/storage/secure_storage.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = SecureStorage();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () async {
              await storage.clearTokens();

              if (!context.mounted) return;

              context.go('/login');
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Welcome to BluLink!",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}