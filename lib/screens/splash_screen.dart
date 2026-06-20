import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/settings_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.repeat(reverse: true);
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Hold splash screen for 2.5 seconds
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final settings = SettingsService.instance;
    final isCompleted = await settings.isOnboardingCompleted();
    if (!mounted) return;

    if (isCompleted) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.1),
            radius: 1.2,
            colors: [
              accentColor.withValues(alpha: 0.15),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.75],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo + Glowing wave
              ScaleTransition(
                scale: _pulseAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.audiotrack_rounded,
                        size: 56,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // App Title
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      "PULSE MUSIC",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Privacy First • Local Music",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Glowing Waveform Drawing
              SizedBox(
                width: 180,
                height: 40,
                child: CustomPaint(
                  painter: _SplashWavePainter(
                    animationValue: _controller.value,
                    waveColor: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashWavePainter extends CustomPainter {
  final double animationValue;
  final Color waveColor;

  _SplashWavePainter({required this.animationValue, required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final int barCount = 18;
    final double spacing = size.width / (barCount - 1);
    final double middleY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final double x = i * spacing;
      // Generate a sinusoidal height offset based on index and time value
      final double progress = (i / barCount) * 2 * math.pi + animationValue * 2 * math.pi;
      final double scale = math.sin((i / barCount) * math.pi); // Taper at edges
      final double waveHeight = (middleY * 0.8) * math.sin(progress) * scale;
      
      canvas.drawLine(
        Offset(x, middleY - waveHeight),
        Offset(x, middleY + waveHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.waveColor != waveColor;
  }
}
