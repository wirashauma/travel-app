import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF8B7CF6);
  static const Color primaryDark = Color(0xFF5A4BD1);

  // Secondary / Accent
  static const Color secondary = Color(0xFF00D2FF);
  static const Color accent = Color(0xFF7C3AED);
  static const Color accentGlow = Color(0x337C3AED);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF00D2FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1E2E), Color(0xFF2A2A3E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF00D2FF), Color(0xFF6C5CE7)],
    stops: [0.0, 0.5, 1.0],
  );

  // Background
  static const Color background = Color(0xFF0F0F1A);
  static const Color backgroundSecondary = Color(0xFF161625);
  static const Color surface = Color(0xFF1A1A2E);

  // Cards
  static const Color cardDark = Color(0xFF1A1A2E);
  static const Color cardDarkElevated = Color(0xFF222236);

  // Borders
  static const Color border = Color(0xFF2A2A3E);
  static const Color borderLight = Color(0xFF3A3A4E);

  // Text
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textTertiary = Color(0xFF6B6B80);

  // Status
  static const Color success = Color(0xFF00C48C);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF00D2FF);

  // Seat Colors
  static const Color seatAvailable = Color(0xFF2A2A3E);
  static const Color seatSelected = Color(0xFF6C5CE7);
  static const Color seatOccupied = Color(0xFF3A3A4E);
  static const Color seatDriver = Color(0xFF1A1A2E);
}
