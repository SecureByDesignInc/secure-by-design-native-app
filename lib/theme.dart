import 'package:flutter/material.dart';

abstract final class SbdColors {
  static const background = Color(0xFF050B14);
  static const surface = Color(0xFF102237);
  static const surfaceLow = Color(0xFF0B1828);
  static const ink = Color(0xFFF3F7FF);
  static const muted = Color(0xffaebdd0);
  static const cyan = Color(0xFF83DCFA);
  static const blue = Color(0xFF378EFA);
  static const border = Color(0xFF23374B);
  static const success = Color(0xFF88E0B1);
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF284F70), Color(0xFF17344F), Color(0xFF102237)],
    stops: [0, 0.48, 1],
  );
  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF172D43), Color(0xFF102237), Color(0xFF0E1D30)],
  );
  static const canvasGradient = RadialGradient(
    center: Alignment(0.9, -1),
    radius: 1.35,
    colors: [Color(0xFF183752), Color(0xFF0C1C2E), background],
    stops: [0, 0.44, 1],
  );
  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB5EAFC), cyan, Color(0xFF76B8FA)],
  );
}

// Shared by cards and navigation so the whole app has the same soft depth.
BoxDecoration softSurface({bool featured = false, double radius = 28}) =>
    BoxDecoration(
      gradient: featured ? SbdColors.gradient : SbdColors.cardGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: SbdColors.cyan.withValues(alpha: featured ? 0.18 : 0.08),
      ),
      boxShadow: [
        BoxShadow(
          color: SbdColors.background.withValues(alpha: 0.28),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ],
    );

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
          fontWeight: FontWeight.w500,
          letterSpacing: -1.2,
          height: 1.12,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.8,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w500,
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
          minimumSize: const Size(48, 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const StadiumBorder(),
          backgroundBuilder: (context, states, child) => Ink(
            decoration: BoxDecoration(
              gradient: states.contains(WidgetState.disabled)
                  ? null
                  : SbdColors.buttonGradient,
              borderRadius: BorderRadius.circular(40),
            ),
            child: child,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SbdColors.ink,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: SbdColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: SbdColors.cyan.withValues(alpha: 0.13),
        height: 72,
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
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: SbdColors.cyan.withValues(alpha: 0.12)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF244764),
        contentTextStyle: TextStyle(color: SbdColors.ink, fontSize: 14),
      ),
    );
