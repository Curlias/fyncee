import 'package:flutter/material.dart';

class FynceeColors {
  // Dark theme colors (por defecto)
  static const Color background = Color(0xFF0A0E27);
  static const Color surface = Color(0xFF1C1F3A);
  static const Color surfaceLight = Color(0xFF2A2D4A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B3C1);
  static const Color textTertiary = Color(0xFF6B7280);
  
  // Light theme colors
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFF0F2F5);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);
  
  // Common colors
  static const Color primary = Color(0xFF00D9FF);
  static const Color primaryDark = Color(0xFF0099CC);

  // Accent colors
  static const Color incomeGreen = Color(0xFF00D68F);
  static const Color expenseRed = Color(0xFFFF3B69);
  static const Color error = Color(0xFFFF3B69);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  static const Color success = Color(0xFF00D68F);

  // Category colors
  static const Color categoryFood = Color(0xFFFFA726);
  static const Color categoryTransport = Color(0xFF42A5F5);
  static const Color categoryTech = Color(0xFF66BB6A);
  static const Color categoryClothing = Color(0xFFFFCA28);
  static const Color categoryHealth = Color(0xFFEF5350);
  static const Color categoryTravel = Color(0xFF26C6DA);
  static const Color categoryEntertainment = Color(0xFFAB47BC);
  static const Color categoryGeneral = Color(0xFF78909C);
}

class FynceeTheme {
  // Color principal (para usar directamente)
  static const Color primaryColor = FynceeColors.primary;
  
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: FynceeColors.primary,
        onPrimary: FynceeColors.background,
        secondary: FynceeColors.primaryDark,
        onSecondary: FynceeColors.textPrimary,
        surface: FynceeColors.surface,
        onSurface: FynceeColors.textPrimary,
        error: FynceeColors.expenseRed,
        onError: FynceeColors.textPrimary,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: FynceeColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: FynceeColors.background,
        elevation: 0,
        centerTitle: false,
        foregroundColor: FynceeColors.textPrimary,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: FynceeColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: FynceeColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: FynceeColors.primary,
        foregroundColor: FynceeColors.background,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FynceeColors.primary,
          foregroundColor: FynceeColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: FynceeColors.surface,
        selectedItemColor: FynceeColors.primary,
        unselectedItemColor: FynceeColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: FynceeColors.textPrimary,
        displayColor: FynceeColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FynceeColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: FynceeColors.primary, width: 2),
        ),
        hintStyle: base.textTheme.bodyMedium?.copyWith(
          color: FynceeColors.textSecondary,
        ),
        labelStyle: base.textTheme.bodyMedium?.copyWith(
          color: FynceeColors.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FynceeColors.surface,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: FynceeColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: FynceeColors.primary,
        onPrimary: Colors.white,
        secondary: FynceeColors.primaryDark,
        onSecondary: Colors.white,
        surface: FynceeColors.lightSurface,
        onSurface: FynceeColors.lightTextPrimary,
        error: FynceeColors.expenseRed,
        onError: Colors.white,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: FynceeColors.lightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: FynceeColors.lightBackground,
        elevation: 0,
        centerTitle: false,
        foregroundColor: FynceeColors.lightTextPrimary,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: FynceeColors.lightTextPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: FynceeColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: FynceeColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FynceeColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: FynceeColors.lightSurface,
        selectedItemColor: FynceeColors.primary,
        unselectedItemColor: FynceeColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: FynceeColors.lightTextPrimary,
        displayColor: FynceeColors.lightTextPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FynceeColors.lightSurfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: FynceeColors.primary, width: 2),
        ),
        hintStyle: base.textTheme.bodyMedium?.copyWith(
          color: FynceeColors.lightTextSecondary,
        ),
        labelStyle: base.textTheme.bodyMedium?.copyWith(
          color: FynceeColors.lightTextSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FynceeColors.lightSurface,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: FynceeColors.lightTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
