import 'package:flutter/material.dart';

class AppTheme {
  // Theme Keys
  static const String dark = 'dark';
  static const String midnightBlue = 'midnight_blue';
  static const String neonCyan = 'neon_cyan';
  static const String emerald = 'emerald';
  static const String sunset = 'sunset';
  static const String custom = 'custom';

  static ThemeData getTheme(String name, {Color? customBg, Color? customCard, Color? customAccent}) {
    switch (name) {
      case midnightBlue:
        return buildTheme(
          brightness: Brightness.dark,
          bg: const Color(0xFF0A1128),
          card: const Color(0xFF1C2541),
          accent: const Color(0xFF00B4D8),
        );
      case neonCyan:
        return buildTheme(
          brightness: Brightness.dark,
          bg: const Color(0xFF050505),
          card: const Color(0xFF121212),
          accent: const Color(0xFF00FFCC),
        );
      case emerald:
        return buildTheme(
          brightness: Brightness.dark,
          bg: const Color(0xFF0B1A15),
          card: const Color(0xFF132E27),
          accent: const Color(0xFF2EC4B6),
        );
      case sunset:
        return buildTheme(
          brightness: Brightness.dark,
          bg: const Color(0xFF150A15),
          card: const Color(0xFF261426),
          accent: const Color(0xFFF72585),
        );
      case custom:
        return buildTheme(
          brightness: Brightness.dark,
          bg: customBg ?? const Color(0xFF0F1115),
          card: customCard ?? const Color(0xFF1A1D24),
          accent: customAccent ?? Colors.deepPurpleAccent,
        );
      case dark:
      default:
        return buildTheme(
          brightness: Brightness.dark,
          bg: const Color(0xFF0F1115),
          card: const Color(0xFF1A1D24),
          accent: const Color(0xFF9D4EDD), // Royal purple
        );
    }
  }

  static ThemeData buildTheme({
    required Brightness brightness,
    required Color bg,
    required Color card,
    required Color accent,
  }) {
    final base = ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      cardColor: card,
      colorScheme: ColorScheme.dark(
        surface: card,
        primary: accent,
        secondary: accent.withValues(alpha: 0.8),
      ),
      useMaterial3: true,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: accent,
        inactiveTrackColor: accent.withValues(alpha: 0.24),
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.12),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: Colors.grey,
        textColor: Colors.white,
        selectedColor: accent,
        selectedTileColor: accent.withValues(alpha: 0.1),
      ),
    );
  }
}
