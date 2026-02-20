import 'package:flutter/material.dart';
import '../constants/app_styles.dart';

class AppThemes {
  // light theme
  static final ThemeData light = ThemeData(
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.secondaryColor,
    brightness: Brightness.light,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.secondaryColor,
      elevation: 0,
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
      ),
      titleTextStyle: AppTextStyle.h2.copyWith(color: AppColors.textPrimary),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      primary: AppColors.primaryColor,
      secondary: AppColors.accentColor,
      brightness: Brightness.light,
      surface: AppColors.secondaryColor,
      background: AppColors.secondaryColor,
    ),
    cardColor: AppColors.secondaryColor,
    // cardTheme: CardTheme(
    //   color: AppColors.secondaryColor,
    //   elevation: 2,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(12),
    //   ),
    // ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: AppTextStyle.buttonMedium,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        side: const BorderSide(color: AppColors.primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: AppTextStyle.buttonMedium.copyWith(
          color: AppColors.primaryColor,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.secondaryLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.secondaryDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
      labelStyle: AppTextStyle.labelMedium,
      hintStyle: AppTextStyle.bodySmall.copyWith(color: AppColors.textLight),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.secondaryColor,
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: AppColors.textLight,
    ),
  );

  // dark theme
  static final ThemeData dark = ThemeData(
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    brightness: Brightness.dark,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      iconTheme: const IconThemeData(
        color: AppColors.secondaryColor,
      ),
      titleTextStyle: AppTextStyle.h2.copyWith(color: AppColors.secondaryColor),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      primary: AppColors.primaryColor,
      secondary: AppColors.accentColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E1E1E),
      background: AppColors.backgroundDark,
    ),
    cardColor: const Color(0xFF1E1E1E),
    // cardTheme: CardTheme(
    //   color: const Color(0xFF1E1E1E),
    //   elevation: 2,
    //   shape: RoundedRectangleBorder(
    //     borderRadius: BorderRadius.circular(12),
    //   ),
    // ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: AppTextStyle.buttonMedium,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        side: const BorderSide(color: AppColors.primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: AppTextStyle.buttonMedium.copyWith(
          color: AppColors.primaryColor,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2D2D2D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF404040)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
      labelStyle: AppTextStyle.labelMedium.copyWith(color: AppColors.textLight),
      hintStyle: AppTextStyle.bodySmall.copyWith(color: AppColors.textLight),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: AppColors.primaryColor,
      unselectedItemColor: Color(0xFF95A5A6),
    ),
  );
}