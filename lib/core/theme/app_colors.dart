import 'package:flutter/material.dart';

class AppColors {
  // Primary Blue Palette
  static const Color headerBlueDark = Color(0xFF1A5DC8);
  static const Color headerBlueLight = Color(0xFF4CA3F5);
  
  // Brand Colors
  static const Color primary = headerBlueDark;
  static const Color primaryLight = headerBlueLight;
  static const Color accent = Color(0xFF00C9A7); // Teal/Mint
  
  // Neutral / Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color cardBg = Color(0xFFF1F5F9);
  
  // Text Colors
  static const Color textDark = Color(0xFF0F172A);
  static const Color textGrey = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  
  // Status Colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color pending = Color(0xFF64748B);

  // Stepper / UI Helpers
  static const Color inactiveStep = Color(0xFFE2E8F0);
  static const Color stepDone = Color(0xFF00C9A7);
}
