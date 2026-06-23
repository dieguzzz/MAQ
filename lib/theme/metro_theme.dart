import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetroColors {
  MetroColors._();

  static const Color primary = Color(0xFF0C5BA2);
  static const Color red = Color(0xFFE53935);
  static const Color accent = Color(0xFFF8D133);
  static const Color green = Color(0xFF4CAF50);

  // Line-specific colors
  static const Color linea1 = primary;
  static const Color linea2 = green;

  // Legacy aliases
  static const Color blue = primary;

  static const Color white = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF4F4F4);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF242424);
  static const Color text2 = Color(0xFF484848);
  static const Color text3 = Color(0xFF888888);

  // Legacy aliases
  static const Color grayLight = bg;
  static const Color grayMedium = Color(0xFFE0E0E0);
  static const Color grayDark = text;

  static const Color stateNormal = green;
  static const Color stateModerate = Color(0xFFFFC107);
  static const Color stateCritical = red;
  static const Color stateInactive = Color(0xFF9E9E9E);
}

class MetroTheme {
  MetroTheme._();

  static ThemeData light() {
    const Color seed = MetroColors.primary;
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.inter(
        textStyle: base.textTheme.headlineLarge,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineMedium: GoogleFonts.inter(
        textStyle: base.textTheme.headlineMedium,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.inter(
        textStyle: base.textTheme.titleLarge,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.inter(
        textStyle: base.textTheme.titleMedium,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(
        textStyle: base.textTheme.bodyLarge,
        color: MetroColors.text2,
      ),
      bodyMedium: GoogleFonts.inter(
        textStyle: base.textTheme.bodyMedium,
        color: MetroColors.text2,
      ),
      labelSmall: GoogleFonts.inter(
        textStyle: base.textTheme.labelSmall,
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
        color: MetroColors.primary,
      ),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      primary: seed,
      secondary: MetroColors.green,
      tertiary: MetroColors.red,
      surface: MetroColors.bg,
      onSurface: MetroColors.text,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MetroColors.bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: MetroColors.bg,
        elevation: 0,
        foregroundColor: MetroColors.text,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MetroColors.primary,
          foregroundColor: MetroColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MetroColors.text,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: MetroColors.bg,
        selectedColor: MetroColors.primary.withValues(alpha: 0.15),
        labelStyle: textTheme.labelLarge,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: MetroColors.card,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: MetroColors.white,
        selectedItemColor: MetroColors.primary,
        unselectedItemColor: MetroColors.text3,
        selectedIconTheme: const IconThemeData(
          color: MetroColors.primary,
          size: 28,
        ),
        unselectedIconTheme: const IconThemeData(
          color: MetroColors.text3,
          size: 24,
        ),
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.inter(
        textStyle: base.textTheme.headlineLarge,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineMedium: GoogleFonts.inter(
        textStyle: base.textTheme.headlineMedium,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: GoogleFonts.inter(
        textStyle: base.textTheme.titleLarge,
        fontWeight: FontWeight.w700,
      ),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: MetroColors.primary,
      brightness: Brightness.dark,
      primary: MetroColors.primary,
      secondary: MetroColors.green,
      tertiary: MetroColors.red,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0E121A),
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MetroColors.primary,
          foregroundColor: MetroColors.white,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MetroColors.white,
        ),
      ),
    );
  }
}
