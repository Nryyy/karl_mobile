import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:karl_mobile/generated/app_localizations.dart';

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

  static String? Function(String?) defaultValidatorWith(BuildContext context) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return AppLocalizations.of(context)?.emailRequired ?? 'Email address is required';
      }
      const emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
      if (!RegExp(emailRegex).hasMatch(value)) {
        return AppLocalizations.of(context)?.emailInvalid ?? 'Enter a valid email address';
      }
      return null;
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: textInputAction ?? TextInputAction.next,
      validator: validator ?? defaultValidatorWith(context),
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)?.emailLabel ?? 'Email address',
        hintText: 'your.email@example.com',
        prefixIcon: Icon(
          Icons.email_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
        errorMaxLines: 2,
        helperText: AppLocalizations.of(context)?.emailHelperText ?? 'We won\'t send spam',
        helperStyle: GoogleFonts.inter(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      style: GoogleFonts.inter(fontSize: 16, color: colorScheme.onSurface),
    );
  }
}
