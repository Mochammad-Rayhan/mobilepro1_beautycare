import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  
  bool _agreeToTerms = false;
  bool _isLoading = false;

  void _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      _showSnackBar('All fields are required');
      return;
    }

    if (_passwordController.text != _confirmController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }



    setState(() {
      _isLoading = true;
    });

    final user = User(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    final apiService = ApiService();
    int result = await apiService.registerUser(user);

    setState(() {
      _isLoading = false;
    });

    if (result != -1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful! Please Sign In.')),
        );
        Navigator.pop(context);
      }
    } else {
      _showSnackBar('Email already exists or error occurred');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Beautycare',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Join us and find your perfect beauty routine.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              
              CustomTextField(
                hintText: 'Full Name',
                prefixIcon: Icons.person_outline,
                controller: _nameController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Email address',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'Confirm Password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                controller: _confirmController,
              ),
              const SizedBox(height: 24),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreeToTerms,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'I agree to the ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : PrimaryButton(
                      text: 'Create Account',
                      onPressed: _agreeToTerms ? _register : null,
                    ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(fontWeight: FontWeight.w600),
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
