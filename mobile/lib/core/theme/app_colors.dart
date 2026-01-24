import 'package:flutter/material.dart';

class AppColors {
  // Coptic-inspired Gold
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFFAA8C2C);
  static const Color goldLight = Color(0xFFF3D576);

  // Deep Coptic Blue (Royal)
  static const Color bluePrimary = Color(0xFF003366);
  static const Color blueDark = Color(0xFF001F3F);
  static const Color blueLight = Color(0xFF335C85);

  // Vineyard Theme (Earthy/Premium)
  static const Color vineyardBrown = Color(0xFF1A120B); // Deepest brown/black
  static const Color vineyardBrownLight = Color(
    0xFF2C241B,
  ); // Lighter brown overlay
  static const Color vineyardSurface = Color(
    0xFF2A2118,
  ); // Surface element color

  // Deep Red (Martyrdom/Coptic Ribbon)
  static const Color redPrimary = Color(0xFFC0392B);
  static const Color redAccent = Color(0xFFA52A2A);
  static const Color redLight = Color(
    0xFFFF5252,
  ); // High contrast for dark mode

  // Neutrals - Light
  static const Color backgroundLight = Color(0xFFF8F9FA); // Off-white
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF757575);

  // Neutrals - Dark
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFA0A0A0);

  // Modal UI elements (theme-aware)
  static const Color dragHandleLight = Color(0xFFD1D5DB); // grey-300 equivalent
  static const Color dragHandleDark = Color(0xFF4B5563); // grey-600 equivalent

  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldPrimary, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
