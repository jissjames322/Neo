import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

class ShieldScreen extends ConsumerStatefulWidget {
  const ShieldScreen({super.key});

  @override
  ConsumerState<ShieldScreen> createState() => _ShieldScreenState();
}

class _ShieldScreenState extends ConsumerState<ShieldScreen> with SingleTickerProviderStateMixin {
  final SettingsService _settings = SettingsService.instance;
  late AnimationController _pulseController;

  bool _isShieldEnabled = true;
  int _blockedCount = 0;
  double _dataSavedMb = 0.0;

  final List<Map<String, String>> _blockedLogs = [
    {"time": "Just now", "type": "Ad Server", "url": "doubleclick.net/gampad", "status": "BLOCKED"},
    {"time": "Just now", "type": "Telemetry", "url": "youtube.com/api/stats/ads", "status": "BLOCKED"},
    {"time": "1 min ago", "type": "Tracker", "url": "google-analytics.com/g/collect", "status": "BLOCKED"},
    {"time": "2 mins ago", "type": "QoS Monitor", "url": "youtube.com/api/stats/qoe", "status": "BLOCKED"},
    {"time": "5 mins ago", "type": "Ad Asset", "url": "ytimg.com/ad-resources", "status": "BLOCKED"},
    {"time": "10 mins ago", "type": "Telemetry", "url": "youtube.com/api/stats/watchtime", "status": "BLOCKED"},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadStats();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final enabled = await _settings.isShieldEnabled();
    final count = await _settings.getShieldBlockedCount();
    final mb = await _settings.getShieldDataSavedMb();

    setState(() {
      _isShieldEnabled = enabled;
      _blockedCount = count;
      _dataSavedMb = mb;
    });
  }

  Future<void> _toggleShield(bool val) async {
    await _settings.setShieldEnabled(val);
    setState(() {
      _isShieldEnabled = val;
    });
  }

  Future<void> _resetStats() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Statistics?"),
        content: const Text("This will reset all blocked trackers and data saved counters to zero."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reset"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final p = await _settings.prefs;
      await p.setInt('shield_blocked_count', 0);
      await p.setDouble('shield_data_saved_mb', 0.0);
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "NEO SHIELD",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Privacy Shield & Ad Blocking System",
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: Colors.grey.shade400),
                    onPressed: _loadStats,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Main Status Banner
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isShieldEnabled
                            ? [accentColor.withOpacity(0.15), cardColor]
                            : [Colors.redAccent.withOpacity(0.1), cardColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isShieldEnabled
                            ? accentColor.withOpacity(0.2 + 0.15 * _pulseController.value)
                            : Colors.redAccent.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isShieldEnabled
                              ? accentColor.withOpacity(0.05 + 0.05 * _pulseController.value)
                              : Colors.redAccent.withOpacity(0.05),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _isShieldEnabled
                                ? accentColor.withOpacity(0.1)
                                : Colors.redAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isShieldEnabled ? Icons.security_rounded : Icons.gpp_maybe_rounded,
                            color: _isShieldEnabled ? accentColor : Colors.redAccent,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isShieldEnabled ? "Protection Active" : "Shield Suspended",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isShieldEnabled
                                    ? "YouTube ad requests, analytics scripts, and doubleclick trackers are being blocked successfully."
                                    : "You are currently exposed to advertisements, QoS trackers, and user monitoring scripts.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isShieldEnabled,
                          activeColor: accentColor,
                          onChanged: _toggleShield,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: "Blocked Requests",
                      value: _blockedCount.toString(),
                      subtitle: "Ad servers & tracking endpoints",
                      icon: Icons.block_flipped,
                      color: accentColor,
                      cardColor: cardColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: "Data Saved",
                      value: "${_dataSavedMb.toStringAsFixed(1)} MB",
                      subtitle: "Avoided loading marketing assets",
                      icon: Icons.data_usage_rounded,
                      color: Colors.tealAccent,
                      cardColor: cardColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Privacy Rating & Shield Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: _isShieldEnabled ? 1.0 : 0.2,
                            strokeWidth: 8,
                            color: _isShieldEnabled ? accentColor : Colors.orangeAccent,
                            backgroundColor: Colors.grey.shade800,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          _isShieldEnabled ? "A+" : "D",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: _isShieldEnabled ? accentColor : Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Privacy Shield Rating",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isShieldEnabled
                                ? "Your privacy grade is exceptional. No logins required, and third-party trackers are blocked."
                                : "Warning: Telemetry servers can now analyze your listening habits and download patterns.",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade400, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Blocked logs / Diagnostic Console
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "NEO SHIELD DIAGNOSTICS LOG",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.grey,
                    ),
                  ),
                  TextButton(
                    onPressed: _resetStats,
                    child: const Text("Reset Stats", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _blockedLogs.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.03),
                  ),
                  itemBuilder: (context, index) {
                    final log = _blockedLogs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: _isShieldEnabled ? accentColor : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log["url"]!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      log["type"]!,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "•",
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      log["time"]!,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isShieldEnabled
                                  ? accentColor.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _isShieldEnabled ? "BLOCKED" : "ALLOWED",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _isShieldEnabled ? accentColor : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }
}
