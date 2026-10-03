import 'package:flutter/material.dart';

abstract final class SbdColors {
  static const background = Color(0xFF050B14);
  static const surface = Color(0xFF102237);
  static const surfaceLow = Color(0xFF0B1828);
  static const ink = Color(0xFFF3F7FF);
  static const muted = Color(0xffaebdd0);
  static const cyan = Color(0xFF83DCFA);
  static const blue = Color(0xFF378EFA);
  static const border = Color(0xFF2B3D53);
  static const success = Color(0xFF88E0B1);
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF163D61), Color(0xFF102237), Color(0xFF0B1828)],
  );
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Geist',
      scaffoldBackgroundColor: SbdColors.background,
      colorScheme: const ColorScheme.dark(
        primary: SbdColors.cyan,
        onPrimary: SbdColors.background,
        secondary: SbdColors.blue,
        surface: SbdColors.surface,
        onSurface: SbdColors.ink,
        outline: SbdColors.border,
        error: Color(0xFFFFB4AB),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          letterSpacing: -1.2,
          height: 1.12,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.8,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.6,
          height: 1.25,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: SbdColors.muted),
        bodyMedium:
            TextStyle(fontSize: 14, height: 1.5, color: SbdColors.muted),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(
          fontSize: 12,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: SbdColors.background,
        foregroundColor: SbdColors.ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: SbdColors.cyan,
          foregroundColor: SbdColors.background,
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SbdColors.ink,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: SbdColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SbdColors.background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: SbdColors.cyan.withValues(alpha: 0.13),
        height: 76,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? SbdColors.cyan
                : SbdColors.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? SbdColors.cyan
                : SbdColors.muted,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF244764),
        contentTextStyle: TextStyle(color: SbdColors.ink, fontSize: 14),
      ),
    );
