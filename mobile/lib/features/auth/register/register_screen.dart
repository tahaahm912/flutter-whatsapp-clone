import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/app/theme/app_colors.dart';
import 'package:mobile/core/widgets/app_button.dart';
import 'package:mobile/core/widgets/app_text_field.dart';

import 'package:mobile/features/auth/data/models/register_request.dart';
import 'package:mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mobile/features/auth/data/services/auth_api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

@override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  late final AuthRepository _repository;

@override
void initState() {
  super.initState();

  final apiService = AuthApiService();
  _repository = AuthRepository(apiService);
}

@override
void dispose() {
  _emailController.dispose();
  _passwordController.dispose();
  _nameController.dispose();
  _confirmPasswordController.dispose();
  super.dispose();
}

Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = RegisterRequest(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final response = await _repository.register(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );

      context.go('/otp');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                    "Create Account",
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
                    "Sign up to get started",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Full Name
                AppTextField(
                  controller: _nameController,
                  label: "Full Name",
                  hintText: "Enter your name",
                  keyboardType: TextInputType.name,
                  prefix: const Icon(Icons.person_2_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your name";
                    }
                    if (value.trim().length < 3) {
                      return "Name must be at least 3 characters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                //Email
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

                const SizedBox(height: 20),

                //Confirm Password
                AppTextField(
                  controller: _confirmPasswordController,
                  label: "Confirm Password",
                  hintText: "Enter your password",
                  obscureText: _obscureConfirmPassword,
                  prefix: const Icon(Icons.lock_outline),
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword? Icons.visibility_off_outlined: Icons.visibility_outlined
                    ),
                    onPressed: (){
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty){
                      return "Please enter your password";
                    }
                    if (value != _passwordController.text){
                      return "Password do not match";
                    }
                    return null;
                  },
                ),

                // Sign Up
                const SizedBox(height: 30),

                AppButton(
                  text: "Sign Up",
                  isLoading: _isLoading,
                  onPressed: _register,
                ),

                const SizedBox(height: 28),

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    
                    Expanded(
                      child: Divider(
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.go('/login');
                      },
                      child: const Text(
                        "Sign In",
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