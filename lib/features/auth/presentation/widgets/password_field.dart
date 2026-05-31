import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom password input field with show/hide toggle and validation.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;
  final String labelText;
  final Function(String)? onChanged;
  final TextInputAction? textInputAction;

  const PasswordField({
    super.key,
    required this.controller,
    this.errorText,
    this.labelText = 'Пароль',
    this.onChanged,
    this.textInputAction,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isObscured = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        obscureText: _isObscured,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: '••••••••',
          prefixIcon: Icon(
            Icons.lock_outline,
            color: _isFocused
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
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
          errorText: widget.errorText,
          errorMaxLines: 2,
        ),
        textInputAction: widget.textInputAction ?? TextInputAction.done,
        style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface),
      ),
    );
  }
}
