import 'package:flutter/material.dart';

/// SmartChefAI Color System
/// Based on Material 3 with custom brand colors
class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color primaryOrangeDark = Color(0xFFE55A2B);
  static const Color secondaryGreen = Color(0xFF2ECC71);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color accentGreen = Color(0xFF2ECC71);

  // Light Theme Colors
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFFFF6B35),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFDBCF),
    onPrimaryContainer: Color(0xFF3A0B00),
    secondary: Color(0xFF2ECC71),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD4F5E0),
    onSecondaryContainer: Color(0xFF002111),
    tertiary: Color(0xFFFFD93D),
    onTertiary: Color(0xFF3D3000),
    tertiaryContainer: Color(0xFFFFF0C3),
    onTertiaryContainer: Color(0xFF251A00),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFFFFBFF),
    onSurface: Color(0xFF201A17),
    surfaceContainerHighest: Color(0xFFF5F0EC),
    onSurfaceVariant: Color(0xFF52443C),
    outline: Color(0xFF85746B),
    outlineVariant: Color(0xFFD8C2B8),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF362F2B),
    onInverseSurface: Color(0xFFFBEEE8),
    inversePrimary: Color(0xFFFFB59B),
    surfaceTint: Color(0xFFFF6B35),
  );

  // Dark Theme Colors
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB59B),
    onPrimary: Color(0xFF5E1700),
    primaryContainer: Color(0xFF862400),
    onPrimaryContainer: Color(0xFFFFDBCF),
    secondary: Color(0xFFB8F0C5),
    onSecondary: Color(0xFF00391F),
    secondaryContainer: Color(0xFF00522D),
    onSecondaryContainer: Color(0xFFD4F5E0),
    tertiary: Color(0xFFE9C54A),
    onTertiary: Color(0xFF3D3000),
    tertiaryContainer: Color(0xFF584700),
    onTertiaryContainer: Color(0xFFFFF0C3),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF181210),
    onSurface: Color(0xFFF1DFD6),
    surfaceContainerHighest: Color(0xFF3D3632),
    onSurfaceVariant: Color(0xFFD8C2B8),
    outline: Color(0xFFA08D83),
    outlineVariant: Color(0xFF52443C),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF1DFD6),
    onInverseSurface: Color(0xFF362F2B),
    inversePrimary: Color(0xFFAE3200),
    surfaceTint: Color(0xFFFFB59B),
  );

  // Semantic Colors
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFFFD93D);
  static const Color info = Color(0xFF3498DB);

  // Category Colors
  static const Color vegetarian = Color(0xFF27AE60);
  static const Color vegan = Color(0xFF16A085);
  static const Color glutenFree = Color(0xFF9B59B6);
  static const Color dairyFree = Color(0xFF3498DB);
  static const Color lowCarb = Color(0xFFE67E22);
  static const Color highProtein = Color(0xFFE74C3C);

  // Gradient Presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFF8F65)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF6B35), Color(0xFFFFD93D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient freshGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF3498DB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
