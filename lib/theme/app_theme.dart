import 'package:flutter/material.dart';

class AppTheme {
  // ☀️ Scandinavian Calm
  static final ThemeData light = ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Poppins',
    useMaterial3: true,

    scaffoldBackgroundColor: const Color(0xFFF4F8F8),

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2F8293),
      secondary: Color(0xFF72B8BD),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF203440),
      onPrimary: Colors.white,
      outline: Color(0xFFD6E2E3),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF4F8F8),
      foregroundColor: Color(0xFF203440),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFF203440),
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 40,
        fontWeight: FontWeight.w500,
        color: Color(0xFF203440),
        height: 1.15,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: Color(0xFF203440),
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFF203440),
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF203440),
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Color(0xFF526A72),
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF526A72),
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE2EBEC), width: 1),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFFDCE6E7),
      thickness: 1,
      space: 1,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD6E2E3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD6E2E3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2F8293), width: 1.5),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2F8293),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      selectedItemColor: Color(0xFF2F8293),
      unselectedItemColor: Color(0xFF91A2A7),
      selectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 11),
    ),
  );

  // 🌙 Mint & Indigo
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Poppins',
    useMaterial3: true,

    scaffoldBackgroundColor: const Color(0xFF111526),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF8A7CF6),
      secondary: Color(0xFF65C9BC),
      surface: Color(0xFF191E32),
      onSurface: Color(0xFFF1F2F7),
      onPrimary: Colors.white,
      outline: Color(0xFF343A52),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111526),
      foregroundColor: Color(0xFFF1F2F7),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F2F7),
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 40,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF1F2F7),
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F2F7),
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F2F7),
      ),
      titleLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFF1F2F7),
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        color: Color(0xFFB3B9C9),
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        color: Color(0xFFB3B9C9),
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF191E32),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF2B3148), width: 1),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Color(0xFF30364D),
      thickness: 1,
      space: 1,
    ),
  );
}
