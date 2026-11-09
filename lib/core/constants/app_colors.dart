import 'package:flutter/material.dart';

class AppColors {
  // ── Light Neumorphic Canvas (Soft Off-White / Grey) ───────────────
  // Exact palette matching the reference image: soft, tactile, porcelain grey
  static const Color neuBase = Color(0xFFE2E7EE);        // Base Canvas (#E2E7EE)
  static const Color neuLightShadow = Color(0xFFFFFFFF); // Pure White Light Reflection (Top-Left)
  static const Color neuDarkShadow = Color(0xFFA6B4C9);  // Soft Slate Shadow (Bottom-Right)

  // Surface variations
  static const Color surface = neuBase;
  static const Color background = neuBase;
  static const Color surfaceElevated = Color(0xFFE8EDF5);
  static const Color border = Color(0xFFD5DFEC);

  // ── Typography (Dark Charcoal & Slate Grey) ──────────────────────
  static const Color textPrimary = Color(0xFF242C38);   // Deep Charcoal Slate
  static const Color textSecondary = Color(0xFF6B7A90); // Medium Slate Grey
  static const Color textMuted = Color(0xFF98A6BA);     // Soft Muted Grey

  // ── Accents & Controls ───────────────────────────────────────────
  static const Color primary = Color(0xFF242C38);        // Primary Action Dark
  static const Color accent = Color(0xFF4A5568);         // Secondary Slate
  static const Color activeBlue = Color(0xFF3B82F6);     // Soft Active Blue

  // ── Status Indicators ────────────────────────────────────────────
  static const Color normal = Color(0xFF10B981);         // Emerald Green
  static const Color active = Color(0xFF242C38);         // Active Dark
  static const Color warning = Color(0xFFF59E0B);        // Warm Amber
  static const Color danger = Color(0xFFEF4444);         // Soft Rose Red

  // ── Neumorphic Shadow Builders ───────────────────────────────────
  /// Dual soft shadow creating the extruded 3D effect in light mode
  static List<BoxShadow> neuElevation({
    double distance = 6.0,
    double blur = 14.0,
    Color? darkColor,
    Color? lightColor,
    Color? glowColor,
    double glowRadius = 0.0,
  }) {
    return [
      if (glowColor != null && glowRadius > 0)
        BoxShadow(
          color: glowColor,
          offset: Offset.zero,
          blurRadius: glowRadius,
          spreadRadius: 1,
        ),
      BoxShadow(
        color: (darkColor ?? neuDarkShadow).withAlpha(160),
        offset: Offset(distance, distance),
        blurRadius: blur,
      ),
      BoxShadow(
        color: (lightColor ?? neuLightShadow).withAlpha(240),
        offset: Offset(-distance, -distance),
        blurRadius: blur,
      ),
    ];
  }

  // ── Theme Data (Light Neumorphic) ────────────────────────────────
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: neuBase,
      primaryColor: textPrimary,
      colorScheme: const ColorScheme.light(
        primary: textPrimary,
        secondary: accent,
        surface: neuBase,
        error: danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: neuBase,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
    );
  }
}
