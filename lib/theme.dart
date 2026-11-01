import 'package:flutter/material.dart';

/// The website's design, as the app wears it (owner direction, 1 November 2026:
/// the app's design and functionality match the website). Every value here is
/// read from the site's stylesheets: the hub pages (app/videos/training-hub.css,
/// videos.css), the shared shell (app/template-shared.css) and the homepage
/// (app/template-home.css). Keep them in step with the site, not the other way
/// round.
abstract final class SbdColors {
  /// The hub pages' ground (.vc-page).
  static const background = Color(0xFF071521);

  /// The header, footer and homepage stage (.site-header, .sbd-hero-stage).
  static const stage = Color(0xFF050B14);

  /// Panels and tiles (.th-sidebar, .th-tools-card, .th-empty).
  static const surface = Color(0xFF0B1D2C);

  /// The RMF steps panel and the deeper ground of the Tools card gradient.
  static const surfaceLow = Color(0xFF0A1826);

  /// A hovered or selected library link (.th-side-link).
  static const surfaceHover = Color(0xFF12293A);
  static const surfaceSelected = Color(0xFF16364B);

  static const ink = Color(0xFFEEF7FC);
  static const inkBright = Color(0xFFF1F8FF);
  static const muted = Color(0xFFA9BFCE);
  static const dim = Color(0xFF8FA9BA);
  static const linkText = Color(0xFFC3D4DF);

  static const cyan = Color(0xFF8AE5EF);
  static const blue = Color(0xFF378EFA);
  static const amber = Color(0xFFF7BD68);
  static const amberInk = Color(0xFF2B1A02);
  static const success = Color(0xFF8FE0B0);

  /// Hairlines: panels (.th-sidebar), tiles (.th-thumb), inputs (.th-search),
  /// the feature card (.th-feature) and the header's rule.
  static const border = Color(0xFF1D3A4F);
  static const borderTile = Color(0xFF23445A);
  static const borderInput = Color(0xFF2A4A60);
  static const borderFeature = Color(0xFF1F4157);
  static const borderHeader = Color(0xFF29405A);

  /// The site's primary button (.th-primary) and secondary button (.th-secondary).
  static const primary = Color(0xFF91DFEB);
  static const primaryBorder = Color(0xFFA4EAF3);
  static const primaryInk = Color(0xFF06283C);
  static const secondary = Color(0xFF102C40);
  static const secondaryBorder = Color(0xFF34546A);

  /// The site's navigation (.site-header nav) and its current item.
  static const navSurface = Color(0xFF0C1828);
  static const navBorder = Color(0xFF2A405B);
  static const navInk = Color(0xFFB4C7DF);
  static const navCurrentBorder = Color(0xFF4386B9);
  static const navCurrent = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF174675), Color(0xFF102A47)],
  );

  /// The logo pill (.logo-pill): Follow along, Book a call, Discord and so on.
  static const pillBorder = Color(0xFF355B7C);
  static const pillInk = Color(0xFFE5F3FF);
  static const pill = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF12314E), Color(0xFF0C1D31)],
  );

  /// The tile thumbnail's ground (.th-thumb) and the featured card's ground.
  static const thumb = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2B40), Color(0xFF081A29)],
  );
  static const feature = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B1A2B), Color(0xFF0B2F49)],
  );

  /// Kept for the lesson video's play button and poster fallback.
  static const gradient = feature;
  static const buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8F0F6), primary],
  );

  /// The topic families' accent colors (training-hub.css `.th-art-<family>`).
  static Color family(String family) => switch (family) {
        'harden' => amber,
        'logging' => const Color(0xFF9DB8FF),
        'endpoint' => success,
        'ops' => const Color(0xFFF29B7C),
        'authorize' => const Color(0xFFC9B6FF),
        'reference' => const Color(0xFFD7E3EA),
        _ => cyan,
      };
}

/// The site's monospace: kickers, chips, counts and the ghosted course number.
const sbdMono = 'GeistMono';

/// A panel the way the site draws one: a flat surface on a hairline with the
/// hub's 18px corners, and no shadow. [featured] is the Tools card's gradient.
BoxDecoration softSurface({bool featured = false, double radius = 18}) =>
    BoxDecoration(
      color: featured ? null : SbdColors.surface,
      gradient: featured ? SbdColors.feature : null,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
          color: featured ? SbdColors.borderFeature : SbdColors.border),
    );

ThemeData buildTheme() {
  const radius10 = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)));
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Geist',
    scaffoldBackgroundColor: SbdColors.background,
    canvasColor: SbdColors.background,
    dividerColor: SbdColors.border,
    colorScheme: const ColorScheme.dark(
      primary: SbdColors.cyan,
      onPrimary: SbdColors.primaryInk,
      secondary: SbdColors.blue,
      surface: SbdColors.background,
      onSurface: SbdColors.ink,
      onSurfaceVariant: SbdColors.muted,
      surfaceContainerHighest: SbdColors.surface,
      outline: SbdColors.border,
      outlineVariant: SbdColors.border,
      error: Color(0xFFFFB4AB),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        letterSpacing: -1.2,
        height: 1.15,
        color: SbdColors.inkBright,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -1,
        height: 1.15,
        color: SbdColors.inkBright,
      ),
      headlineSmall: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        height: 1.2,
        color: SbdColors.inkBright,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.25,
        color: SbdColors.inkBright,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        height: 1.3,
        color: SbdColors.inkBright,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: SbdColors.inkBright,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: SbdColors.muted),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: SbdColors.muted),
      bodySmall: TextStyle(fontSize: 12.5, height: 1.4, color: SbdColors.muted),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(
        fontFamily: sbdMono,
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
        color: SbdColors.dim,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: SbdColors.stage,
      foregroundColor: SbdColors.inkBright,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: SbdColors.borderHeader)),
      titleTextStyle: TextStyle(
          fontFamily: 'Geist',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: SbdColors.inkBright),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SbdColors.primary,
        foregroundColor: SbdColors.primaryInk,
        disabledBackgroundColor: SbdColors.secondary,
        disabledForegroundColor: SbdColors.dim,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        side: const BorderSide(color: SbdColors.primaryBorder),
        shape: radius10,
        textStyle: const TextStyle(
            fontFamily: 'Geist', fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: SbdColors.secondary,
        foregroundColor: SbdColors.ink,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        side: const BorderSide(color: SbdColors.secondaryBorder),
        shape: radius10,
        textStyle: const TextStyle(
            fontFamily: 'Geist', fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SbdColors.cyan,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: radius10,
        textStyle: const TextStyle(
            fontFamily: 'Geist', fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: SbdColors.muted),
    ),
    chipTheme: ChipThemeData(
      shape: radius10,
      side: const BorderSide(color: SbdColors.border),
      backgroundColor: SbdColors.surface,
      selectedColor: SbdColors.surfaceSelected,
      labelStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: SbdColors.linkText),
      secondaryLabelStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SbdColors.surface,
      hintStyle: const TextStyle(color: SbdColors.dim, fontSize: 14),
      labelStyle: const TextStyle(color: SbdColors.dim, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: SbdColors.cyan),
      prefixIconColor: SbdColors.dim,
      suffixIconColor: SbdColors.muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SbdColors.borderInput)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SbdColors.borderInput)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SbdColors.cyan)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: SbdColors.cyan,
      textColor: SbdColors.ink,
      titleTextStyle: TextStyle(
          fontFamily: 'Geist',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: SbdColors.inkBright),
      subtitleTextStyle: TextStyle(
          fontFamily: 'Geist', fontSize: 13, height: 1.4, color: SbdColors.muted),
    ),
    dividerTheme: const DividerThemeData(color: SbdColors.border, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SbdColors.cyan, linearTrackColor: SbdColors.border),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? SbdColors.primaryInk
              : SbdColors.muted),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? SbdColors.cyan
              : SbdColors.surfaceSelected),
      trackOutlineColor: WidgetStateProperty.all(SbdColors.borderInput),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: SbdColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: SbdColors.borderFeature)),
      titleTextStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: SbdColors.inkBright),
      contentTextStyle: const TextStyle(
          fontFamily: 'Geist', fontSize: 15, height: 1.5, color: SbdColors.muted),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: SbdColors.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: SbdColors.borderInput,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: SbdColors.surfaceSelected,
      contentTextStyle: TextStyle(color: SbdColors.ink, fontSize: 14),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: SbdColors.borderInput)),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: SbdColors.cyan,
      collapsedIconColor: SbdColors.muted,
      textColor: SbdColors.inkBright,
      collapsedTextColor: SbdColors.inkBright,
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
          color: SbdColors.surfaceSelected,
          borderRadius: BorderRadius.all(Radius.circular(8))),
      textStyle: TextStyle(fontFamily: 'Geist', color: SbdColors.ink),
    ),
  );
}
