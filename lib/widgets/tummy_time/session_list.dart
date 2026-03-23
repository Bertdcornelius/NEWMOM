import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../premium_ui_components.dart';

class TummyTimeSessionList extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;
  final GlobalKey<AnimatedListState> listKey;
  final Function(int) onDeleteSession;
  final bool isLoading;

  const TummyTimeSessionList({
    super.key,
    required this.sessions,
    required this.listKey,
    required this.onDeleteSession,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final typo = PremiumTypography(context);
    final colors = PremiumColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sessions', style: typo.h2),
        const SizedBox(height: 12),

        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (sessions.isEmpty)
          PremiumCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('No sessions yet. Start tummy time!', style: typo.body)),
            ),
          )
        else
          AnimatedList(
            key: listKey,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            initialItemCount: sessions.length > 20 ? 20 : sessions.length,
            itemBuilder: (context, index, animation) {
              final s = sessions[index];
              return buildSessionTile(s, index, animation, colors, typo, () => onDeleteSession(index));
            },
          ),
      ],
    );
  }

  static Widget buildSessionTile(Map<String, dynamic> s, int index, Animation<double> animation, PremiumColors colors, PremiumTypography typo, VoidCallback onTap) {
    final durSec = s['duration_sec'] as int? ?? 0;
    final durStr = durSec >= 60 ? '${durSec ~/ 60}m ${durSec % 60}s' : '${durSec}s';
    String dateStr = s['date'] ?? '';
    if (dateStr.isEmpty && s['timestamp'] != null) {
      dateStr = DateFormat('MMM d, h:mm a').format(DateTime.parse(s['timestamp']));
    }

    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: DataTile(
            onTap: onTap,
            child: Row(
              children: [
                PremiumBubbleIcon(icon: Icons.timer_outlined, color: colors.softAmber, size: 20, padding: 10),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(durStr, style: typo.bodyBold),
                    Text(dateStr, style: typo.caption),
                  ],
                )),
                Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
