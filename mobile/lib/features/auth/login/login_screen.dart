import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_text_field.dart';

class LoginScreen extends StatelessWidget{
  const LoginScreen ({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
  padding: const EdgeInsets.all(24),
  child: Column(
    children: [
      const AppTextField(
        label: "Email",
      ),

      const SizedBox(height: 16),

      const AppTextField(
        label: "Password",
        obscureText: true,
      ),

      const SizedBox(height: 24),

      AppButton(
        text: "Go To Register",
        onPressed: () {
          context.go('/register');
        },
            ),
          ],
        ),
      ),
    );
  }
}