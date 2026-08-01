import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

@override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

@override
void dispose() {
  _emailController.dispose();
  _passwordController.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Form(
          key: _formKey,
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

                // Welcome
                const Center(
                  child: Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                const Center(
                  child: Text(
                    "Sign in to continue to your account",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Phone Number
                AppTextField(
                  controller: _emailController,
                  label: "Email",
                  hintText: "Enter your email",
                  keyboardType: TextInputType.emailAddress,
                  prefix: const Icon(Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your email";
                    }
                    if (!value.contains("@")) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password
                AppTextField(
                  controller: _passwordController,
                  label: "Password",
                  hintText: "Enter your password",
                  obscureText: _obscurePassword,
                  prefix: const Icon(Icons.lock_outline),
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword? Icons.visibility_off_outlined: Icons.visibility_outlined
                    ),
                    onPressed: (){
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty){
                      return "Please enter your password";
                    }
                    if (value.length < 8){
                      return "Password must be at least 8 characters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Login Button
                AppButton(
                  text: "Login",
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.go('/home');
                    }
                  },
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "or continue with",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Google Button
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {},

                    icon: Image.asset(
                      'assets/icons/google.png',
                      width: 20,
                      height: 20,
                    ),

                    label: const Text(
                      "Google",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.go('/register');
                      },
                      child: const Text(
                        "Sign up",
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
      ),  
    );  
  } 
} 