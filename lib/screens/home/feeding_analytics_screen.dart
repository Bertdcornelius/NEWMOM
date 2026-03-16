import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../services/baby_data_repository.dart';
import '../../widgets/premium_ui_components.dart';

class FeedingAnalyticsScreen extends StatefulWidget {
  const FeedingAnalyticsScreen({super.key});

  @override
  State<FeedingAnalyticsScreen> createState() => _FeedingAnalyticsScreenState();
}

class _FeedingAnalyticsScreenState extends State<FeedingAnalyticsScreen> {
  List<Map<String, dynamic>> _feeds = [];
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
    final feeds = await service.getFeeds();
    if (mounted) {
      setState(() {
        _feeds = feeds;
        _isLoading = false;
      });
    }
  }


  // Stats Calculations
  int get _totalFeeds => _feeds.length;
  int get _breastCount => _feeds.where((f) => f['type'] == 'breast').length;
  int get _bottleCount => _feeds.where((f) => f['type'] == 'bottle').length;
  int get _solidCount => _feeds.where((f) => f['type'] == 'solid').length;

  double get _avgMlPerDay {
    if (_feeds.isEmpty) return 0;
    final bottles = _feeds.where((f) => f['type'] == 'bottle');
    if (bottles.isEmpty) return 0;
    final totalMl = bottles.fold<int>(0, (sum, f) => sum + ((f['amount_ml'] as int?) ?? 0));
    final days = _getDaySpan();
    return days > 0 ? totalMl / days : totalMl.toDouble();
  }

  int _getDaySpan() {
    if (_feeds.isEmpty) return 1;
    try {
      final dates = _feeds.map((f) => DateTime.parse(f['created_at']).toLocal()).toList();
      final earliest = dates.reduce((a, b) => a.isBefore(b) ? a : b);
      final latest = dates.reduce((a, b) => a.isAfter(b) ? a : b);
      return max(1, latest.difference(earliest).inDays + 1);
    } catch (_) { return 1; }
  }

  double get _feedsPerDay {
    final days = _getDaySpan();
    return days > 0 ? _totalFeeds / days : _totalFeeds.toDouble();
  }

  // Daily feed counts for the last 7 days
  List<int> get _weeklyFeedCounts {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _feeds.where((f) {
        try {
          final d = DateTime.parse(f['created_at']).toLocal();
          return d.year == day.year && d.month == day.month && d.day == day.day;
        } catch (_) { return false; }
      }).length;
    });
  }

  String _getPatternText() {
    if (_feeds.length < 3) return 'Log more feeds to see patterns.';
    final avg = _feedsPerDay;
    if (avg >= 8) return '📊 Baby is feeding frequently (~${avg.toStringAsFixed(1)}/day). This is normal for newborns.';
    if (avg >= 5) return '📊 Feeding pattern looks healthy at ~${avg.toStringAsFixed(1)} feeds/day.';
    return '📊 ~${avg.toStringAsFixed(1)} feeds/day detected. Consider if this meets your baby\'s needs.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);
    final isDark = colors.isDark;

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Feeding Analytics', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.warmPeach))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Stats
                        Row(
                          children: [
                            _miniStat('Total', '$_totalFeeds', colors.warmPeach, colors),
                            const SizedBox(width: 10),
                            _miniStat('Per Day', _feedsPerDay.toStringAsFixed(1), colors.sereneBlue, colors),
                            const SizedBox(width: 10),
                            _miniStat('Avg ml/d', _avgMlPerDay.toStringAsFixed(0), colors.gentlePurple, colors),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Feed Type Ratio
                        PremiumCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Feed Type Breakdown', style: typo.title),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 140,
                                child: _totalFeeds > 0
                                    ? CustomPaint(
                                        size: const Size(double.infinity, 140),
                                        painter: _DonutChartPainter(
                                          values: [_breastCount.toDouble(), _bottleCount.toDouble(), _solidCount.toDouble()],
                                          colors: [colors.warmPeach, colors.sereneBlue, colors.sageGreen],
                                          isDark: isDark,
                                        ),
                                      )
                                    : Center(child: Text('No data', style: typo.body)),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _legendItem('Breast', _breastCount, colors.warmPeach),
                                  _legendItem('Bottle', _bottleCount, colors.sereneBlue),
                                  _legendItem('Solid', _solidCount, colors.sageGreen),
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
                                  painter: _BarChartPainter(
                                    data: _weeklyFeedCounts,
                                    barColor: colors.warmPeach,
                                    textColor: colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pattern Insight
                        PremiumCard(
                          child: Row(
                            children: [
                              PremiumBubbleIcon(icon: Icons.insights_rounded, color: colors.softAmber, size: 20, padding: 12),
                              const SizedBox(width: 12),
                              Expanded(child: Text(_getPatternText(), style: typo.body)),
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

  Widget _miniStat(String label, String value, Color color, PremiumColors colors) {
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

  Widget _legendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label ($count)', style: PremiumTypography(context).caption),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final bool isDark;

  _DonutChartPainter({required this.values, required this.colors, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    final strokeWidth = 28.0;

    double startAngle = -pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.04,
        false,
        Paint()..color = colors[i]..style = PaintingStyle.stroke..strokeWidth = strokeWidth..strokeCap = StrokeCap.round,
      );
      startAngle += sweep;
    }

    // Center text
    final tp = TextPainter(
      text: TextSpan(
        text: '${total.toInt()}',
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.w800),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2 - 6));

    final label = TextPainter(
      text: TextSpan(text: 'feeds', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11)),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(center.dx - label.width / 2, center.dy + 8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BarChartPainter extends CustomPainter {
  final List<int> data;
  final Color barColor;
  final Color textColor;

  _BarChartPainter({required this.data, required this.barColor, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final startDay = now.subtract(const Duration(days: 6));

    final barWidth = size.width / 9;
    final maxVal = data.isEmpty ? 1.0 : max(data.reduce(max).toDouble(), 1.0);
    final chartHeight = size.height - 24;

    for (int i = 0; i < 7; i++) {
      final x = barWidth * 0.5 + i * (size.width / 7);
      final val = i < data.length ? data[i].toDouble() : 0;
      final barHeight = (val / maxVal) * chartHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 3, chartHeight - barHeight, barWidth * 2 / 3, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = barColor.withValues(alpha: i == 6 ? 1.0 : 0.5));

      // Count on top
      if (val > 0) {
        final tp = TextPainter(
          text: TextSpan(text: val.toInt().toString(), style: TextStyle(color: barColor, fontSize: 10, fontWeight: FontWeight.w700)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, chartHeight - barHeight - 14));
      }

      // Day label
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
