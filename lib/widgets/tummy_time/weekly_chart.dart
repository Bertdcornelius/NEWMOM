import 'package:flutter/material.dart';
import 'dart:math';
import '../premium_ui_components.dart';

class TummyTimeWeeklyChart extends StatelessWidget {
  final List<int> weeklyData;
  final int dailyGoalMin;

  const TummyTimeWeeklyChart({
    super.key,
    required this.weeklyData,
    required this.dailyGoalMin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    return PremiumCard(
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
                data: weeklyData,
                barColor: colors.softAmber,
                textColor: colors.textSecondary,
                goalSec: dailyGoalMin * 60,
              ),
            ),
          ),
        ],
      ),
    );
  }
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

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - barWidth / 3, chartHeight - barHeight, barWidth * 2 / 3, barHeight.toDouble()),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = val >= goalSec ? barColor : barColor.withValues(alpha: 0.4));

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
