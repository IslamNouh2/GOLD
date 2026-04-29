import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DahabiTheme {
  // Colors from the premium HTML snippet
  static const Color gold = Color(0xFFF5C842);
  static const Color goldDim = Color(0xFF8B6F20);
  static const Color goldBright = Color(0xFFFFE066);
  
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF151515);
  static const Color surfaceVariant = Color(0xFF1C1C1C);
  static const Color border = Color(0xFF2A2A2A);
  
  static const Color text = Color(0xFFF0EDE4);
  static const Color muted = Color(0xFF6B6861);
  
  static const Color green = Color(0xFF22C97A);
  static const Color red = Color(0xFFE24B4A);

  static const Color primary = gold;

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: Colors.black,
        secondary: goldDim,
        surface: surface,
        onSurface: text,
        background: background,
        onBackground: text,
        error: red,
      ),
      dividerColor: border,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.ibmPlexMono(
          fontSize: 42,
          fontWeight: FontWeight.w600,
          color: text,
          letterSpacing: -0.02,
        ),
        titleLarge: GoogleFonts.notoNaskhArabic(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: gold,
        ),
        bodyLarge: GoogleFonts.ibmPlexMono(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: text,
        ),
        bodyMedium: GoogleFonts.ibmPlexMono(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: text,
        ),
        labelSmall: GoogleFonts.ibmPlexMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: muted,
          letterSpacing: 0.12,
        ),
      ),
    );
  }

  // Custom TextStyles for specific Dahabi requirements
  static TextStyle get dataMono => GoogleFonts.ibmPlexMono(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: text,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get arabicTitle => GoogleFonts.notoNaskhArabic(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: gold,
      );

  static TextStyle get labelCaps => GoogleFonts.ibmPlexMono(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: muted,
        letterSpacing: 0.12,
      );
}

