import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material Form password field with show/hide toggle and validation.
class PasswordFormField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String labelText;
  final TextInputAction? textInputAction;
  final String? hintText;

  const PasswordFormField({
    super.key,
    required this.controller,
    this.validator,
    this.labelText = 'Пароль',
    this.textInputAction,
    this.hintText,
  });

  static String? defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Пароль обов\'язковий';
    }
    if (value.length < 8) {
      return 'Пароль мусить містити мінімум 8 символів';
    }
    return null;
  }

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: widget.controller,
      obscureText: _isObscured,
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      validator: widget.validator ?? PasswordFormField.defaultValidator,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText ?? '••••••••',
        prefixIcon: Icon(
          Icons.lock_outline,
          color: colorScheme.onSurfaceVariant,
        ),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _isObscured = !_isObscured),
          child: Icon(
            _isObscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        errorMaxLines: 2,
      ),
      style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface),
    );
  }
}
