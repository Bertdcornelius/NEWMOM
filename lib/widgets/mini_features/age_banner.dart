import 'package:flutter/material.dart';
import '../../widgets/premium_ui_components.dart';

class AgeBanner extends StatelessWidget {
  final String babyName;
  final DateTime? birthday;

  const AgeBanner({super.key, required this.babyName, this.birthday});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Mom & $babyName', style: PremiumTypography(context).h1),
            const SizedBox(width: 8),
            if (birthday != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: PremiumColors(context).softAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PremiumColors(context).softAmber.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _calculateExactAge(birthday!),
                  style: PremiumTypography(context).caption.copyWith(
                    color: PremiumColors(context).softAmber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        if (birthday != null) ...[
          const SizedBox(height: 6),
          Text(_getLeapHint(birthday!), style: PremiumTypography(context).caption),
        ]
      ],
    );
  }

  String _calculateExactAge(DateTime bday) {
    final diff = DateTime.now().difference(bday);
    final days = diff.inDays;
    if (days < 7) return "$days Days Old";
    final weeks = days ~/ 7;
    final remainingDays = days % 7;
    if (remainingDays == 0) return "$weeks Weeks Old";
    return "$weeks Wks, $remainingDays Days";
  }

  String _getLeapHint(DateTime bday) {
    final weeks = DateTime.now().difference(bday).inDays ~/ 7;
    if (weeks == 4 || weeks == 5) return "💡 Wonder Week 1: Changing Sensations!";
    if (weeks == 7 || weeks == 8) return "💡 Wonder Week 2: Patterns & Shadows!";
    if (weeks == 11 || weeks == 12) return "💡 Wonder Week 3: Smooth Transitions!";
    if (weeks == 18 || weeks == 19) return "💡 Wonder Week 4: Events & Sounds!";
    return "Watching them grow ❤️";
  }
}
