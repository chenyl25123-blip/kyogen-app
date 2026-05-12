import 'package:flutter/material.dart';

class AppColors {
  // ── 柔軟パステル ───────────────────────────────
  static const bg       = Color(0xFFF5F3F8);
  static const bg2      = Color(0xFFFFFFFF);
  static const bg3      = Color(0xFFEEEBF4);
  static const border   = Color(0xFFE2DDED);
  static const border2  = Color(0xFFCFC8E0);

  static const teal     = Color(0xFF7BA8B5); // 確認済み・安全
  static const tealDim  = Color(0x217BA8B5);
  static const peach    = Color(0xFFE8A57C); // 警告
  static const peachDim = Color(0x21E8A57C);
  static const plum     = Color(0xFF8E5973); // 緊急
  static const plumDim  = Color(0x218E5973);

  static const text     = Color(0xFF3A3645);
  static const text2    = Color(0xFF7A7390);
  static const text3    = Color(0xFFB0A8C4);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.light(
        primary:   AppColors.teal,
        secondary: AppColors.peach,
        error:     AppColors.plum,
        surface:   AppColors.bg2,
        onPrimary: Colors.white,
        onSurface: AppColors.text,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.text),
        titleLarge:   TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
        bodyLarge:    TextStyle(fontSize: 16, color: AppColors.text),
        bodyMedium:   TextStyle(fontSize: 14, color: AppColors.text2),
        bodySmall:    TextStyle(fontSize: 12, color: AppColors.text3),
        labelSmall:   TextStyle(fontSize: 10, color: AppColors.text3, letterSpacing: 0.15),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bg2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg3,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.teal, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: AppColors.text3),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.text),
        titleTextStyle: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bg.withValues(alpha: 0.96),
        selectedItemColor: AppColors.teal,
        unselectedItemColor: AppColors.text3,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.1,
        ),
        unselectedLabelStyle: TextStyle(fontSize: 9, letterSpacing: 0.1),
      ),
    );
  }
}
