import 'package:flutter/material.dart';

/// App color constants following the dark fitness theme
class AppColors {
  AppColors._();

  // Primary Colors - Gold/Green for "Standard en or"
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color primaryGreen = Color(0xFF00FF88);
  static const Color primaryGreenDark = Color(0xFF00CC6F);

  // Background Colors - Dark Theme
  static const Color backgroundDark = Color(0xFF0A0E1A);
  static const Color backgroundCard = Color(0xFF151B2D);
  static const Color backgroundCardLight = Color(0xFF1E2536);
  static const Color cardBackground = Color(0xFF151B2D); // Alias for backgroundCard
  static const Color borderColor = Color(0xFF2D3748); // Border color for cards

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B8C8);
  static const Color textHint = Color(0xFF6B7280);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color errorRed = Color(0xFFEF4444); // Alias for error
  static const Color info = Color(0xFF3B82F6);

  // Workout Specific
  static const Color exerciseCardBg = Color(0xFF1A2332);
  static const Color setCompleted = Color(0xFF059669);
  static const Color setIncomplete = Color(0xFF374151);
  static const Color restTimer = Color(0xFFF59E0B);

  // Muscle Groups
  static const Color muscleChest = Color(0xFFEC4899);
  static const Color muscleAbs = Color(0xFF8B5CF6);
  static const Color muscleBack = Color(0xFF3B82F6);
  static const Color muscleShoulders = Color(0xFFEAB308);
  static const Color muscleArms = Color(0xFF10B981);
  static const Color muscleLegs = Color(0xFFEF4444);

  // Chart Colors
  static const Color chartPrimary = primaryGreen;
  static const Color chartSecondary = primaryGold;
  static const Color chartGrid = Color(0xFF2D3748);
  static const Color chartBackground = Color(0xFF1A202C);

  // Additional UI Colors
  static const Color cardDark = Color(0xFF151B2D); // Same as backgroundCard
  static const Color accent = primaryGreen;
  static const Color primary = primaryGreen;
  static const Color secondary = primaryGold;

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, primaryGreenDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
