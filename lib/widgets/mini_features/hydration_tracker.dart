import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../premium_ui_components.dart';

class HydrationTracker extends StatefulWidget {
  const HydrationTracker({super.key});

  @override
  State<HydrationTracker> createState() => _HydrationTrackerState();
}

class _HydrationTrackerState extends State<HydrationTracker> with SingleTickerProviderStateMixin {
  int _glasses = 0;
  final int _goal = 8;
  late String _todayKey;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _todayKey = 'water_${DateFormat('yyyy_MM_dd').format(DateTime.now())}';
    
    _waveController = AnimationController(
       vsync: this, 
       duration: const Duration(milliseconds: 2000)
    )..repeat();
    
    _loadData();
  }
  
  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _glasses = prefs.getInt(_todayKey) ?? 0;
    });
  }

  Future<void> _increment() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
       _glasses++;
    });
    await prefs.setInt(_todayKey, _glasses);
  }
  
  Future<void> _decrement() async {
      if (_glasses <= 0) return;
      final prefs = await SharedPreferences.getInstance();
      setState(() => _glasses--);
      await prefs.setInt(_todayKey, _glasses);
  }

  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);
    final progress = (_glasses / _goal).clamp(0.0, 1.0);
    final isComplete = _glasses >= _goal;

    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Hydration Ring", style: typo.h2),
              if (isComplete)
                 Container(
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                     decoration: BoxDecoration(color: colors.softAmber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                     child: Text("Goal Reached! 🎉", style: typo.caption.copyWith(color: colors.softAmber, fontWeight: FontWeight.bold)),
                 )
            ],
          ),
          const SizedBox(height: 32),
          
          // Liquid Ring
          Stack(
             alignment: Alignment.center,
             children: [
                SizedBox(
                   width: 140, height: 140,
                   child: TweenAnimationBuilder<double>(
                       tween: Tween<double>(begin: 0.0, end: progress),
                       duration: const Duration(milliseconds: 1200),
                       curve: Curves.easeOutCirc,
                       builder: (context, value, child) {
                           return CustomPaint(
                               painter: _LiquidRingPainter(
                                   progress: value,
                                   waveAnimation: _waveController,
                                   color: colors.sereneBlue,
                                   trackColor: colors.surfaceMuted,
                               ),
                           );
                       }
                   )
                ),
                Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                      Icon(Icons.water_drop_rounded, color: colors.sereneBlue, size: 28),
                      const SizedBox(height: 4),
                      Text("$_glasses / $_goal", style: GoogleFonts.plusJakartaSans(
                          fontSize: 28, fontWeight: FontWeight.w800, color: colors.textPrimary
                      )),
                      Text("glasses", style: typo.caption),
                   ],
                )
             ],
          ),
          
          const SizedBox(height: 36),
          
          // Controls
          Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
                 _ctrlBtn(Icons.remove, _decrement, colors, isSecondary: true),
                 const SizedBox(width: 16),
                 Expanded(
                     child: ElevatedButton.icon(
                         onPressed: _increment,
                         icon: const Icon(Icons.add_rounded, color: Colors.white),
                         label: const Text("Drink 1 Glass", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                         style: ElevatedButton.styleFrom(
                             backgroundColor: colors.sereneBlue,
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                             elevation: 0,
                         )
                     )
                 )
             ]
          )
        ],
      ),
    );
  }
  
  Widget _ctrlBtn(IconData icon, VoidCallback onTap, PremiumColors colors, {bool isSecondary = false}) {
      return GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: isSecondary ? colors.surfaceMuted : colors.sereneBlue,
                  shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSecondary ? colors.textPrimary : Colors.white)
          )
      );
  }
}

class _LiquidRingPainter extends CustomPainter {
    final double progress;
    final Animation<double> waveAnimation;
    final Color color;
    final Color trackColor;
    
    _LiquidRingPainter({required this.progress, required this.waveAnimation, required this.color, required this.trackColor}) : super(repaint: waveAnimation);
    
    @override
    void paint(Canvas canvas, Size size) {
        final center = Offset(size.width / 2, size.height / 2);
        final radius = size.width / 2;
        final strokeWidth = 16.0;
        
        // Background track
        final trackPaint = Paint()
            ..color = trackColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;
            
        canvas.drawCircle(center, radius, trackPaint);
        
        if (progress <= 0) return;
        
        // Progress Arc
        final arcPaint = Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.round;
            
        final sweepAngle = 2 * math.pi * progress;
        // Start at top (-pi/2)
        canvas.drawArc(
            Rect.fromCircle(center: center, radius: radius),
            -math.pi / 2, 
            sweepAngle, 
            false, 
            arcPaint
        );
        
        // Draw tiny particle ripples if progressing
        if (progress > 0 && progress < 1) {
            final headAngle = -math.pi / 2 + sweepAngle;
            final headOffset = Offset(
                center.dx + radius * math.cos(headAngle),
                center.dy + radius * math.sin(headAngle)
            );
            
            final glowPaint = Paint()
                ..color = color.withValues(alpha: 0.4)
                ..style = PaintingStyle.fill;
                
            // Pulse glow at the leading edge based on waveAnimation
            final pulseRadius = strokeWidth * 0.8 + (math.sin(waveAnimation.value * 2 * math.pi) * 3);
            canvas.drawCircle(headOffset, pulseRadius, glowPaint);
        }
    }
    
    @override
    bool shouldRepaint(covariant _LiquidRingPainter oldDelegate) {
        return oldDelegate.progress != progress || oldDelegate.color != color;
    }
}
