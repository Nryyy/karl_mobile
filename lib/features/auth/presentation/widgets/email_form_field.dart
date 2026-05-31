import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material Form email field with built-in validation.
class EmailFormField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  const EmailFormField({
    super.key,
    required this.controller,
    this.validator,
    this.textInputAction,
  });

  static String? defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email адреса обов\'язкова';
    }
    const emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    if (!RegExp(emailRegex).hasMatch(value)) {
      return 'Введіть дійсну email адресу';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction ?? TextInputAction.next,
      validator: validator ?? defaultValidator,
      decoration: InputDecoration(
        labelText: 'Email адреса',
        hintText: 'your.email@example.com',
        prefixIcon: Icon(
          Icons.email_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        errorMaxLines: 2,
        helperText: 'Ми не надсилатимемо спам',
        helperStyle: GoogleFonts.inter(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      style: GoogleFonts.inter(
        fontSize: 16,
        color: colorScheme.onSurface,
      ),
    );
  }
}
