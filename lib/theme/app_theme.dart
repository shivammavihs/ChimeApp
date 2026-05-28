import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------
class AppColors {
  AppColors._();

  static bool isDark = true;

  static Color get background => isDark ? const Color(0xFF010208) : const Color(0xFFF4F6FC);
  static Color get surfaceGlass => isDark ? const Color(0x0FFFFFFF) : const Color(0x0D000000); // ~6% white in dark, ~5% black in light
  static Color get primary => isDark ? const Color(0xFF2B5CE6) : const Color(0xFF1B4DC6); // cobalt blue
  static Color get primaryLight => isDark ? const Color(0xFF4F8EF7) : const Color(0xFF336FD3); // bright cobalt
  static Color get accent => isDark ? const Color(0xFF6BA3FF) : const Color(0xFF2B5CE6);
  static Color get borderGlass => isDark ? const Color(0x1FFFFFFF) : const Color(0x16000000); // ~12% white in dark, ~9% black in light
  static Color get textPrimary => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF030611);
  static Color get textMuted => isDark ? const Color(0x73FFFFFF) : const Color(0x7F000000); // ~45% white in dark, ~50% black in light
  static Color get textDisabled => isDark ? const Color(0x40FFFFFF) : const Color(0x40000000); // ~25% white in dark, ~25% black in light
  static Color get chimeFlash => isDark ? const Color(0xFF4F8EF7) : const Color(0xFF2B5CE6);
  static Color get success => isDark ? const Color(0xFF34C770) : const Color(0xFF24A351);
  static Color get arcTrack => isDark ? const Color(0x26FFFFFF) : const Color(0x19000000); // ~15% white in dark, ~10% black in light

  // Premium colors from screenshot
  static Color get startButton => isDark ? const Color(0xFF7EB0D5) : const Color(0xFF3B6E8C); // warm sky-blue for start
  static Color get presetBg => isDark ? const Color(0xFF2C1E30) : const Color(0xFFF2EAF3); // dark plum/eggplant -> pastel plum
  static Color get selectedItem => isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1B4DC6); // light blue selected numbers
  static Color get unselectedItem => isDark ? const Color(0xFF5A5065) : const Color(0xFFA592A7); // muted unselected numbers
  static Color get labelMuted => isDark ? const Color(0xFF8A7D8A) : const Color(0xFF7E6B7B); // soft mauve label color
  static Color get navBarBg => isDark ? const Color(0x19FFFFFF) : const Color(0x12000000); // glassmorphic bottom nav bar
}

// ---------------------------------------------------------------------------
// App-level ThemeData
// ---------------------------------------------------------------------------
ThemeData buildAppTheme() {
  final isDark = AppColors.isDark;
  final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: AppColors.primary,
      onPrimary: isDark ? Colors.white : Colors.black,
      secondary: AppColors.primaryLight,
      onSecondary: isDark ? Colors.white : Colors.black,
      error: Colors.red,
      onError: Colors.white,
      surface: AppColors.background,
      onSurface: AppColors.textPrimary,
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
    displayLarge: TextStyle(
      fontSize: 90,
      fontWeight: FontWeight.w200, // ultra-thin elegance
      color: AppColors.textPrimary,
      letterSpacing: -2.0,
      height: 1.0,
    ),
    displayMedium: TextStyle(
      fontSize: 70,
      fontWeight: FontWeight.w200,
      color: AppColors.textPrimary,
      letterSpacing: -1.5,
      height: 1.0,
    ),
    displaySmall: TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w200,
      color: AppColors.textPrimary,
      letterSpacing: -1.0,
      height: 1.0,
    ),
    // Subtitle / rep counter
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w300,
      color: AppColors.labelMuted,
      letterSpacing: 0.5,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w300,
      color: AppColors.labelMuted,
      letterSpacing: 0.4,
    ),
    // Stepper labels (e.g. Hours, Minutes, Seconds)
    titleMedium: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: AppColors.labelMuted,
      letterSpacing: 2.0, // clean track uppercase label look
    ),
    // Stepper values
    titleLarge: TextStyle(
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
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textMuted,
    ),
  );
}
