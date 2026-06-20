import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/shield_screen.dart';
import '../widgets/sidebar.dart';
import '../widgets/bottom_player_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class MainShellLayout extends StatelessWidget {
  final Widget child;

  const MainShellLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                if (isDesktop) const Sidebar(),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const BottomPlayerBar(),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: _getSelectedIndex(context),
              onTap: (index) => _onItemTapped(index, context),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: 'Library'),
                BottomNavigationBarItem(icon: Icon(Icons.shield_rounded), label: 'Shield'),
                BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: 'Settings'),
              ],
            )
          : null,
    );
  }

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location == '/' || location == '/home') return 0;
    if (location.startsWith('/library')) return 1;
    if (location.startsWith('/shield')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/library');
        break;
      case 2:
        context.go('/shield');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }
}

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainShellLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          redirect: (_, __) => '/home',
        ),
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/library',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LibraryScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
        GoRoute(
          path: '/shield',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ShieldScreen(),
          ),
        ),
      ],
    ),
  ],
);
