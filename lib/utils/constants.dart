import 'package:flutter/material.dart';

class AppColors {
  // Primary: Marron Chocolat - stability, classic libraries
  static const Color primary = Color(0xFF7B542F);

  // Secondary: Or Antique - quality, premium feel
  static const Color secondary = Color(0xFFB6771D);

  // Accent: Orange Vibrant - energy, call-to-actions
  static const Color accent = Color(0xFFFF9D00);

  // Background: Beige Doré - warm, book pages feel
  static const Color background = Color(0xFFFFCF71);

  // Additional useful colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

// ---------------- STRINGS ----------------

class AppStrings {
  static const String appName = 'Bookly';
  static const String tagline = 'Where every page turns into an adventure';
}

// ---------------- DURATIONS ----------------

class AppDurations {
  static const Duration splashAnimation = Duration(milliseconds: 1500);
  static const Duration splashWait = Duration(seconds: 3);
}