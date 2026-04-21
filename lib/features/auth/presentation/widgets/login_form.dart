import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import 'email_field.dart';
import 'password_field.dart';

/// Login form widget with validation and state management.
class LoginForm extends StatefulWidget {
  final VoidCallback onSubmitted;
  final bool isLoading;

  const LoginForm({
    super.key,
    required this.onSubmitted,
    this.isLoading = false,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email адреса обов\'язкова';
    }
    const emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    if (!RegExp(emailRegex).hasMatch(value)) {
      return 'Введіть дійсну email адресу';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пароль обов\'язковий';
    }
    if (value.length < 8) {
      return 'Пароль мусить містити мінімум 8 символів';
    }
    return null;
  }

  void _handleSubmit() {
    setState(() {
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
    });

    if (_emailError == null && _passwordError == null) {
      widget.onSubmitted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          EmailField(
            controller: _emailController,
            errorText: _emailError,
            onChanged: (_) {
              setState(() => _emailError = null);
            },
          ),
          const SizedBox(height: 20),

          // Password field
          PasswordField(
            controller: _passwordController,
            errorText: _passwordError,
            labelText: 'Пароль',
            onChanged: (_) {
              setState(() => _passwordError = null);
            },
          ),
          const SizedBox(height: 12),

          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.isLoading
                  ? null
                  : () {
                      // Navigate to forgot password
                    },
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                'Забули пароль?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Login button
          ElevatedButton(
            onPressed: widget.isLoading ? null : _handleSubmit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: widget.isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : Text(
                      'Увійти',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
