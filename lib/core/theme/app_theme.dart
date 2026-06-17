import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.primaryBlue),
  );

  static ThemeData dark = ThemeData.dark().copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryGreen),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.primaryGreen),
  );
}
