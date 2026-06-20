import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/settings_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final List<String> _selectedGenres = [];

  final List<Map<String, dynamic>> _genres = [
    {'name': 'Rock', 'colors': [Colors.red.shade900, Colors.orange.shade900], 'icon': Icons.album_rounded},
    {'name': 'Pop', 'colors': [Colors.pink.shade800, Colors.deepOrange.shade600], 'icon': Icons.face_rounded},
    {'name': 'Metal', 'colors': [Colors.blueGrey.shade900, Colors.grey.shade800], 'icon': Icons.bolt_rounded},
    {'name': 'EDM', 'colors': [Colors.purple.shade900, Colors.cyan.shade800], 'icon': Icons.graphic_eq_rounded},
    {'name': 'LoFi', 'colors': [Colors.amber.shade900, Colors.red.shade700], 'icon': Icons.coffee_rounded},
    {'name': 'Hip Hop', 'colors': [Colors.brown.shade800, Colors.amber.shade800], 'icon': Icons.record_voice_over_rounded},
    {'name': 'Jazz', 'colors': [Colors.indigo.shade900, Colors.blue.shade900], 'icon': Icons.library_music_rounded},
    {'name': 'Classical', 'colors': [Colors.deepPurple.shade900, Colors.amber.shade900], 'icon': Icons.piano_rounded},
    {'name': 'Indie', 'colors': [Colors.teal.shade900, const Color(0xFF2EC4B6)], 'icon': Icons.nature_people_rounded},
    {'name': 'Synthwave', 'colors': [Colors.pink.shade900, Colors.purple.shade800], 'icon': Icons.wb_twilight_rounded},
  ];

  void _toggleGenre(String name) {
    setState(() {
      if (_selectedGenres.contains(name)) {
        _selectedGenres.remove(name);
      } else {
        _selectedGenres.add(name);
      }
    });
  }

  Future<void> _completeOnboarding() async {
    final settings = SettingsService.instance;
    await settings.setSelectedGenres(_selectedGenres);
    await settings.setOnboardingCompleted(true);
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withBlue(30),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Welcome to Pulse",
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Your music habits never leave this device. Select your favorite genres to help us curate your local recommendation system.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade400,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _genres.length,
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.3,
                      ),
                      itemBuilder: (context, index) {
                        final genre = _genres[index];
                        final String name = genre['name'];
                        final List<Color> colors = genre['colors'];
                        final IconData icon = genre['icon'];
                        final isSelected = _selectedGenres.contains(name);

                        return GestureDetector(
                          onTap: () => _toggleGenre(name),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: colors,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? primaryColor.withValues(alpha: 0.4)
                                      : Colors.black.withValues(alpha: 0.2),
                                  blurRadius: isSelected ? 12 : 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -10,
                                  bottom: -10,
                                  child: Icon(
                                    icon,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(icon, color: Colors.white, size: 24),
                                          if (isSelected)
                                            Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.black,
                                                size: 14,
                                              ),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: primaryColor.withValues(alpha: 0.5),
                      ),
                      onPressed: _completeOnboarding,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedGenres.isEmpty ? "Skip & Start Listening" : "Get Started",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
