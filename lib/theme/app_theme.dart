import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------
class AppColors {
  AppColors._();

  static const background = Color(0xFF000000);
  static const surfaceGlass = Color(0x0FFFFFFF); // ~6% white
  static const primary = Color(0xFF2B5CE6); // cobalt blue
  static const primaryLight = Color(0xFF4F8EF7); // bright cobalt
  static const accent = Color(0xFF6BA3FF);
  static const borderGlass = Color(0x1FFFFFFF); // ~12% white
  static const textPrimary = Color(0xFFFFFFFF);
  static const textMuted = Color(0x73FFFFFF); // ~45% white
  static const textDisabled = Color(0x40FFFFFF); // ~25% white
  static const chimeFlash = Color(0xFF4F8EF7);
  static const success = Color(0xFF34C770);
  static const arcTrack = Color(0x26FFFFFF); // ~15% white

  // Premium colors from screenshot
  static const startButton = Color(0xFF7EB0D5); // warm sky-blue for start
  static const presetBg = Color(0xFF2C1E30); // dark plum/eggplant
  static const selectedItem = Color(0xFF8AB4F8); // light blue selected numbers
  static const unselectedItem = Color(0xFF6E6070); // muted unselected numbers
  static const labelMuted = Color(0xFF9E8F9A); // soft mauve label color
  static const navBarBg = Color(0x19FFFFFF); // glassmorphic bottom nav bar
}

// ---------------------------------------------------------------------------
// App-level ThemeData
// ---------------------------------------------------------------------------
ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.background,
    ),
    textTheme: _buildTextTheme(base.textTheme),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

TextTheme _buildTextTheme(TextTheme base) {
  // Use the default system font family (sans-serif) for clean modern readability
  return base.copyWith(
    // Massive countdown digits
    displayLarge: const TextStyle(
      fontSize: 90,
      fontWeight: FontWeight.w200, // ultra-thin elegance
      color: AppColors.textPrimary,
      letterSpacing: -2.0,
      height: 1.0,
    ),
    displayMedium: const TextStyle(
      fontSize: 70,
      fontWeight: FontWeight.w200,
      color: AppColors.textPrimary,
      letterSpacing: -1.5,
      height: 1.0,
    ),
    displaySmall: const TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w200,
      color: AppColors.textPrimary,
      letterSpacing: -1.0,
      height: 1.0,
    ),
    // Subtitle / rep counter
    headlineMedium: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w300,
      color: AppColors.labelMuted,
      letterSpacing: 0.5,
    ),
    headlineSmall: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w300,
      color: AppColors.labelMuted,
      letterSpacing: 0.4,
    ),
    // Stepper labels (e.g. Hours, Minutes, Seconds)
    titleMedium: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.labelMuted,
      letterSpacing: 2.0, // clean track uppercase label look
    ),
    // Stepper values
    titleLarge: const TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w300,
      color: AppColors.selectedItem,
    ),
    // Button text
    labelLarge: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
    ),
  );
}
