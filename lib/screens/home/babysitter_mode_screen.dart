import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/baby_data_repository.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/premium_ui_components.dart';
import 'dart:convert';

class BabysitterModeScreen extends StatefulWidget {
  const BabysitterModeScreen({super.key});

  @override
  State<BabysitterModeScreen> createState() => _BabysitterModeScreenState();
}

class _BabysitterModeScreenState extends State<BabysitterModeScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _lastFeed;
  Map<String, dynamic>? _lastSleep;
  Map<String, String> _emergencyInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    final service = context.read<BabyDataRepository>();
    final ls = context.read<LocalStorageService>();

    final results = await Future.wait([
      service.getProfile(),
      service.getLastFeed(),
      service.getSleepLogs(),
    ]);

    final raw = ls.getString('emergency_card');
    if (raw != null) _emergencyInfo = Map<String, String>.from(jsonDecode(raw));

    final sleeps = results[2] as List<Map<String, dynamic>>;

    if (mounted) {
      setState(() {
        _profile = results[0] as Map<String, dynamic>?;
        _lastFeed = results[1] as Map<String, dynamic>?;
        _lastSleep = sleeps.isNotEmpty ? sleeps.first : null;
        _isLoading = false;
      });
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'None';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d, h:mm a').format(date);
    } catch (_) { return 'Unknown'; }
  }


  @override
  Widget build(BuildContext context) {
    final babyName = _profile?['baby_name'] ?? 'Baby';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Header
                    Column(
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.tealAccent.shade400, Colors.tealAccent.shade700],
                            ),
                          ),
                          child: Center(
                            child: Text(babyName.isNotEmpty ? babyName[0].toUpperCase() : 'B',
                                style: PremiumTypography(context).bodyBold.copyWith(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('BABYSITTER MODE', style: PremiumTypography(context).bodyBold.copyWith(
                          fontSize: 12, fontWeight: FontWeight.w800, color: Colors.tealAccent, letterSpacing: 2,
                        )),
                        Text(babyName, style: PremiumTypography(context).bodyBold.copyWith(
                          fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
                        )),
                        const SizedBox(height: 8),
                        if (_profile?['baby_dob'] != null)
                          Text('DOB: ${_profile!['baby_dob']}', style: PremiumTypography(context).bodyBold.copyWith(
                            fontSize: 14, color: Colors.white60,
                          )),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Essential Info Cards
                    _babysitterCard(
                      '🍼', 'Last Feed',
                      _lastFeed != null
                          ? '${_lastFeed!['type']?.toString().toUpperCase() ?? 'FEED'} • ${_formatTime(_lastFeed!['created_at'])}'
                          : 'No feeds logged',
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),

                    _babysitterCard(
                      '😴', 'Last Sleep',
                      _lastSleep != null
                          ? 'Started ${_formatTime(_lastSleep!['start_time'])}'
                          : 'No sleep logged',
                      Colors.blueAccent,
                    ),
                    const SizedBox(height: 12),

                    _babysitterCard(
                      '⚠️', 'Allergies',
                      _emergencyInfo['allergies']?.isNotEmpty == true
                          ? _emergencyInfo['allergies']!
                          : 'None listed',
                      Colors.redAccent,
                    ),
                    const SizedBox(height: 12),

                    _babysitterCard(
                      '📞', 'Emergency Contact',
                      _emergencyInfo['emergency_contact']?.isNotEmpty == true
                          ? '${_emergencyInfo['emergency_contact']} (${_emergencyInfo['emergency_phone'] ?? ''})'
                          : 'Not set',
                      Colors.greenAccent,
                    ),
                    const SizedBox(height: 12),

                    _babysitterCard(
                      '👨‍⚕️', 'Pediatrician',
                      _emergencyInfo['pediatrician']?.isNotEmpty == true
                          ? '${_emergencyInfo['pediatrician']} (${_emergencyInfo['pediatrician_phone'] ?? ''})'
                          : 'Not set',
                      Colors.cyanAccent,
                    ),
                    const SizedBox(height: 32),

                    // Exit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _exitBabysitterMode(),
                        icon: const Icon(Icons.exit_to_app_rounded),
                        label: Text('Exit Babysitter Mode', style: PremiumTypography(context).bodyBold.copyWith(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _babysitterCard(String emoji, String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: PremiumTypography(context).bodyBold.copyWith(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white60,
              )),
              const SizedBox(height: 2),
              Text(value, style: PremiumTypography(context).bodyBold.copyWith(
                fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white,
              )),
            ],
          )),
        ],
      ),
    );
  }

  void _exitBabysitterMode() {
    // Simple PIN dialog to prevent baby from accidentally exiting
    final pinC = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter PIN to Exit'),
        content: TextField(
          controller: pinC,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(hintText: 'Enter 1234 to exit'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (pinC.text == '1234') {
                Navigator.pop(ctx);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wrong PIN! Default: 1234')),
                );
              }
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
