import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;
    final currentPath = GoRouterState.of(context).uri.toString();

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withBlue(20), // Darker sidebar
        border: Border(
          right: BorderSide(
            color: Colors.grey.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _SidebarWaveLogo(),
                SizedBox(width: 12),
                Text(
                  "PULSE",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          _SidebarItem(
            icon: Icons.home_rounded,
            label: "Home",
            isSelected: currentPath == '/' || currentPath == '/home',
            onTap: () => context.go('/home'),
            activeColor: activeColor,
          ),
          _SidebarItem(
            icon: Icons.library_music_rounded,
            label: "Your Library",
            isSelected: currentPath.startsWith('/library'),
            onTap: () => context.go('/library'),
            activeColor: activeColor,
          ),
          _SidebarItem(
            icon: Icons.shield_rounded,
            label: "Neo Shield",
            isSelected: currentPath.startsWith('/shield'),
            onTap: () => context.go('/shield'),
            activeColor: activeColor,
          ),
          _SidebarItem(
            icon: Icons.settings_rounded,
            label: "Settings",
            isSelected: currentPath.startsWith('/settings'),
            onTap: () => context.go('/settings'),
            activeColor: activeColor,
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: InkWell(
              onTap: () => context.go('/shield'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: activeColor.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    Text(
                      "Privacy Secured",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : Colors.grey.shade400,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarWaveLogo extends StatefulWidget {
  const _SidebarWaveLogo();

  @override
  State<_SidebarWaveLogo> createState() => _SidebarWaveLogoState();
}

class _SidebarWaveLogoState extends State<_SidebarWaveLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 24,
          height: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              double value = 0.3;
              switch (index) {
                case 0:
                  value = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi));
                  break;
                case 1:
                  value = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi + math.pi / 2));
                  break;
                case 2:
                  value = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(_controller.value * 2 * math.pi + math.pi));
                  break;
              }
              return Container(
                width: 3,
                height: 18 * value,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
