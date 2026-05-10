import 'package:flutter/material.dart';

import 'app_palette.dart';

class AccessPlateTheme {
  const AccessPlateTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: NihPalette.primary,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFFF6F6F6) : NihPalette.base,
          onPrimary: isDark ? NihPalette.base : NihPalette.white,
          primaryContainer: isDark
              ? const Color(0xFF252525)
              : const Color(0xFF181818),
          onPrimaryContainer: NihPalette.white,
          secondary: isDark ? const Color(0xFFB5DC87) : NihPalette.secondary,
          onSecondary: isDark ? NihPalette.base : NihPalette.base,
          secondaryContainer: isDark
              ? const Color(0xFF21301A)
              : NihPalette.secondaryLightest,
          onSecondaryContainer: isDark
              ? NihPalette.white
              : NihPalette.secondaryDarkest,
          surface: isDark ? const Color(0xFF171717) : NihPalette.white,
          onSurface: isDark ? const Color(0xFFF7F7F7) : NihPalette.base,
          surfaceContainerHighest: isDark
              ? const Color(0xFF222222)
              : const Color(0xFFF3F0EA),
          onSurfaceVariant: isDark
              ? const Color(0xFFC9C9CE)
              : NihPalette.grayDark,
          outline: isDark ? const Color(0xFF363636) : const Color(0xFFE6E2DB),
          outlineVariant: isDark
              ? const Color(0xFF2B2B2B)
              : const Color(0xFFEEEAE4),
          error: const Color(0xFFC95C4B),
          onError: NihPalette.white,
          shadow: Colors.black,
          scrim: Colors.black,
          surfaceTint: Colors.transparent,
        );

    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
    );
    final textTheme = _buildTextTheme(baseTheme.textTheme, colorScheme, isDark);

    return baseTheme.copyWith(
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF101010)
          : NihPalette.mist,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF1D1D1D) : NihPalette.white,
        selectedColor: colorScheme.primary,
        disabledColor: colorScheme.surfaceContainerHighest,
        side: BorderSide(
          color: isDark ? const Color(0xFF2B2B2B) : const Color(0xFFEAE5DD),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          backgroundColor: isDark ? const Color(0xFF1B1B1B) : NihPalette.white,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF171717) : NihPalette.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 3,
        activeTrackColor: colorScheme.primary,
        thumbColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.outlineVariant,
        overlayColor: colorScheme.primary.withValues(alpha: 0.08),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1B1B1B) : NihPalette.white,
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF232323) : NihPalette.base,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: NihPalette.white,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.outlineVariant,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
      ),
    );
  }

  static TextTheme _buildTextTheme(
    TextTheme base,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 34,
        height: 1.08,
        letterSpacing: -0.8,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 30,
        height: 1.12,
        letterSpacing: -0.75,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 26,
        height: 1.16,
        letterSpacing: -0.55,
        fontWeight: FontWeight.w800,
        color: colorScheme.onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 20,
        height: 1.2,
        letterSpacing: -0.28,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.3,
        letterSpacing: -0.18,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.42,
        letterSpacing: -0.12,
        color: colorScheme.onSurface.withValues(alpha: isDark ? 0.95 : 0.94),
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.4,
        letterSpacing: -0.08,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 15,
        height: 1.2,
        letterSpacing: -0.04,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        height: 1.2,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
