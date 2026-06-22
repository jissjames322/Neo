import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'navigation/router.dart';
import 'providers/theme_provider.dart';
import 'services/yt_dlp_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  JustAudioMediaKit.ensureInitialized(
    windows: true,
  );

  // Initialize yt-dlp backend (auto-downloads binary if needed)
  await YtDlpService.instance.initialize();
  await YtDlpService.instance.startProxyServer();

  runApp(
    const ProviderScope(
      child: NeoApp(),
    ),
  );
}

class NeoApp extends ConsumerWidget {
  const NeoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'NEO',
      theme: themeState.themeData,
      routerConfig: router,
    );
  }
}
