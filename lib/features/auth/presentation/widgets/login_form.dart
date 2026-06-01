import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'email_form_field.dart';
import 'password_form_field.dart';

/// Login form widget with standard Flutter Form validation.
class LoginForm extends StatefulWidget {
  final Future<void> Function(String email, String password)
  onEmailPasswordSubmitted;
  final Future<void> Function() onGooglePressed;
  final bool isLoading;

  const LoginForm({
    super.key,
    required this.onEmailPasswordSubmitted,
    required this.onGooglePressed,
    this.isLoading = false,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      await widget.onEmailPasswordSubmitted(
        _emailController.text,
        _passwordController.text,
      );
    } else {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    }
  }

  Future<void> _handleGoogleLogin() async {
    await widget.onGooglePressed();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field with built-in validation
          EmailFormField(
            controller: _emailController,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),

          // Password field with built-in validation
          PasswordFormField(
            controller: _passwordController,
            labelText: 'Пароль',
            textInputAction: TextInputAction.done,
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
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

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
                      'Увійти через email',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Divider(color: colorScheme.outlineVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'або',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: Divider(color: colorScheme.outlineVariant)),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: widget.isLoading ? null : _handleGoogleLogin,
            icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Увійти через Google',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: widget.isLoading
                  ? null
                  : () => GoRouter.of(context).go('/password-reset'),
              child: Text(
                'Забули пароль?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
