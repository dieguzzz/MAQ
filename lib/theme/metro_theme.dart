import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetroColors {
  MetroColors._();

  static const Color blue = Color(0xFF0072CE);
  static const Color green = Color(0xFF00A651);
  static const Color energyOrange = Color(0xFFFF6B35);

  static const Color white = Color(0xFFFFFFFF);
  static const Color grayLight = Color(0xFFF5F5F5);
  static const Color grayMedium = Color(0xFFE0E0E0);
  static const Color grayDark = Color(0xFF333333);

  static const Color stateNormal = Color(0xFF4CAF50);
  static const Color stateModerate = Color(0xFFFFC107);
  static const Color stateCritical = Color(0xFFF44336);
  static const Color stateInactive = Color(0xFF9E9E9E);
}

class MetroTheme {
  MetroTheme._();

  static ThemeData light() {
    const Color seed = MetroColors.blue;
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineLarge: GoogleFonts.montserrat(
        textStyle: base.textTheme.headlineLarge,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.montserrat(
        textStyle: base.textTheme.headlineMedium,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.montserrat(
        textStyle: base.textTheme.titleLarge,
        fontWeight: FontWeight.w600,
      ),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      primary: seed,
      secondary: MetroColors.green,
      surface: MetroColors.grayLight,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MetroColors.grayLight,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: MetroColors.grayLight,
        elevation: 0,
        foregroundColor: MetroColors.grayDark,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MetroColors.energyOrange,
          foregroundColor: MetroColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MetroColors.grayDark,
          textStyle: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: MetroColors.grayLight,
        selectedColor: MetroColors.energyOrange.withValues(alpha: 0.15),
        labelStyle: textTheme.labelLarge,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: MetroColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: MetroColors.white,
        selectedItemColor: MetroColors.blue,
        unselectedItemColor: MetroColors.grayDark.withValues(alpha: 0.6),
        selectedIconTheme: const IconThemeData(
          color: MetroColors.blue,
          size: 28,
        ),
        unselectedIconTheme: IconThemeData(
          color: MetroColors.grayDark.withValues(alpha: 0.6),
          size: 24,
        ),
        selectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
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
      headlineLarge: GoogleFonts.montserrat(
        textStyle: base.textTheme.headlineLarge,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: GoogleFonts.montserrat(
        textStyle: base.textTheme.headlineMedium,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.montserrat(
        textStyle: base.textTheme.titleLarge,
        fontWeight: FontWeight.w600,
      ),
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: MetroColors.blue,
      brightness: Brightness.dark,
      primary: MetroColors.blue,
      secondary: MetroColors.green,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0E121A),
      textTheme: textTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MetroColors.energyOrange,
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

