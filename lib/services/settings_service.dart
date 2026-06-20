import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._init();
  SharedPreferences? _prefs;

  SettingsService._init();

  Future<SharedPreferences> get prefs async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  // --- Onboarding & Genres ---

  Future<bool> isOnboardingCompleted() async {
    final p = await prefs;
    return p.getBool('onboarding_completed') ?? false;
  }

  Future<void> setOnboardingCompleted(bool val) async {
    final p = await prefs;
    await p.setBool('onboarding_completed', val);
  }

  Future<List<String>> getSelectedGenres() async {
    final p = await prefs;
    return p.getStringList('selected_genres') ?? [];
  }

  Future<void> setSelectedGenres(List<String> genres) async {
    final p = await prefs;
    await p.setStringList('selected_genres', genres);
  }

  // --- Themes ---

  Future<String> getThemeName() async {
    final p = await prefs;
    return p.getString('theme_name') ?? 'dark';
  }

  Future<void> setThemeName(String name) async {
    final p = await prefs;
    await p.setString('theme_name', name);
  }

  Future<double> getAnimationSpeed() async {
    final p = await prefs;
    return p.getDouble('animation_speed') ?? 1.0;
  }

  Future<void> setAnimationSpeed(double factor) async {
    final p = await prefs;
    await p.setDouble('animation_speed', factor);
  }

  // --- Custom Theme Colors ---

  Future<Color> getCustomColor(String key, Color defaultColor) async {
    final p = await prefs;
    final val = p.getInt('custom_color_$key');
    if (val != null) return Color(val);
    return defaultColor;
  }

  Future<void> setCustomColor(String key, Color color) async {
    final p = await prefs;
    await p.setInt('custom_color_$key', color.toARGB32());
  }

  // --- Audio Settings ---

  Future<double> getCrossfadeDuration() async {
    final p = await prefs;
    return p.getDouble('audio_crossfade') ?? 0.0; // 0.0 means off
  }

  Future<void> setCrossfadeDuration(double seconds) async {
    final p = await prefs;
    await p.setDouble('audio_crossfade', seconds);
  }

  Future<bool> isVolumeNormalizationEnabled() async {
    final p = await prefs;
    return p.getBool('volume_normalization') ?? false;
  }

  Future<void> setVolumeNormalization(bool enabled) async {
    final p = await prefs;
    await p.setBool('volume_normalization', enabled);
  }

  Future<double> getPlaybackSpeed() async {
    final p = await prefs;
    return p.getDouble('playback_speed') ?? 1.0;
  }

  Future<void> setPlaybackSpeed(double speed) async {
    final p = await prefs;
    await p.setDouble('playback_speed', speed);
  }

  // --- Equalizer Settings ---

  Future<List<double>> getEqualizerBands() async {
    final p = await prefs;
    final encoded = p.getString('equalizer_bands');
    if (encoded != null) {
      try {
        final list = jsonDecode(encoded) as List;
        return list.map((e) => (e as num).toDouble()).toList();
      } catch (_) {}
    }
    // Default flat bands (e.g. 5 bands all at 0.0 gain)
    return [0.0, 0.0, 0.0, 0.0, 0.0];
  }

  Future<void> setEqualizerBands(List<double> bands) async {
    final p = await prefs;
    await p.setString('equalizer_bands', jsonEncode(bands));
  }

  // --- Language & Privacy ---

  Future<String> getLanguage() async {
    final p = await prefs;
    return p.getString('language') ?? 'en';
  }

  Future<void> setLanguage(String lang) async {
    final p = await prefs;
    await p.setString('language', lang);
  }

  Future<bool> isHistoryTrackingEnabled() async {
    final p = await prefs;
    return p.getBool('history_tracking') ?? true;
  }

  Future<void> setHistoryTracking(bool enabled) async {
    final p = await prefs;
    await p.setBool('history_tracking', enabled);
  }

  // --- Neo Shield Stats ---

  Future<int> getShieldBlockedCount() async {
    final p = await prefs;
    return p.getInt('shield_blocked_count') ?? 0;
  }

  Future<void> incrementShieldBlockedCount(int val) async {
    final p = await prefs;
    final current = p.getInt('shield_blocked_count') ?? 0;
    await p.setInt('shield_blocked_count', current + val);
  }

  Future<double> getShieldDataSavedMb() async {
    final p = await prefs;
    return p.getDouble('shield_data_saved_mb') ?? 0.0;
  }

  Future<void> incrementShieldDataSavedMb(double val) async {
    final p = await prefs;
    final current = p.getDouble('shield_data_saved_mb') ?? 0.0;
    await p.setDouble('shield_data_saved_mb', current + val);
  }

  Future<bool> isShieldEnabled() async {
    final p = await prefs;
    return p.getBool('shield_enabled') ?? true;
  }

  Future<void> setShieldEnabled(bool enabled) async {
    final p = await prefs;
    await p.setBool('shield_enabled', enabled);
  }

  // --- Reset All Preferences ---

  Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
}
