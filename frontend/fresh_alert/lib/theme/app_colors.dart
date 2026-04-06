import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// FRESH ALERT — CENTRALIZED COLOR PALETTE
// ═══════════════════════════════════════════════════════════════════════════════
//
// Every colour the app uses lives here. To re-skin the entire app,
// change the values in this single file.
//
// Usage in widgets:
//   final c = AppColors.of(context);   // picks light/dark automatically
//   c.primary, c.scaffoldBg, c.cardBg, etc.
// ═══════════════════════════════════════════════════════════════════════════════

/// Semantic status colours — shared between both themes.
class StatusColors {
  const StatusColors._();

  /// Healthy / fresh items
  static const green = Color(0xFF1DB954);   // Spotify green

  /// Expiring soon warnings
  static const orange = Color(0xFFF59E0B);  // warm amber

  /// Expired / danger
  static const red = Color(0xFFEF4444);     // clean red
}

// ─────────────────────────────────────────────────────────────────────────────
// LIGHT PALETTE
// ─────────────────────────────────────────────────────────────────────────────

class _LightColors extends AppColors {
  const _LightColors();

  // ── Brand ──────────────────────────────────────────────────────────────────
  @override Color get primary            => const Color(0xFF1AA34A);  // Spotify-inspired — good contrast on light
  @override Color get onPrimary          => const Color(0xFFFFFFFF);
  @override Color get primaryContainer   => const Color(0xFFD4EDDA);
  @override Color get onPrimaryContainer => const Color(0xFF003D20);

  // ── Surfaces ───────────────────────────────────────────────────────────────
  @override Color get scaffoldBg            => const Color(0xFFF5F3EE);   // warm linen
  @override Color get surface              => const Color(0xFFFFFFFF);    // white cards
  @override Color get surfaceContainerLow  => const Color(0xFFF9F7F2);   // subtle warm layer
  @override Color get surfaceContainer     => const Color(0xFFF0EDE7);   // inputs, search bars
  @override Color get surfaceContainerHigh => const Color(0xFFE8E5DF);   // elevated cards, bottom nav

  // ── Text & Icons ───────────────────────────────────────────────────────────
  @override Color get onSurface         => const Color(0xFF1C1917);      // warm near-black
  @override Color get onSurfaceVariant  => const Color(0xFF78716C);      // stone-500 for subtitles
  @override Color get outline           => const Color(0xFFD6D3CD);      // soft border
  @override Color get outlineVariant    => const Color(0xFFC8C4BD);      // stronger border

  // ── Secondary / Tertiary ────────────────────────────────────────────────────
  @override Color get secondary            => const Color(0xFF57534E);
  @override Color get onSecondary          => Colors.white;
  @override Color get secondaryContainer   => const Color(0xFFE7E5E4);
  @override Color get onSecondaryContainer => const Color(0xFF1C1917);
  @override Color get tertiary             => const Color(0xFF0D9488);
  @override Color get onTertiary           => Colors.white;

  // ── Error ──────────────────────────────────────────────────────────────────
  @override Color get error   => const Color(0xFFDC2626);
  @override Color get onError => Colors.white;

  // ── Miscellaneous ──────────────────────────────────────────────────────────
  @override Brightness get brightness => Brightness.light;

  // Hero card gradient
  @override Color get heroGradientStart => const Color(0xFFD1FAE5); // emerald-100
  @override Color get heroGradientEnd   => const Color(0xFFF0FDF4); // emerald-50

  // Drag handle inside bottom sheets
  @override Color get dragHandle => const Color(0xFFD6D3CD);

  // Snackbar
  @override Color get snackbarBg   => const Color(0xFF292524);  // stone-800
  @override Color get snackbarText => const Color(0xFFFAFAF9);  // stone-50
}

// ─────────────────────────────────────────────────────────────────────────────
// DARK PALETTE
// ─────────────────────────────────────────────────────────────────────────────

class _DarkColors extends AppColors {
  const _DarkColors();

  // ── Brand ──────────────────────────────────────────────────────────────────
  @override Color get primary            => const Color(0xFF1DB954);  // Spotify green — pops on dark
  @override Color get onPrimary          => const Color(0xFF003D20);
  @override Color get primaryContainer   => const Color(0xFF0A5C2F);
  @override Color get onPrimaryContainer => const Color(0xFFB8F1C8);

  // ── Surfaces ───────────────────────────────────────────────────────────────
  @override Color get scaffoldBg            => const Color(0xFF0C0A09);   // stone-950
  @override Color get surface              => const Color(0xFF1C1917);    // stone-900
  @override Color get surfaceContainerLow  => const Color(0xFF121110);   // between 950 and 900
  @override Color get surfaceContainer     => const Color(0xFF1C1917);   // stone-900
  @override Color get surfaceContainerHigh => const Color(0xFF292524);   // stone-800

  // ── Text & Icons ───────────────────────────────────────────────────────────
  @override Color get onSurface         => const Color(0xFFFAFAF9);      // stone-50
  @override Color get onSurfaceVariant  => const Color(0xFFA8A29E);      // stone-400
  @override Color get outline           => const Color(0xFF44403C);      // stone-700
  @override Color get outlineVariant    => const Color(0xFF292524);      // stone-800

  // ── Secondary / Tertiary ────────────────────────────────────────────────────
  @override Color get secondary            => const Color(0xFFA8A29E);
  @override Color get onSecondary          => const Color(0xFF1C1917);
  @override Color get secondaryContainer   => const Color(0xFF44403C);
  @override Color get onSecondaryContainer => const Color(0xFFE7E5E4);
  @override Color get tertiary             => const Color(0xFF5EEAD4);
  @override Color get onTertiary           => const Color(0xFF003D36);

  // ── Error ──────────────────────────────────────────────────────────────────
  @override Color get error   => const Color(0xFFFCA5A5);  // red-300
  @override Color get onError => const Color(0xFF7F1D1D);

  // ── Miscellaneous ──────────────────────────────────────────────────────────
  @override Brightness get brightness => Brightness.dark;

  // Hero card gradient
  @override Color get heroGradientStart => const Color(0xFF1A3D2B);
  @override Color get heroGradientEnd   => const Color(0xFF0D2318);

  // Drag handle
  @override Color get dragHandle => const Color(0xFF57534E); // stone-600

  // Snackbar
  @override Color get snackbarBg   => const Color(0xFF292524);
  @override Color get snackbarText => const Color(0xFFFAFAF9);
}

// ─────────────────────────────────────────────────────────────────────────────
// ABSTRACT CONTRACT  —  every palette must define these properties
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppColors {
  const AppColors();

  // ── Singletons ─────────────────────────────────────────────────────────────
  static const light = _LightColors();
  static const dark  = _DarkColors();

  /// Pick the right palette based on current brightness.
  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  // ── Brand ──────────────────────────────────────────────────────────────────
  Color get primary;
  Color get onPrimary;
  Color get primaryContainer;
  Color get onPrimaryContainer;

  // ── Surfaces ───────────────────────────────────────────────────────────────
  Color get scaffoldBg;
  Color get surface;
  Color get surfaceContainerLow;
  Color get surfaceContainer;
  Color get surfaceContainerHigh;

  // ── Text & Icons ───────────────────────────────────────────────────────────
  Color get onSurface;
  Color get onSurfaceVariant;
  Color get outline;
  Color get outlineVariant;

  // ── Secondary / Tertiary ────────────────────────────────────────────────────
  Color get secondary;
  Color get onSecondary;
  Color get secondaryContainer;
  Color get onSecondaryContainer;
  Color get tertiary;
  Color get onTertiary;

  // ── Error ──────────────────────────────────────────────────────────────────
  Color get error;
  Color get onError;

  // ── Meta ───────────────────────────────────────────────────────────────────
  Brightness get brightness;

  // ── Semantic extras ────────────────────────────────────────────────────────
  Color get heroGradientStart;
  Color get heroGradientEnd;
  Color get dragHandle;
  Color get snackbarBg;
  Color get snackbarText;

  // ── Helper: build a Flutter ColorScheme from this palette ──────────────────
  ColorScheme toColorScheme() => ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    error: error,
    onError: onError,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHighest: surfaceContainerHigh,
    outline: outline,
    outlineVariant: outlineVariant,
  );
}
