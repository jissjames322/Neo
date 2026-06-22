import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          bg: const Color(0xFF070D1E),
          card: const Color(0xFF121E3A),
          accent: const Color(0xFF00B4D8),
        );
      case neonCyan:
        return buildTheme(
          brightness: Brightness.dark,
          bg: const Color(0xFF030303),
          card: const Color(0xFF0D0D0D),
          accent: const Color(0xFF00FFCC),
        );
      case emerald:
        return buildTheme(
          brightness: Brightness.dark,
          bg: const Color(0xFF071410),
          card: const Color(0xFF0E261E),
          accent: const Color(0xFF2EC4B6),
        );
      case sunset:
        return buildTheme(
          brightness: Brightness.dark,
          bg: const Color(0xFF100810),
          card: const Color(0xFF1E0F1E),
          accent: const Color(0xFFF72585),
        );
      case custom:
        return buildTheme(
          brightness: Brightness.dark,
          bg: customBg ?? const Color(0xFF0A0B10),
          card: customCard ?? const Color(0xFF141620),
          accent: customAccent ?? Colors.deepPurpleAccent,
        );
      case dark:
      default:
        // NEO default: Deep Space Black + Electric Violet
        return buildTheme(
          brightness: Brightness.dark,
          bg: const Color(0xFF080A10),
          card: const Color(0xFF111320),
          accent: const Color(0xFF9D4EDD),
        );
    }
  }

  static ThemeData buildTheme({
    required Brightness brightness,
    required Color bg,
    required Color card,
    required Color accent,
  }) {
    final textTheme = GoogleFonts.outfitTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).apply(bodyColor: Colors.white, displayColor: Colors.white);

    final base = ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      cardColor: card,
      colorScheme: ColorScheme.dark(
        surface: card,
        primary: accent,
        secondary: accent.withValues(alpha: 0.8),
        surfaceContainerHighest: card.withValues(alpha: 0.6),
      ),
      textTheme: textTheme,
      useMaterial3: true,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: accent,
        inactiveTrackColor: accent.withValues(alpha: 0.2),
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.12),
        trackHeight: 3.0,
      ),
      listTileTheme: base.listTileTheme.copyWith(
        iconColor: Colors.grey,
        textColor: Colors.white,
        selectedColor: accent,
        selectedTileColor: accent.withValues(alpha: 0.1),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
      ),
    );
  }
}
