import 'package:flutter/material.dart';

class AppColors {
  static const Color cohereBlack = Color(0xFF000000);
  static const Color nearBlackPrimary = Color(0xFF17171c);
  static const Color deepEnterpriseGreen = Color(0xFF003c33);
  static const Color darkNavy = Color(0xFF071829);
  static const Color actionBlue = Color(0xFF1863dc);
  static const Color coral = Color(0xFFff7759);
  static const Color softCoral = Color(0xFFffad9b);
  static const Color canvasWhite = Color(0xFFffffff);
  static const Color softStone = Color(0xFFeeece7);
  static const Color ink = Color(0xFF212121);
  static const Color mutedSlate = Color(0xFF93939f);
  static const Color hairline = Color(0xFFd9d9dd);
  static const Color borderLight = Color(0xFFe5e7eb);
  static const Color errorRed = Color(0xFFb30000);
  static const Color focusBlue = Color(0xFF4c6ee6);
}

class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 22.0;
  static const double xl = 30.0;
  static const double pill = 32.0;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Unica77',
    fontSize: 72,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.92,
    color: AppColors.ink,
    height: 1.0,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Unica77',
    fontSize: 48,
    fontWeight: FontWeight.w400,
    letterSpacing: -1.2,
    color: AppColors.ink,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Unica77',
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.32,
    color: AppColors.ink,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Unica77',
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Unica77',
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Unica77',
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Unica77',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Unica77',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Unica77',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedSlate,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Unica77',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedSlate,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Unica77',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle input = TextStyle(
    fontFamily: 'Unica77',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: 'Unica77',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedSlate,
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.canvasWhite,
    colorScheme: const ColorScheme.light(
      primary: AppColors.cohereBlack,
      secondary: AppColors.actionBlue,
      surface: AppColors.canvasWhite,
      onPrimary: AppColors.canvasWhite,
      onSecondary: AppColors.canvasWhite,
      onSurface: AppColors.ink,
      error: AppColors.errorRed,
    ),
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      displaySmall: AppTextStyles.displaySmall,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      titleLarge: AppTextStyles.titleLarge,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.button,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.titleLarge,
      iconTheme: IconThemeData(color: AppColors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.softStone,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.actionBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.errorRed),
      ),
      hintStyle: AppTextStyles.hint,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cohereBlack,
        foregroundColor: AppColors.canvasWhite,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        textStyle: AppTextStyles.button.copyWith(color: AppColors.canvasWhite),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.softStone,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.hairline),
      ),
    ),
  );
}