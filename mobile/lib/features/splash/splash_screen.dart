import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget{
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text("Splash")),
      body: Center(
        child: ElevatedButton(
          onPressed: (){
           context.go('/login');
          },
          child: const Text("Go To Login"),
        ),
      ),
    );
  }
}