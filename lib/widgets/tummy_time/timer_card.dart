import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../premium_ui_components.dart';

class TummyTimeTimerCard extends StatelessWidget {
  final bool isTimerRunning;
  final String formattedTime;
  final double todayProgress;
  final double todayMin;
  final int dailyGoalMin;
  final VoidCallback onToggleTimer;
  final VoidCallback onEditGoal;

  const TummyTimeTimerCard({
    super.key,
    required this.isTimerRunning,
    required this.formattedTime,
    required this.todayProgress,
    required this.todayMin,
    required this.dailyGoalMin,
    required this.onToggleTimer,
    required this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    return PremiumCard(
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
                    progress: todayProgress,
                    color: colors.softAmber,
                    bgColor: colors.surfaceMuted,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isTimerRunning)
                      Text(formattedTime, style: GoogleFonts.plusJakartaSans(
                        fontSize: 36, fontWeight: FontWeight.w800, color: colors.softAmber,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ))
                    else
                      Text('${todayMin.toStringAsFixed(0)}m', style: GoogleFonts.plusJakartaSans(
                        fontSize: 36, fontWeight: FontWeight.w800, color: colors.textPrimary,
                      )),
                    Text(isTimerRunning ? 'In progress...' : 'of ${dailyGoalMin}m goal', style: typo.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Timer Button
          PremiumActionButton(
            label: isTimerRunning ? 'Stop & Save' : 'Start Tummy Time',
            icon: isTimerRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
            color: isTimerRunning ? colors.warmPeach : colors.softAmber,
            onTap: onToggleTimer,
          ),
          const SizedBox(height: 12),

          // Goal Setter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Daily Goal: ', style: typo.body),
              GestureDetector(
                onTap: onEditGoal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.softAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$dailyGoalMin min', style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w700, color: colors.softAmber,
                  )),
                ),
              ),
            ],
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

    canvas.drawCircle(center, radius, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = bgColor);

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
