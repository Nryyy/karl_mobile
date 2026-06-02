import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

/// Material Form password field with show/hide toggle and validation.
class PasswordFormField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String? labelText;
  final TextInputAction? textInputAction;
  final String? hintText;

  const PasswordFormField({
    super.key,
    required this.controller,
    this.validator,
    this.labelText,
    this.textInputAction,
    this.hintText,
  });

  static String? Function(String?) defaultValidatorWith(BuildContext context) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return AppLocalizations.of(context)?.passwordRequired ?? 'Password is required';
      }
      if (value.length < 8) {
        return AppLocalizations.of(context)?.passwordMinLength ?? 'Password must be at least 8 characters';
      }
      return null;
    };
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
      validator: widget.validator ?? PasswordFormField.defaultValidatorWith(context),
      decoration: InputDecoration(
        labelText: widget.labelText ?? AppLocalizations.of(context)?.passwordLabel ?? 'Password',
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
