import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/theme/app_colors.dart';

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

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          context.push('/new-contact');
        },
        child: const Icon(
          Icons.add,
          size: 30,
        ),
      ),

      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,
    );
  }
}