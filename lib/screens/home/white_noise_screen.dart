import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/notification_service.dart';
import '../../widgets/premium_ui_components.dart';

class WhiteNoiseScreen extends StatefulWidget {
  const WhiteNoiseScreen({super.key});

  @override
  State<WhiteNoiseScreen> createState() => _WhiteNoiseScreenState();
}

class _WhiteNoiseScreenState extends State<WhiteNoiseScreen> with SingleTickerProviderStateMixin {

  late AnimationController _pulseController;
  String? _activeSound;
  int _timerMinutes = 30;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  double _volume = 0.7;
  NotificationService? _notificationService;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Local ambient audio files
  static const Map<String, String> soundUrls = {
    'rain': 'audio/rain.mp3',
    'ocean': 'audio/ocean.mp3',
    'heartbeat': 'audio/heartbeat.mp3',
    'shush': 'audio/shush.mp3',
    'fan': 'audio/fan.mp3',
    'nature': 'audio/nature.mp3',
    'lullaby': 'audio/lullaby.mp3',
    'womb': 'audio/womb.mp3',
  };

  static const sounds = [
    {'id': 'rain', 'name': 'Rain', 'emoji': '🌧️', 'desc': 'Gentle rainfall'},
    {'id': 'ocean', 'name': 'Ocean', 'emoji': '🌊', 'desc': 'Calm waves'},
    {'id': 'heartbeat', 'name': 'Heartbeat', 'emoji': '💓', 'desc': 'Steady rhythm'},
    {'id': 'shush', 'name': 'Shush', 'emoji': '🤫', 'desc': 'Soothing shush'},
    {'id': 'fan', 'name': 'Fan', 'emoji': '🌀', 'desc': 'White noise fan'},
    {'id': 'nature', 'name': 'Nature', 'emoji': '🌿', 'desc': 'Forest ambiance'},
    {'id': 'lullaby', 'name': 'Lullaby', 'emoji': '🎵', 'desc': 'Soft melody'},
    {'id': 'womb', 'name': 'Womb', 'emoji': '🤰', 'desc': 'Womb sounds'},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.setVolume(_volume);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notificationService = context.read<NotificationService>();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _audioPlayer.stop();
    _notificationService?.cancelReminder(99999);
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleSound(String id) async {
    if (_activeSound == id) {
      // Stop current sound
      await _audioPlayer.stop();
      if (!mounted) return;
      await context.read<NotificationService>().cancelReminder(99999);
      _countdownTimer?.cancel();
      setState(() {
        _activeSound = null;
        _remainingSeconds = 0;
      });
    } else {
      // Play new sound
      setState(() {
        _activeSound = id;
        _remainingSeconds = _timerMinutes * 60;
      });

      try {
        final url = soundUrls[id];
        if (url != null) {
          await _audioPlayer.stop();
          await _audioPlayer.setVolume(_volume);
          await _audioPlayer.play(AssetSource(url));
          if (mounted) {
            final soundData = sounds.firstWhere((s) => s['id'] == id, orElse: () => {'name': 'White Noise'});
            String soundName = soundData['name'] as String;
            await context.read<NotificationService>().scheduleReminder(99999, DateTime.now().add(Duration(minutes: _timerMinutes)), '🔊 $soundName playing', 'White noise is active');
          }
        }
      } catch (e) {
        debugPrint('Audio playback error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not play sound: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }

      // Start countdown timer
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _activeSound = null;
            timer.cancel();
            _audioPlayer.stop();
            if (mounted) {
              context.read<NotificationService>().cancelReminder(99999);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timer ended. Sound stopped. 😴')),
              );
            }
          }
        });
      });
    }
  }

  String _formatCountdown() {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }


  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    return PremiumScaffold(
      backgroundColor: _activeSound != null ? const Color(0xFF0F172A) : null, // Premium dark blue when playing
      appBar: AppBar(
        title: const Text('White Noise'),
        backgroundColor: Colors.transparent,
        foregroundColor: _activeSound != null ? Colors.white : null,
        elevation: 0,
        centerTitle: true,
      ),
      body: Material(
          color: Colors.transparent,
          child: Column(
            children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Now Playing Card
                  if (_activeSound != null) ...[
                    _buildNowPlaying(colors, typo),
                    const SizedBox(height: 24),
                  ],

                  // Timer Selector
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Timer', style: typo.title),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [15, 30, 60, 120].map((min) {
                              final isSelected = _timerMinutes == min;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () => setState(() => _timerMinutes = min),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? colors.sereneBlue : colors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      min < 60 ? '${min}m' : '${min ~/ 60}h',
                                      style: PremiumTypography(context).bodyBold.copyWith(
                                        fontSize: 14, fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sound Grid
                  Text('Choose a Sound', style: typo.h2),
                  const SizedBox(height: 12),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: sounds.length,
                    itemBuilder: (ctx, i) => _buildSoundCard(sounds[i], colors, typo),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildNowPlaying(PremiumColors colors, PremiumTypography typo) {
    final sound = sounds.firstWhere((s) => s['id'] == _activeSound, orElse: () => sounds[0]);
    return PremiumCard(
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Transform.scale(
              scale: 1.0 + (_pulseController.value * 0.08),
              child: child,
            ),
            child: Text(sound['emoji']!, style: const TextStyle(fontSize: 48)),
          ),
          const SizedBox(height: 12),
          Text('Now Playing', style: typo.caption),
          Text(sound['name']!, style: typo.h2),
          const SizedBox(height: 8),
          Text(_formatCountdown(), style: PremiumTypography(context).bodyBold.copyWith(
            fontSize: 32, fontWeight: FontWeight.w800, color: colors.sereneBlue,
          )),
          const SizedBox(height: 16),
          // Volume Slider
          Row(
            children: [
              Icon(Icons.volume_down_rounded, color: colors.textMuted, size: 20),
              Expanded(
                child: Slider(
                  value: _volume,
                  onChanged: (v) {
                    setState(() => _volume = v);
                    _audioPlayer.setVolume(v);
                  },
                  activeColor: colors.sereneBlue,
                  inactiveColor: colors.surfaceMuted,
                ),
              ),
              Icon(Icons.volume_up_rounded, color: colors.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          PremiumActionButton(
            label: 'Stop',
            icon: Icons.stop_rounded,
            color: colors.warmPeach,
            onTap: () => _toggleSound(_activeSound!),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundCard(Map<String, String> sound, PremiumColors colors, PremiumTypography typo) {
    final isActive = _activeSound == sound['id'];
    return GestureDetector(
      onTap: () => _toggleSound(sound['id']!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? colors.sereneBlue.withValues(alpha: 0.15) : colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? colors.sereneBlue : colors.surfaceMuted,
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive ? [BoxShadow(color: colors.sereneBlue.withValues(alpha: 0.2), blurRadius: 12)] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(sound['emoji']!, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(sound['name']!, style: PremiumTypography(context).bodyBold.copyWith(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: isActive ? colors.sereneBlue : colors.textPrimary,
            )),
            Text(sound['desc']!, style: typo.caption),
          ],
        ),
      ),
    );
  }
}
