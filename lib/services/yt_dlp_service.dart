import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';

/// YtDlpService — Secure local subprocess backend using yt-dlp.
///
/// Security notes:
/// - All subprocess calls use argument lists, NEVER shell strings (prevents shell injection).
/// - Video IDs are validated against a strict regex before use.
/// - The yt-dlp binary is downloaded from the official GitHub releases page over HTTPS.
/// - No third-party proxy servers are used.
/// - No hardcoded API keys.
class YtDlpService {
  static final YtDlpService instance = YtDlpService._init();
  YtDlpService._init();

  String? _ytDlpPath;
  bool _isInitialized = false;
  bool _isAvailable = false;

  // Security: strict video ID validation — only alphanumeric + dash + underscore, 11 chars
  static final RegExp _videoIdRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');

  // Official yt-dlp Windows binary URL (verified GitHub releases)
  static const String _ytDlpWindowsBinaryUrl =
      'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe';

  bool get isAvailable => _isAvailable;
  String? get ytDlpPath => _ytDlpPath;

  /// Initialize: locate or auto-download yt-dlp binary.
  Future<bool> initialize() async {
    if (_isInitialized) return _isAvailable;
    _isInitialized = true;

    // 1. Check if yt-dlp is already on PATH
    final pathResult = await _tryRunYtDlp(['yt-dlp', '--version']);
    if (pathResult != null) {
      _ytDlpPath = 'yt-dlp';
      _isAvailable = true;
      debugPrint('[NEO] yt-dlp found on PATH: ${pathResult.trim()}');
      return true;
    }

    // 2. Check in app data folder
    final appDir = await getApplicationSupportDirectory();
    final binaryPath = '${appDir.path}\\yt-dlp.exe';
    final binaryFile = File(binaryPath);

    if (await binaryFile.exists()) {
      final localResult = await _tryRunYtDlp([binaryPath, '--version']);
      if (localResult != null) {
        _ytDlpPath = binaryPath;
        _isAvailable = true;
        debugPrint('[NEO] yt-dlp found at app data: $binaryPath');
        return true;
      }
    }

    // 3. Auto-download yt-dlp.exe
    debugPrint('[NEO] yt-dlp not found, downloading...');
    final downloaded = await _downloadYtDlpBinary(binaryPath);
    if (downloaded) {
      final localResult = await _tryRunYtDlp([binaryPath, '--version']);
      if (localResult != null) {
        _ytDlpPath = binaryPath;
        _isAvailable = true;
        debugPrint('[NEO] yt-dlp downloaded and ready');
        return true;
      }
    }

    _isAvailable = false;
    debugPrint('[NEO] yt-dlp unavailable');
    return false;
  }

  /// Download the official yt-dlp.exe binary from GitHub releases.
  Future<bool> _downloadYtDlpBinary(String savePath) async {
    try {
      final response = await http
          .get(Uri.parse(_ytDlpWindowsBinaryUrl))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return true;
      }
    } catch (e) {
      debugPrint('[NEO] Failed to download yt-dlp: $e');
    }
    return false;
  }

  /// Try running yt-dlp with given args. Returns stdout string or null on failure.
  /// SECURITY: Uses argument list (not shell string) to prevent injection.
  Future<String?> _tryRunYtDlp(List<String> args) async {
    try {
      final result = await Process.run(
        args[0],
        args.sublist(1),
        runInShell: false, // SECURITY: never run in shell
      ).timeout(const Duration(seconds: 10));

      if (result.exitCode == 0) {
        return result.stdout.toString();
      }
    } catch (_) {}
    return null;
  }

  HttpServer? _proxyServer;
  int get proxyPort => _proxyServer?.port ?? 8080;

  /// Run yt-dlp with given args, return stdout or null.
  /// SECURITY: Uses argument list, runInShell: false.
  Future<String?> _runYtDlp(List<String> args, {Duration timeout = const Duration(seconds: 30)}) async {
    final binary = _ytDlpPath;
    if (binary == null) return null;

    Process? process;
    try {
      process = await Process.start(
        binary,
        args,
        runInShell: false, // SECURITY: never run in shell
      );

      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      // Collect stdout and stderr
      process.stdout.transform(utf8.decoder).listen((data) => stdoutBuffer.write(data));
      process.stderr.transform(utf8.decoder).listen((data) => stderrBuffer.write(data));

      final exitCode = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          process?.kill(ProcessSignal.sigterm);
          process?.kill(ProcessSignal.sigkill);
          throw TimeoutException('yt-dlp process timed out');
        },
      );

      if (exitCode == 0) {
        return stdoutBuffer.toString().trim();
      } else {
        debugPrint('[NEO] yt-dlp error (exit $exitCode): $stderrBuffer');
      }
    } catch (e) {
      debugPrint('[NEO] yt-dlp run error: $e');
      process?.kill(ProcessSignal.sigkill);
    }
    return null;
  }

  /// Start the local proxy server to seamlessly stream YouTube URLs.
  Future<void> startProxyServer() async {
    if (_proxyServer != null) return;
    try {
      _proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      debugPrint('[NEO] Proxy server started on port ${_proxyServer!.port}');
      _proxyServer!.listen((HttpRequest request) async {
        if (request.uri.path == '/stream') {
          final id = request.uri.queryParameters['id'];
          if (id != null) {
            final url = await getStreamUrl(id);
            if (url != null) {
              try {
                final client = HttpClient();
                final proxyRequest = await client.getUrl(Uri.parse(url));

                // Forward Range headers for seeking support
                if (request.headers.value('range') != null) {
                  proxyRequest.headers.set('range', request.headers.value('range')!);
                }

                final proxyResponse = await proxyRequest.close();
                request.response.statusCode = proxyResponse.statusCode;

                // Forward essential headers
                proxyResponse.headers.forEach((name, values) {
                  for (final value in values) {
                    request.response.headers.add(name, value);
                  }
                });

                await proxyResponse.pipe(request.response);
              } catch (e) {
                debugPrint('[NEO] Proxy error: $e');
                request.response.statusCode = HttpStatus.internalServerError;
                await request.response.close();
              }
              return;
            }
          }
        }
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });
    } catch (e) {
      debugPrint('[NEO] Failed to start proxy server: $e');
    }
  }

  /// Search YouTube for songs matching [query].
  /// Returns up to [maxResults] Song objects.
  /// Uses yt-dlp `ytsearch` prefix — no API key required.
  Future<List<Song>> searchSongs(String query, {int maxResults = 10}) async {
    if (!_isAvailable) return [];
    if (query.trim().isEmpty) return [];

    // SECURITY: query is passed as a list argument, not interpolated into a shell string
    final output = await _runYtDlp(
      [
        '--no-download',
        '--flat-playlist',
        '--dump-json',
        '--no-playlist',
        '--match-filter', '!is_live',
        'ytsearch$maxResults:${query.trim()}',
      ],
      timeout: const Duration(seconds: 25),
    );

    if (output == null || output.isEmpty) return [];

    final List<Song> results = [];
    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        final song = _parseSongFromJson(json);
        if (song != null) results.add(song);
      } catch (_) {
        continue;
      }
    }
    return results;
  }

  /// Parse a Song from yt-dlp JSON output.
  Song? _parseSongFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    if (id == null || id.isEmpty) return null;

    final title = (json['title'] as String?) ?? 'Unknown Title';
    final uploader = (json['uploader'] as String?) ??
        (json['channel'] as String?) ??
        'Unknown Artist';
    final durationSec = (json['duration'] as num?)?.toInt() ?? 240;
    final thumbnail = (json['thumbnail'] as String?) ??
        'https://img.youtube.com/vi/$id/mqdefault.jpg';

    return Song(
      id: id,
      title: title,
      artist: uploader,
      album: 'YouTube',
      filePath: 'youtube://$id',
      durationMs: durationSec * 1000,
      genre: 'YouTube',
      sourceType: 'stream',
      thumbnailUrl: thumbnail,
    );
  }

  final Map<String, _CachedUrl> _urlCache = {};
  final Map<String, Future<String?>> _inFlightRequests = {};

  /// Get a direct audio stream URL for [videoId].
  /// SECURITY: videoId is validated with strict regex before use.
  /// Returns null if invalid or unavailable.
  Future<String?> getStreamUrl(String videoId) async {
    if (!_isAvailable) return null;

    // SECURITY: Validate videoId strictly before passing to subprocess
    if (!_videoIdRegex.hasMatch(videoId)) {
      debugPrint('[NEO] Invalid videoId rejected: $videoId');
      return null;
    }

    final cached = _urlCache[videoId];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.url;
    }

    if (_inFlightRequests.containsKey(videoId)) {
      return _inFlightRequests[videoId];
    }

    final future = _fetchStreamUrl(videoId);
    _inFlightRequests[videoId] = future;
    
    try {
      final url = await future;
      if (url != null) {
        // Cache URL for 2 hours
        _urlCache[videoId] = _CachedUrl(url, DateTime.now().add(const Duration(hours: 2)));
      }
      return url;
    } finally {
      _inFlightRequests.remove(videoId);
    }
  }

  Future<String?> _fetchStreamUrl(String videoId) async {

    final url = 'https://www.youtube.com/watch?v=$videoId';

    // SECURITY: URL passed as argument list item, not shell-interpolated
    final output = await _runYtDlp(
      [
        '-f', 'bestaudio[ext=m4a]/bestaudio[ext=webm]/bestaudio',
        '--get-url',
        '--no-playlist',
        url,
      ],
      timeout: const Duration(seconds: 20),
    );

    if (output == null || output.isEmpty) return null;

    // SECURITY: Validate the returned URL starts with https://
    final streamUrl = output.split('\n').first.trim();
    if (!streamUrl.startsWith('https://')) {
      debugPrint('[NEO] Rejected non-HTTPS stream URL');
      return null;
    }

    return streamUrl;
  }

  /// Download audio for [videoId] as mp3 to [outputDir].
  /// SECURITY: videoId validated, output path validated, argument list used.
  /// Returns the output file path, or null on failure.
  Future<String?> downloadAudio(String videoId, String outputDir) async {
    if (!_isAvailable) return null;

    // SECURITY: Validate videoId
    if (!_videoIdRegex.hasMatch(videoId)) {
      debugPrint('[NEO] Invalid videoId rejected for download: $videoId');
      return null;
    }

    // SECURITY: Validate outputDir is an actual directory
    final dir = Directory(outputDir);
    if (!await dir.exists()) return null;

    final url = 'https://www.youtube.com/watch?v=$videoId';
    final outputTemplate = '$outputDir\\%(title)s.%(ext)s';

    final output = await _runYtDlp(
      [
        '-x',
        '--audio-format', 'mp3',
        '--audio-quality', '0',
        '-o', outputTemplate,
        '--no-playlist',
        '--print', 'after_move:filepath',
        url,
      ],
      timeout: const Duration(minutes: 5),
    );

    if (output != null && output.isNotEmpty) {
      final filePath = output.split('\n').last.trim();
      if (File(filePath).existsSync()) return filePath;
    }
    return null;
  }

  /// Get user's Downloads folder path.
  static Future<String> getDownloadsPath() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? 'C:\\Users\\Public';
      return '$userProfile\\Downloads';
    }
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/Downloads';
  }
}

class _CachedUrl {
  final String url;
  final DateTime expiresAt;
  _CachedUrl(this.url, this.expiresAt);
}
