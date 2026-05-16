import 'package:flutter/material.dart';

class AppColors {
  // ── ベース ────────────────────────────────────────────
  static const bg       = Color(0xFFF7F5F0); // 暖米色
  static const bg2      = Color(0xFFFFFFFF);
  static const bg3      = Color(0xFFEDEAE3); // 暖グレー
  static const border   = Color(0xFFE0DAD0); // ヘアライン
  static const border2  = Color(0xFFCCC7BC);

  // ── アクション（操作UI専用） ──────────────────────────
  static const slate    = Color(0xFF4A4035); // ボタン・Toggle・ナビ
  static const slateDim = Color(0x144A4035);

  // ── ステータス（ホーム画面の状態表示のみ） ────────────
  static const teal     = Color(0xFF7BA8B5); // 確認済み・安全
  static const tealDim  = Color(0x217BA8B5);
  static const peach    = Color(0xFFE8A57C); // 未確認・警告
  static const peachDim = Color(0x21E8A57C);
  static const plum     = Color(0xFF8E5973); // 緊急
  static const plumDim  = Color(0x218E5973);

  // ── 破壊的操作（削除・リセット専用） ─────────────────
  static const terra    = Color(0xFFB25040);
  static const terraDim = Color(0x14B25040);

  // ── ブランド（アイコンリングのみ） ───────────────────
  static const amber    = Color(0xFFF59E0B);
  static const amberDim = Color(0x1AF59E0B);

  // ── テキスト ─────────────────────────────────────────
  static const text     = Color(0xFF2C2820);
  static const text2    = Color(0xFF6B6358);
  static const text3    = Color(0xFFA89E94);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.light(
        primary:   AppColors.slate,
        secondary: AppColors.peach,
        error:     AppColors.terra,
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
          borderSide: BorderSide(color: AppColors.slate, width: 1.5),
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
        backgroundColor: AppColors.bg,
        selectedItemColor: AppColors.slate,
        unselectedItemColor: AppColors.text3,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.1,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 9, letterSpacing: 0.1),
      ),
    );
  }
}
