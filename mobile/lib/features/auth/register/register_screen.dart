import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/widgets/app_button.dart';

class RegisterScreen extends StatelessWidget{
  const RegisterScreen ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Center(
        child: AppButton(
          text: "Go To Home",
          onPressed: (){
            context.go('/home');
          }
        )
      ),
    );
  }
}