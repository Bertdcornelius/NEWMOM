import 'package:flutter/material.dart';
import '../../widgets/premium_ui_components.dart';

class SleepOrbButton extends StatelessWidget {
  final bool isSleeping;
  final Future<void> Function() onToggle;

  const SleepOrbButton({
    super.key,
    required this.isSleeping,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glowing rings
          AnimatedContainer(
            duration: const Duration(milliseconds: 2000),
            curve: Curves.easeInOutSine,
            width: isSleeping ? 320 : 260,
            height: isSleeping ? 320 : 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSleeping 
                  ? PremiumColors(context).sereneBlue.withValues(alpha: 0.05) 
                  : PremiumColors(context).softAmber.withValues(alpha: 0.05),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeInOutSine,
            width: isSleeping ? 280 : 220,
            height: isSleeping ? 280 : 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSleeping 
                  ? PremiumColors(context).sereneBlue.withValues(alpha: 0.1) 
                  : PremiumColors(context).softAmber.withValues(alpha: 0.1),
            ),
          ),
          // Inner solid button
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSleeping 
                      ? [const Color(0xFF6E85B7), const Color(0xFF4B659E)] // Deep Serene Blue gradient
                      : [const Color(0xFFFFD54F), const Color(0xFFFFB300)], // Soft Amber gradient
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: isSleeping 
                        ? const Color(0xFF6E85B7).withValues(alpha: 0.4) 
                        : const Color(0xFFFFB300).withValues(alpha: 0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  )
                ]
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(
                      isSleeping ? Icons.bedtime_rounded : Icons.wb_sunny_rounded, 
                      color: Colors.white, 
                      size: 64
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isSleeping ? "WAKE UP" : "START SLEEP", 
                      style: PremiumTypography(context).caption.copyWith(
                        color: Colors.white, 
                        letterSpacing: 2.0, 
                        fontWeight: FontWeight.bold
                      )
                    ),
                ],
            ),
          ),
        ],
      ),
    );
  }
}
