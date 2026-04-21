import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Custom email input field with validation and professional styling.
class EmailField extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;
  final Function(String)? onChanged;

  const EmailField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  @override
  State<EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends State<EmailField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            onChanged: widget.onChanged,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email адреса',
              hintText: 'your.email@example.com',
              prefixIcon: Icon(
                Icons.email_outlined,
                color: _isFocused ? AppColors.primary : AppColors.textTertiary,
              ),
              errorText: widget.errorText,
              errorMaxLines: 2,
            ),
            textInputAction: TextInputAction.next,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          if (widget.errorText == null) ...[
            const SizedBox(height: 8),
            Text(
              'Ми не надсилатимемо спам',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
