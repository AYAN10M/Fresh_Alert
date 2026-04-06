import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fresh_alert/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// FRESH ALERT — CENTRALIZED THEME BUILDER
// ═══════════════════════════════════════════════════════════════════════════════
//
// Builds light & dark ThemeData from AppColors.
// Every widget-level theme override (cards, dialogs, snackbars, etc.)
// is configured here — screens should never need to hardcode colours.
// ═══════════════════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppColors.light);
  static ThemeData dark()  => _build(AppColors.dark);

  static ThemeData _build(AppColors c) {
    final scheme = c.toColorScheme();
    final isDark = c.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      fontFamily: 'NotoSans',
      colorScheme: scheme,
      scaffoldBackgroundColor: c.scaffoldBg,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: c.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ),
      ),

      // ── Cards ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ── Snackbar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.snackbarBg,
        contentTextStyle: TextStyle(
          fontFamily: 'NotoSans',
          color: c.snackbarText,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Dialogs ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSans',
          fontWeight: FontWeight.w700,
          color: c.onSurface,
          fontSize: 18,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'NotoSans',
          color: c.onSurfaceVariant,
          fontSize: 14,
        ),
      ),

      // ── Bottom Sheet ───────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),

      // ── Date Picker ────────────────────────────────────────────────────────
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: c.primary,
        headerForegroundColor: c.onPrimary,
        dayForegroundColor: WidgetStatePropertyAll(c.onSurface),
        todayForegroundColor: WidgetStatePropertyAll(c.primary),
        todayBorder: BorderSide(color: c.primary),
      ),

      // ── Text Buttons (used in dialogs) ─────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: const TextStyle(
            fontFamily: 'NotoSans',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ── Input Fields ───────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainerHigh,
        hintStyle: TextStyle(
          fontFamily: 'NotoSans',
          color: c.onSurfaceVariant,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: c.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
