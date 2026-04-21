import 'package:flutter/material.dart';

/// Professional color palette for Karl document circulation platform.
/// Focuses on trust, professionalism, and accessibility.
abstract final class AppColors {
  // Primary colors - Professional navy blue for trust
  static const Color primary = Color(0xFF1E40AF); // Professional navy
  static const Color primaryLight = Color(0xFF3B82F6); // Lighter blue
  static const Color primaryDark = Color(0xFF1E3A8A); // Darker navy

  // Secondary colors - Slate for balanced design
  static const Color secondary = Color(0xFF64748B); // Slate
  static const Color secondaryLight = Color(0xFF94A3B8); // Light slate

  // Accent colors - Green for success/action
  static const Color accent = Color(0xFF059669); // Emerald green
  static const Color accentLight = Color(0xFF10B981); // Light emerald

  // Semantic colors
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF3B82F6);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC); // Very light blue-gray
  static const Color surfaceLight = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFCBD5E1);
  static const Color disabled = Color(0xFF9CA3AF);
  static const Color textPrimary = Color(0xFF1F2937); // Dark gray
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray
  static const Color textTertiary = Color(0xFF9CA3AF); // Light gray

  // Shadows
  static const shadow = Color(0x0F000000); // 6% black opacity
}
