import 'package:flutter/material.dart';

class AppTheme {
  // OFFGRID color palette — dark tactical
  static const Color primary = Color(0xFF00FF88);      // neon green
  static const Color background = Color(0xFF0A0E1A);   // near-black navy
  static const Color surface = Color(0xFF111827);      // dark card
  static const Color surfaceAlt = Color(0xFF1C2333);   // slightly lighter card
  static const Color danger = Color(0xFFFF4444);       // emergency red
  static const Color warning = Color(0xFFFFAA00);      // alert amber
  static const Color textPrimary = Color(0xFFE8F0FE);
  static const Color textMuted = Color(0xFF6B7280);

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      surface: surface,
      error: danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: primary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
      iconTheme: IconThemeData(color: primary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
    ),
//     cardTheme: CardTheme(
//   color: surface,  // ✅ works if surface is defined above
//   elevation: 0,
//   margin: EdgeInsets.zero,
// ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(color: textPrimary),
      bodySmall: TextStyle(color: textMuted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      hintStyle: const TextStyle(color: textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1),
      ),
    ),
  );
}