import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BluLink"),
        actions: [
          IconButton(
            onPressed: () {
              context.go('/profile');
            },
            icon: const Icon(Icons.person_outline),
            tooltip: "Profile",
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Welcome to BluLink!",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}