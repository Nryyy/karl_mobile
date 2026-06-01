import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material Form full name field with validation.
class FullNameFormField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  const FullNameFormField({
    super.key,
    required this.controller,
    this.validator,
    this.textInputAction,
  });

  static String? defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ім\'я та прізвище обов\'язкові';
    }
    if (value.trim().length < 2) {
      return 'Введіть повне ім\'я';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      textInputAction: textInputAction ?? TextInputAction.next,
      validator: validator ?? defaultValidator,
      decoration: InputDecoration(
        labelText: 'Повне ім\'я',
        hintText: 'Іван Петренко',
        prefixIcon: Icon(
          Icons.person_outline,
          color: colorScheme.onSurfaceVariant,
        ),
        errorMaxLines: 2,
      ),
      style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface),
    );
  }
}
