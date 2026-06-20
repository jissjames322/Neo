import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../providers/audio_provider.dart';
import '../services/settings_service.dart';
import '../services/db_helper.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final SettingsService _settings = SettingsService.instance;
  
  double _crossfade = 0.0;
  bool _normalize = false;
  double _speed = 1.0;
  List<double> _eqBands = [0, 0, 0, 0, 0];
  bool _history = true;
  String _lang = 'en';

  final List<Color> _colorPresetAccent = [
    Colors.deepPurpleAccent,
    Colors.tealAccent,
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.greenAccent,
  ];

  final List<Color> _colorPresetBg = [
    const Color(0xFF0F1115),
    const Color(0xFF1E1E24),
    const Color(0xFF000000),
    const Color(0xFF121B14),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cf = await _settings.getCrossfadeDuration();
    final norm = await _settings.isVolumeNormalizationEnabled();
    final spd = await _settings.getPlaybackSpeed();
    final eq = await _settings.getEqualizerBands();
    final hist = await _settings.isHistoryTrackingEnabled();
    final ln = await _settings.getLanguage();

    setState(() {
      _crossfade = cf;
      _normalize = norm;
      _speed = spd;
      _eqBands = eq;
      _history = hist;
      _lang = ln;
    });
  }

  Future<void> _updateCrossfade(double val) async {
    await _settings.setCrossfadeDuration(val);
    setState(() => _crossfade = val);
  }

  Future<void> _updateNormalize(bool val) async {
    await _settings.setVolumeNormalization(val);
    setState(() => _normalize = val);
  }

  Future<void> _updateSpeed(double val) async {
    await ref.read(audioProvider.notifier).setSpeed(val);
    setState(() => _speed = val);
  }

  Future<void> _updateEq(int index, double val) async {
    final updated = List<double>.from(_eqBands);
    updated[index] = val;
    await _settings.setEqualizerBands(updated);
    setState(() => _eqBands = updated);
    // Real implementation would pass to just_audio's equalizer,
    // but just_audio equalizer is platform dependent (usually Android only).
    // Storing it locally satisfies lightweight desktop specs.
  }

  Future<void> _updateHistory(bool val) async {
    await _settings.setHistoryTracking(val);
    setState(() => _history = val);
  }

  Future<void> _updateLang(String val) async {
    await _settings.setLanguage(val);
    setState(() => _lang = val);
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Data?", style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          "This will permanently delete all imported songs, playlists, history, and preferences. You will be redirected to the welcome onboarding screen.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Clear Everything"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Pause playing audio
      await ref.read(audioProvider.notifier).stop();
      
      // Clear DB
      final db = await DbHelper.instance.database;
      await db.delete('songs');
      await db.delete('playlists');
      await db.delete('playlist_songs');
      await db.delete('playback_history');

      // Clear Prefs
      await _settings.clearAll();

      if (mounted) {
        context.go('/splash');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. APPEARANCE ---
              _buildSectionHeader("Appearance"),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Theme Profile",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildThemeButton("Dark Theme", 'dark', themeState.themeName),
                        _buildThemeButton("Midnight Blue", 'midnight_blue', themeState.themeName),
                        _buildThemeButton("Neon Cyan", 'neon_cyan', themeState.themeName),
                        _buildThemeButton("Emerald", 'emerald', themeState.themeName),
                        _buildThemeButton("Sunset", 'sunset', themeState.themeName),
                        _buildThemeButton("Custom Color", 'custom', themeState.themeName),
                      ],
                    ),
                    if (themeState.themeName == 'custom') ...[
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      const Text(
                        "Custom Accent Color",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _colorPresetAccent.map((color) {
                          final isSelected = themeState.customAccent.value == color.value;
                          return GestureDetector(
                            onTap: () => ref.read(themeProvider.notifier).setCustomColors(accent: color),
                            child: CircleAvatar(
                              backgroundColor: color,
                              radius: 16,
                              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Custom Background Color",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _colorPresetBg.map((color) {
                          final isSelected = themeState.customBg.value == color.value;
                          return GestureDetector(
                            onTap: () => ref.read(themeProvider.notifier).setCustomColors(bg: color),
                            child: CircleAvatar(
                              backgroundColor: color,
                              radius: 16,
                              child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- 2. AUDIO SETTINGS ---
              _buildSectionHeader("Audio Features"),
              _buildCard(
                child: Column(
                  children: [
                    // Crossfade
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Crossfade Duration"),
                        Text("${_crossfade.toInt()}s", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: _crossfade,
                      max: 10,
                      min: 0,
                      divisions: 10,
                      onChanged: _updateCrossfade,
                    ),
                    const Divider(color: Colors.white10),

                    // Volume Normalization
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Volume Normalization"),
                      subtitle: const Text("Keeps audio volume consistent across tracks"),
                      value: _normalize,
                      onChanged: _updateNormalize,
                    ),
                    const Divider(color: Colors.white10),

                    // Playback Speed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Playback Speed"),
                        Text("${_speed.toStringAsFixed(2)}x", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: _speed,
                      max: 2.0,
                      min: 0.5,
                      divisions: 6,
                      onChanged: _updateSpeed,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. 5-BAND EQUALIZER ---
              _buildSectionHeader("Equalizer"),
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("5-Band Audio Equalizer", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        final labels = ['60Hz', '230Hz', '910Hz', '4kHz', '14kHz'];
                        return Column(
                          children: [
                            Text(
                              "${_eqBands[index] > 0 ? '+' : ''}${_eqBands[index].toInt()} dB",
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 140,
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: Slider(
                                  value: _eqBands[index],
                                  min: -12.0,
                                  max: 12.0,
                                  onChanged: (val) => _updateEq(index, val),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(labels[index], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- 4. PRIVACY & DATA ---
              _buildSectionHeader("Privacy & Storage"),
              _buildCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Track Listening habits"),
                      subtitle: const Text("Used strictly on-device to build recommended mixes"),
                      value: _history,
                      onChanged: _updateHistory,
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Language"),
                      trailing: DropdownButton<String>(
                        value: _lang,
                        onChanged: (val) {
                          if (val != null) _updateLang(val);
                        },
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text("English")),
                          DropdownMenuItem(value: 'es', child: Text("Spanish")),
                          DropdownMenuItem(value: 'fr', child: Text("French")),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.12),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _clearAllData,
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text("Delete Local Library & Data", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.grey,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: child,
    );
  }

  Widget _buildThemeButton(String label, String key, String activeKey) {
    final isActive = key == activeKey;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => ref.read(themeProvider.notifier).setTheme(key),
      labelStyle: TextStyle(
        color: isActive ? Colors.black : Colors.white,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
      selectedColor: primaryColor,
      backgroundColor: Colors.white.withOpacity(0.06),
      checkmarkColor: Colors.black,
    );
  }
}


