import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:math';
import '../../services/baby_data_repository.dart';
import '../../widgets/premium_ui_components.dart';

class SleepAnalyticsScreen extends StatefulWidget {
  const SleepAnalyticsScreen({super.key});

  @override
  State<SleepAnalyticsScreen> createState() => _SleepAnalyticsScreenState();
}

class _SleepAnalyticsScreenState extends State<SleepAnalyticsScreen> {
  List<Map<String, dynamic>> _sleepLogs = [];
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
    final logs = await service.getSleepLogs();
    if (mounted) {
      setState(() {
        _sleepLogs = logs;
        _isLoading = false;
      });
    }
  }


  // Stats
  double get _avgSleepHours {
    final completed = _sleepLogs.where((l) => l['end_time'] != null).toList();
    if (completed.isEmpty) return 0;
    double totalHours = 0;
    for (final log in completed) {
      try {
        final start = DateTime.parse(log['start_time']).toLocal();
        final end = DateTime.parse(log['end_time']).toLocal();
        totalHours += end.difference(start).inMinutes / 60.0;
      } catch (_) {}
    }
    return totalHours / completed.length;
  }

  double get _totalSleepToday {
    final now = DateTime.now();
    double totalMin = 0;
    for (final log in _sleepLogs) {
      if (log['end_time'] == null) continue;
      try {
        final start = DateTime.parse(log['start_time']).toLocal();
        final end = DateTime.parse(log['end_time']).toLocal();
        if (start.year == now.year && start.month == now.month && start.day == now.day) {
          totalMin += end.difference(start).inMinutes;
        }
      } catch (_) {}
    }
    return totalMin / 60.0;
  }

  int get _totalSessions => _sleepLogs.length;

  // Day vs Night ratio
  Map<String, double> get _dayNightRatio {
    double dayMin = 0, nightMin = 0;
    for (final log in _sleepLogs) {
      if (log['end_time'] == null) continue;
      try {
        final start = DateTime.parse(log['start_time']).toLocal();
        final end = DateTime.parse(log['end_time']).toLocal();
        final dur = end.difference(start).inMinutes.toDouble();
        if (start.hour >= 7 && start.hour < 19) {
          dayMin += dur;
        } else {
          nightMin += dur;
        }
      } catch (_) {}
    }
    return {'day': dayMin, 'night': nightMin};
  }

  // Weekly sleep data (hours per day)
  List<double> get _weeklyData {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      double totalMin = 0;
      for (final log in _sleepLogs) {
        if (log['end_time'] == null) continue;
        try {
          final start = DateTime.parse(log['start_time']).toLocal();
          final end = DateTime.parse(log['end_time']).toLocal();
          if (start.year == day.year && start.month == day.month && start.day == day.day) {
            totalMin += end.difference(start).inMinutes;
          }
        } catch (_) {}
      }
      return totalMin / 60.0;
    });
  }

  String get _bestDay {
    final weekly = _weeklyData;
    if (weekly.every((v) => v == 0)) return 'N/A';
    final now = DateTime.now();
    final maxIdx = weekly.indexOf(weekly.reduce(max));
    final day = now.subtract(Duration(days: 6 - maxIdx));
    return '${DateFormat('EEEE').format(day)} (${weekly[maxIdx].toStringAsFixed(1)}h)';
  }

  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);
    final isDark = colors.isDark;
    final dnRatio = _dayNightRatio;

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Sleep Analytics', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.sereneBlue))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview
                        Row(
                          children: [
                            _statCard('Today', '${_totalSleepToday.toStringAsFixed(1)}h', colors.sereneBlue, colors),
                            const SizedBox(width: 10),
                            _statCard('Avg', '${_avgSleepHours.toStringAsFixed(1)}h', colors.gentlePurple, colors),
                            const SizedBox(width: 10),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Day vs Night Donut
                        PremiumCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Day vs Night Sleep', style: typo.title),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 140,
                                child: (dnRatio['day']! + dnRatio['night']!) > 0
                                    ? CustomPaint(
                                        size: const Size(double.infinity, 140),
                                        painter: _SleepDonutPainter(
                                          dayMin: dnRatio['day']!,
                                          nightMin: dnRatio['night']!,
                                          dayColor: colors.softAmber,
                                          nightColor: colors.sereneBlue,
                                          isDark: isDark,
                                        ),
                                      )
                                    : Center(child: Text('Not enough data', style: typo.body)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _legendDot(colors.softAmber, 'Day (${(dnRatio['day']! / 60).toStringAsFixed(1)}h)'),
                                  const SizedBox(width: 20),
                                  _legendDot(colors.sereneBlue, 'Night (${(dnRatio['night']! / 60).toStringAsFixed(1)}h)'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Weekly Bar Chart
                        PremiumCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Last 7 Days', style: typo.title),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 140,
                                child: CustomPaint(
                                  size: const Size(double.infinity, 140),
                                  painter: _SleepBarPainter(
                                    data: _weeklyData,
                                    barColor: colors.sereneBlue,
                                    textColor: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Best Day
                        PremiumCard(
                          child: Row(
                            children: [
                              PremiumBubbleIcon(icon: Icons.star_rounded, color: colors.softAmber, size: 20, padding: 12),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Best Sleep Day', style: typo.caption),
                                  Text(_bestDay, style: typo.bodyBold),
                                ],
                              )),
                            ],
                          ),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statCard(String label, String value, Color color, PremiumColors colors) {
    return Expanded(
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: PremiumTypography(context).caption),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: PremiumTypography(context).caption),
      ],
    );
  }
}

class _SleepDonutPainter extends CustomPainter {
  final double dayMin, nightMin;
  final Color dayColor, nightColor;
  final bool isDark;

  _SleepDonutPainter({required this.dayMin, required this.nightMin, required this.dayColor, required this.nightColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final total = dayMin + nightMin;
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    final stroke = 28.0;

    final dayAngle = (dayMin / total) * 2 * pi;
    final nightAngle = (nightMin / total) * 2 * pi;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, dayAngle - 0.04, false,
        Paint()..color = dayColor..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2 + dayAngle, nightAngle - 0.04, false,
        Paint()..color = nightColor..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round);

    // Center icon
    final tp = TextPainter(
      text: TextSpan(text: '😴', style: const TextStyle(fontSize: 28)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SleepBarPainter extends CustomPainter {
  final List<double> data;
  final Color barColor;
  final Color textColor;

  _SleepBarPainter({required this.data, required this.barColor, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final startDay = now.subtract(const Duration(days: 6));

    final barWidth = size.width / 9;
    final maxVal = data.isEmpty ? 1.0 : max(data.reduce(max), 1.0);
    final chartHeight = size.height - 24;

    for (int i = 0; i < 7; i++) {
      final x = barWidth * 0.5 + i * (size.width / 7);
      final val = i < data.length ? data[i] : 0.0;
      final barHeight = (val / maxVal) * chartHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 3, chartHeight - barHeight, barWidth * 2 / 3, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = barColor.withValues(alpha: i == 6 ? 1.0 : 0.5));

      if (val > 0) {
        final tp = TextPainter(
          text: TextSpan(text: '${val.toStringAsFixed(1)}h', style: TextStyle(color: barColor, fontSize: 9, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, chartHeight - barHeight - 14));
      }

      final day = startDay.add(Duration(days: i));
      final label = labels[day.weekday - 1];
      final lp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: textColor, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      lp.paint(canvas, Offset(x - lp.width / 2, chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
