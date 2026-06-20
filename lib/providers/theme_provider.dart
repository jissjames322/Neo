import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class ThemeState {
  final String themeName;
  final Color customBg;
  final Color customCard;
  final Color customAccent;

  ThemeState({
    required this.themeName,
    required this.customBg,
    required this.customCard,
    required this.customAccent,
  });

  ThemeData get themeData => AppTheme.getTheme(
        themeName,
        customBg: customBg,
        customCard: customCard,
        customAccent: customAccent,
      );

  ThemeState copyWith({
    String? themeName,
    Color? customBg,
    Color? customCard,
    Color? customAccent,
  }) {
    return ThemeState(
      themeName: themeName ?? this.themeName,
      customBg: customBg ?? this.customBg,
      customCard: customCard ?? this.customCard,
      customAccent: customAccent ?? this.customAccent,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  final SettingsService _settings = SettingsService.instance;

  @override
  ThemeState build() {
    _loadTheme();
    return ThemeState(
      themeName: 'dark',
      customBg: const Color(0xFF0F1115),
      customCard: const Color(0xFF1A1D24),
      customAccent: const Color(0xFF9D4EDD),
    );
  }

  Future<void> _loadTheme() async {
    final name = await _settings.getThemeName();
    final bg = await _settings.getCustomColor('bg', const Color(0xFF0F1115));
    final card = await _settings.getCustomColor('card', const Color(0xFF1A1D24));
    final accent = await _settings.getCustomColor('accent', const Color(0xFF9D4EDD));

    state = ThemeState(
      themeName: name,
      customBg: bg,
      customCard: card,
      customAccent: accent,
    );
  }

  Future<void> setTheme(String name) async {
    await _settings.setThemeName(name);
    state = state.copyWith(themeName: name);
  }

  Future<void> setCustomColors({Color? bg, Color? card, Color? accent}) async {
    if (bg != null) {
      await _settings.setCustomColor('bg', bg);
    }
    if (card != null) {
      await _settings.setCustomColor('card', card);
    }
    if (accent != null) {
      await _settings.setCustomColor('accent', accent);
    }
    state = ThemeState(
      themeName: state.themeName,
      customBg: bg ?? state.customBg,
      customCard: card ?? state.customCard,
      customAccent: accent ?? state.customAccent,
    );
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});
