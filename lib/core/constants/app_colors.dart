import 'package:flutter/material.dart';

/// App color palette matching Memento3D UI tokens
class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF6366F1); // Indigo / Violet brand accent
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Background & Surface colors
  static const Color background = Color(0xFFFBFBFE);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFF1F0F5);

  // Text colors
  static const Color textPrimary = Color(0xFF111827); // Deep slate
  static const Color textSecondary = Color(0xFF6B7280); // Muted grey
  static const Color textMuted = Color(0xFF9CA3AF);

  // Badge & Tag colors
  static const Color badgePurpleBg = Color(0xFFEDE9FE);
  static const Color badgePurpleText = Color(0xFF7C3AED);

  static const Color badgeOrangeBg = Color(0xFFFFDEC9);
  static const Color badgeOrangeText = Color(0xFFC2410C);

  static const Color badgeGreenBg = Color(0xFFD1FAE5);
  static const Color badgeGreenText = Color(0xFF065F46);

  static const Color dotGreen = Color(0xFF10B981);

  // Form & Border colors
  static const Color inputBorder = Color(0xFFE5E7EB);
  static const Color inputFocusBorder = Color(0xFF6366F1);
  static const Color error = Color(0xFFEF4444);

  // Warning / Amber colors (quality-check warnings, non-blocking alerts)
  static const Color warningAmberBg = Color(0xFFFFFBEB);
  static const Color warningAmberBorder = Color(0xFFFDE68A);
  static const Color warningAmberText = Color(0xFF92400E);
  static const Color warningAmberIcon = Color(0xFFD97706);
}
