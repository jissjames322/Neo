import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'navigation/router.dart';
import 'providers/theme_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized(
    windows: true,
  );
  runApp(
    const ProviderScope(
      child: PulseMusic(),
    ),
  );
}

class PulseMusic extends ConsumerWidget {
  const PulseMusic({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Pulse Music',
      theme: themeState.themeData,
      routerConfig: router,
    );
  }
}
