import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/settings_service.dart';
import '../services/yt_dlp_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _waveController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  String _statusText = 'Initializing...';
  bool _isReady = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: false);

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    // Check yt-dlp status
    if (mounted) setState(() => _statusText = 'Checking yt-dlp...');

    final ytDlpReady = YtDlpService.instance.isAvailable;
    if (!ytDlpReady) {
      if (mounted) setState(() => _statusText = 'Downloading yt-dlp engine...');
      await YtDlpService.instance.initialize();
    }

    if (mounted) {
      setState(() {
        _statusText = YtDlpService.instance.isAvailable
            ? 'yt-dlp ready ✓'
            : 'Limited mode (yt-dlp unavailable)';
        _isReady = true;
      });
    }

    await Future.delayed(const Duration(milliseconds: 900));
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
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF080A10),
              accentColor.withValues(alpha: 0.12),
              const Color(0xFF080A10),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background grid pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _GridPainter(accentColor.withValues(alpha: 0.04)),
              ),
            ),

            // Radial glow behind logo
            Center(
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (ctx, child) => Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.15 * _glowAnimation.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // NEO Logo circle
                      AnimatedBuilder(
                        animation: _glowAnimation,
                        builder: (ctx, child) => Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF111320),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.6 * _glowAnimation.value),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35 * _glowAnimation.value),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.graphic_eq_rounded,
                              size: 60,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // NEO text
                      Text(
                        'NEO',
                        style: GoogleFonts.outfit(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 12.0,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: accentColor.withValues(alpha: 0.6),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'YOUTUBE MUSIC PLAYER',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 4.0,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Waveform animation
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (ctx, child) => SizedBox(
                          width: 200,
                          height: 36,
                          child: CustomPaint(
                            painter: _WavePainter(
                              animationValue: _waveController.value,
                              waveColor: accentColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Status text
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _statusText,
                          key: ValueKey(_statusText),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: _isReady
                                ? accentColor.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.35),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color waveColor;

  _WavePainter({required this.animationValue, required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const int barCount = 22;
    final double spacing = size.width / (barCount - 1);
    final double middleY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final double x = i * spacing;
      final double progress =
          (i / barCount) * 2 * math.pi + animationValue * 2 * math.pi;
      final double edge = math.sin((i / barCount) * math.pi);
      final double waveHeight = (middleY * 0.85) * math.sin(progress) * edge;
      final opacity = 0.4 + 0.6 * edge;
      canvas.drawLine(
        Offset(x, middleY - waveHeight),
        Offset(x, middleY + waveHeight),
        paint..color = waveColor.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}

class _GridPainter extends CustomPainter {
  final Color gridColor;
  _GridPainter(this.gridColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const double spacing = 40;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
