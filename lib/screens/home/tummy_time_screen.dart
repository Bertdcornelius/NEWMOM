import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart' hide TextDirection;
import '../../services/local_storage_service.dart';
import '../../widgets/premium_ui_components.dart';

class TummyTimeScreen extends StatefulWidget {
  const TummyTimeScreen({super.key});

  @override
  State<TummyTimeScreen> createState() => _TummyTimeScreenState();
}

class _TummyTimeScreenState extends State<TummyTimeScreen> {
  List<Map<String, dynamic>> _sessions = [];
  int _dailyGoalMin = 30;

  // Timer
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _uiTimer?.cancel();
    super.dispose();
  }

  void _loadData() {
    final ls = context.read<LocalStorageService>();
    final raw = ls.getString('tummy_time_sessions');
    if (raw != null) _sessions = List<Map<String, dynamic>>.from(jsonDecode(raw));
    _dailyGoalMin = int.tryParse(ls.getString('tummy_goal') ?? '30') ?? 30;
    if (mounted) setState(() {});
  }

  Future<void> _saveData() async {
    final ls = context.read<LocalStorageService>();
    await ls.saveString('tummy_time_sessions', jsonEncode(_sessions));
    await ls.saveString('tummy_goal', _dailyGoalMin.toString());
  }

  void _toggleTimer() {
    setState(() {
      if (_isTimerRunning) {
        _stopwatch.stop();
        _isTimerRunning = false;
        _uiTimer?.cancel();
        // Auto-save session
        final durSec = _stopwatch.elapsed.inSeconds;
        if (durSec > 0) {
          _sessions.insert(0, {
            'duration_sec': durSec,
            'date': DateFormat('MMM d, h:mm a').format(DateTime.now()),
            'timestamp': DateTime.now().toIso8601String(),
          });
          _saveData();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tummy time saved! 🎉')));
        }
        _stopwatch.reset();
      } else {
        _stopwatch.reset();
        _stopwatch.start();
        _isTimerRunning = true;
        _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
      }
    });
  }

  String _formatElapsed() {
    final e = _stopwatch.elapsed;
    final m = (e.inMinutes % 60).toString().padLeft(2, '0');
    final s = (e.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int get _todayTotalSec {
    final now = DateTime.now();
    return _sessions.where((s) {
      try {
        final d = DateTime.parse(s['timestamp']);
        return d.year == now.year && d.month == now.month && d.day == now.day;
      } catch (_) { return false; }
    }).fold<int>(0, (sum, s) => sum + (s['duration_sec'] as int? ?? 0));
  }

  double get _todayProgress {
    final totalMin = _todayTotalSec / 60.0;
    return (totalMin / _dailyGoalMin).clamp(0.0, 1.0);
  }

  // Weekly data for bar chart
  List<int> get _weeklyData {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _sessions.where((s) {
        try {
          final d = DateTime.parse(s['timestamp']);
          return d.year == day.year && d.month == day.month && d.day == day.day;
        } catch (_) { return false; }
      }).fold<int>(0, (sum, s) => sum + (s['duration_sec'] as int? ?? 0));
    });
  }


  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);
    final todayMin = _todayTotalSec / 60.0;

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Tummy Time', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress Ring + Timer
                  PremiumCard(
                    child: Column(
                      children: [
                        // Progress Ring
                        SizedBox(
                          width: 200, height: 200,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(200, 200),
                                painter: _ProgressRingPainter(
                                  progress: _todayProgress,
                                  color: colors.softAmber,
                                  bgColor: colors.surfaceMuted,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isTimerRunning)
                                    Text(_formatElapsed(), style: GoogleFonts.plusJakartaSans(
                                      fontSize: 36, fontWeight: FontWeight.w800, color: colors.softAmber,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ))
                                  else
                                    Text('${todayMin.toStringAsFixed(0)}m', style: GoogleFonts.plusJakartaSans(
                                      fontSize: 36, fontWeight: FontWeight.w800, color: colors.textPrimary,
                                    )),
                                  Text(_isTimerRunning ? 'In progress...' : 'of ${_dailyGoalMin}m goal', style: typo.caption),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Timer Button
                        PremiumActionButton(
                          label: _isTimerRunning ? 'Stop & Save' : 'Start Tummy Time',
                          icon: _isTimerRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          color: _isTimerRunning ? colors.warmPeach : colors.softAmber,
                          onTap: _toggleTimer,
                        ),
                        const SizedBox(height: 12),

                        // Goal Setter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Daily Goal: ', style: typo.body),
                            GestureDetector(
                              onTap: _showGoalDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colors.softAmber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('$_dailyGoalMin min', style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: colors.softAmber,
                                )),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Weekly Trend
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('This Week', style: typo.title),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 120,
                          child: CustomPaint(
                            size: const Size(double.infinity, 120),
                            painter: _WeeklyBarPainter(
                              data: _weeklyData,
                              barColor: colors.softAmber,
                              textColor: colors.textSecondary,
                                goalSec: _dailyGoalMin * 60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                  // Session History
                  Text('Sessions', style: typo.h2),
                  const SizedBox(height: 12),

                  if (_sessions.isEmpty)
                    PremiumCard(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('No sessions yet. Start tummy time!', style: typo.body)),
                    ))
                  else
                    ...List.generate(_sessions.length > 20 ? 20 : _sessions.length, (i) {
                      final s = _sessions[i];
                      final durSec = s['duration_sec'] as int? ?? 0;
                      final durStr = durSec >= 60 ? '${durSec ~/ 60}m ${durSec % 60}s' : '${durSec}s';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DataTile(
                          onTap: () => _deleteSession(i),
                          child: Row(
                            children: [
                              PremiumBubbleIcon(icon: Icons.timer_outlined, color: colors.softAmber, size: 20, padding: 10),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(durStr, style: typo.bodyBold),
                                  Text(s['date'] ?? '', style: typo.caption),
                                ],
                              )),
                              Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 20),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog() {
    int tempGoal = _dailyGoalMin;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Daily Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$tempGoal minutes', style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800)),
              Slider(
                value: tempGoal.toDouble(),
                min: 5, max: 120, divisions: 23,
                activeColor: PremiumColors(context).softAmber,
                onChanged: (v) => setD(() => tempGoal = v.toInt()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                setState(() => _dailyGoalMin = tempGoal);
                _saveData();
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSession(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _sessions.removeAt(index);
              _saveData();
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _ProgressRingPainter({required this.progress, required this.color, required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final stroke = 10.0;

    // Background ring
    canvas.drawCircle(center, radius, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = bgColor);

    // Progress arc
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) => old.progress != progress;
}

class _WeeklyBarPainter extends CustomPainter {
  final List<int> data;
  final Color barColor;
  final Color textColor;
  final int goalSec;

  _WeeklyBarPainter({required this.data, required this.barColor, required this.textColor, required this.goalSec});

  @override
  void paint(Canvas canvas, Size size) {
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final startDay = now.subtract(const Duration(days: 6));

    final barWidth = size.width / 9;
    final maxVal = data.isEmpty ? goalSec.toDouble() : max(data.reduce(max).toDouble(), goalSec.toDouble());
    final chartHeight = size.height - 24;

    for (int i = 0; i < 7; i++) {
      final x = barWidth * 0.5 + i * (size.width / 7);
      final val = i < data.length ? data[i].toDouble() : 0;
      final barHeight = maxVal > 0 ? (val / maxVal) * chartHeight : 0;

      // Bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 3, chartHeight - barHeight, barWidth * 2 / 3, barHeight.toDouble()),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = val >= goalSec ? barColor : barColor.withValues(alpha: 0.4));

      // Label
      final day = startDay.add(Duration(days: i));
      final label = labels[day.weekday - 1];
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: textColor, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarPainter old) => true;
}
