import 'package:flutter/material.dart';

class PMFBYColors {
  // Official Government of India Colors
  static const Color saffron = Color(0xFFFF9933); // India Flag Saffron
  static const Color white = Color(0xFFFFFFFF);
  static const Color indiaGreen = Color(0xFF138808); // India Flag Green
  static const Color navyBlue = Color(0xFF1565C0); // Government Blue
  
  // PMFBY Brand Colors - Professional & Clean
  static const Color primaryGreen = Color(0xFF1B5E20); // Deep Forest Green
  static const Color lightGreen = Color(0xFF4CAF50); // Fresh Green
  static const Color accentBlue = Color(0xFF0277BD); // Professional Blue
  static const Color accentGold = Color(0xFFFFA000); // Government Gold
  
  // Status Colors
  static const Color approved = Color(0xFF2E7D32);
  static const Color pending = Color(0xFFF57C00);
  static const Color rejected = Color(0xFFC62828);
  static const Color draft = Color(0xFF616161);
  
  // Background Colors - Clean & Professional
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textHint = Color(0xFF9E9E9E);
  
  // Government Scheme Colors
  static const Color schemeBlue = Color(0xFF1565C0);
  static const Color schemeGreen = Color(0xFF2E7D32);
  static const Color schemeOrange = Color(0xFFF57C00);
}

class PMFBYTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: PMFBYColors.primaryGreen,
      secondary: PMFBYColors.accentGold,
      tertiary: PMFBYColors.accentBlue,
      surface: PMFBYColors.backgroundWhite,
      background: PMFBYColors.backgroundLight,
      error: PMFBYColors.rejected,
      onPrimary: PMFBYColors.textLight,
      onSecondary: PMFBYColors.textLight,
      onSurface: PMFBYColors.textPrimary,
      onBackground: PMFBYColors.textPrimary,
    ),
    scaffoldBackgroundColor: PMFBYColors.backgroundLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: PMFBYColors.primaryGreen,
      foregroundColor: PMFBYColors.textLight,
      elevation: 2,
      centerTitle: false,
      shadowColor: Colors.black26,
    ),
    cardTheme: CardThemeData(
      color: PMFBYColors.cardBackground,
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PMFBYColors.primaryGreen,
        foregroundColor: PMFBYColors.textLight,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: PMFBYColors.accentBlue,
      foregroundColor: PMFBYColors.textLight,
      elevation: 4,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: PMFBYColors.backgroundWhite,
      selectedItemColor: PMFBYColors.primaryGreen,
      unselectedItemColor: PMFBYColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 16,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PMFBYColors.backgroundWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: PMFBYColors.primaryGreen.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: PMFBYColors.primaryGreen.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: PMFBYColors.primaryGreen, width: 2),
      ),
    ),
  );
}
