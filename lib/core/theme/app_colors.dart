import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFFFF2D78); // Soft Pink
  static const Color secondary = Color(0xFFFFE4E9); // Peach
  static const Color accent = Color(0xFFFFF9E1); // Soft Yellow

  // Neutral Colors
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF2D78),
      Color(0xFFFF71A3),
    ],
  );

  static const LinearGradient peachGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFE4E9),
      Color(0xFFFFF1F3),
    ],
  );
}
