import 'package:flutter/material.dart';

/// Centralised theme definitions.
///
/// Three themes live here:
///   * [light]     — default light theme (Material 3).
///   * [dark]      — default dark theme (Material 3).
///   * [calm]      — deliberately low-stimulation theme used *only* on the
///                   safety-plan / Calm screen. Muted colours, minimal
///                   contrast variation, large default tap targets.
///
/// The seed colour is a muted teal-blue; it reads as calm without feeling
/// clinical, and has acceptable contrast against both white and near-black.
class AppTheme {
  AppTheme._();

  static const Color _seed = Color(0xFF4A7C74);

  static ThemeData light() => _base(Brightness.light);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF111817),
      surfaceContainerLowest: const Color(0xFF0D1413),
      surfaceContainerLow: const Color(0xFF182221),
      surfaceContainer: const Color(0xFF1D2927),
      surfaceContainerHigh: const Color(0xFF263331),
      surfaceContainerHighest: const Color(0xFF303D3B),
      onSurface: const Color(0xFFE5ECE9),
      onSurfaceVariant: const Color(0xFFC3D0CC),
      primary: const Color(0xFF9BCDC3),
      onPrimary: const Color(0xFF073731),
      primaryContainer: const Color(0xFF24544D),
      onPrimaryContainer: const Color(0xFFD2F1EC),
      secondaryContainer: const Color(0xFF344B47),
      onSecondaryContainer: const Color(0xFFD7E7E3),
      outline: const Color(0xFF84938F),
    );
    return _base(
      Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0D1413),
    );
  }

  static ThemeData _base(
    Brightness brightness, {
    ColorScheme? colorScheme,
    Color? scaffoldBackgroundColor,
  }) {
    final scheme = colorScheme ??
        ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: brightness,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 48),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: scheme.surfaceContainerLow,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.55),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: brightness == Brightness.dark,
        fillColor: brightness == Brightness.dark
            ? scheme.surfaceContainerLow
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        textColor: scheme.onSurface,
      ),
    );
  }

  /// Low-stimulation theme for the Calm screen.
  ///
  /// Design decisions:
  ///   * Always dark (reduced glare / visual stimulation).
  ///   * No red or orange anywhere in the palette.
  ///   * Muted, desaturated colours.
  ///   * Large tap targets (minimum 64pt height) — easy to hit when
  ///     dysregulated.
  ///   * Minimal type hierarchy (no decorative weights).
  static ThemeData calm() {
    const bg = Color(0xFF1B2430);
    const surface = Color(0xFF26313F);
    const onSurface = Color(0xFFE8ECEF);
    const accent = Color(0xFF8AB0A8);

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: bg,
      onSurface: onSurface,
      surfaceContainerHighest: surface,
      primary: accent,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 18, height: 1.5, color: onSurface),
        bodyMedium: TextStyle(fontSize: 16, height: 1.5, color: onSurface),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(120, 64),
          textStyle: const TextStyle(fontSize: 18),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
