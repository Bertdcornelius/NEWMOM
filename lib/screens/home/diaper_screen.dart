import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../services/baby_data_repository.dart';
import '../../widgets/premium_ui_components.dart';


class DiaperScreen extends StatefulWidget {
  const DiaperScreen({super.key});

  @override
  State<DiaperScreen> createState() => _DiaperScreenState();
}

class _DiaperScreenState extends State<DiaperScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadData();
  }



  Future<void> _loadData() async {
    final service = context.read<BabyDataRepository>();
    final logs = await service.getDiaperLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });

    }
  }



  // Today's stats
  Map<String, int> get _todayStats {
    final now = DateTime.now();
    final today = _logs.where((l) {
      try {
        final date = DateTime.parse(l['created_at']).toLocal();
        return date.year == now.year && date.month == now.month && date.day == now.day;
      } catch (_) { return false; }
    }).toList();

    return {
      'pee': today.where((l) => l['type'] == 'pee' || l['type'] == 'both').length,
      'poop': today.where((l) => l['type'] == 'poop' || l['type'] == 'both').length,
      'total': today.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);
    final stats = _todayStats;

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Diaper Tracker', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.sageGreen))
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Today's Summary
                          PremiumCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Today\'s Summary', style: typo.title),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _summaryBubble('💧', 'Wet', '${stats['pee']}', Colors.blue, colors),
                                    const SizedBox(width: 12),
                                    _summaryBubble('💩', 'Dirty', '${stats['poop']}', Colors.brown, colors),
                                    const SizedBox(width: 12),
                                    _summaryBubble('📋', 'Total', '${stats['total']}', colors.sageGreen, colors),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Quick Log Buttons
                          Text('Quick Log', style: typo.h2),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _quickLogBtn('Wet', '💧', Colors.blue, 'pee', colors),
                              const SizedBox(width: 12),
                              _quickLogBtn('Dirty', '💩', Colors.brown, 'poop', colors),
                              const SizedBox(width: 12),
                              _quickLogBtn('Both', '🤢', Colors.orange, 'both', colors),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Pattern Analysis
                          if (_logs.length >= 3) ...[
                            PremiumCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      PremiumBubbleIcon(icon: Icons.auto_graph_rounded, color: colors.gentlePurple, size: 20, padding: 10),
                                      const SizedBox(width: 12),
                                      Text('Pattern Insights', style: typo.title),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(_getPatternInsight(), style: typo.body),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // History
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('History', style: typo.h2),
                              Text('${_logs.length} entries', style: typo.caption),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_logs.isEmpty)
                            PremiumCard(child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Center(child: Text('No diaper logs yet', style: typo.body)),
                            ))
                          else
                            ...List.generate(min(_logs.length, 20), (i) {
                              final log = _logs[i];
                              return _buildLogTile(log, colors, typo, i);
                            }),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  int min(int a, int b) => a < b ? a : b;

  Widget _summaryBubble(String emoji, String label, String value, Color color, PremiumColors colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: PremiumTypography(context).caption),
          ],
        ),
      ),
    );
  }

  Widget _quickLogBtn(String label, String emoji, Color color, String type, PremiumColors colors) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _saveDiaperLog(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w700, color: color,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> log, PremiumColors colors, PremiumTypography typo, int index) {
    final type = log['type'] ?? 'unknown';
    final emoji = type == 'pee' ? '💧' : type == 'poop' ? '💩' : '🤢';
    final color = type == 'pee' ? Colors.blue : type == 'poop' ? Colors.brown : Colors.orange;
    String timeStr = 'Unknown';
    try {
      final date = DateTime.parse(log['created_at']).toLocal();
      timeStr = DateFormat('MMM d, h:mm a').format(date);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DataTile(
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.toUpperCase(), style: typo.bodyBold),
                Text(timeStr, style: typo.caption),
              ],
            )),
          ],
        ),
      ),
    );
  }

  String _getPatternInsight() {
    final stats = _todayStats;
    final total = stats['total'] ?? 0;
    if (total >= 8) return '🟢 Great! $total changes today — excellent hydration!';
    if (total >= 5) return '🟡 $total changes so far — on track for the day.';
    if (total >= 1) return '🔵 $total changes today — keep monitoring.';
    return '⚪ No changes logged yet today.';
  }

  Future<void> _saveDiaperLog(String type) async {
    final userId = context.read<BabyDataRepository>().currentUser?.id;
    if (userId != null) {
      await context.read<BabyDataRepository>().saveDiaperLog({
        'id': const Uuid().v4(),
        'user_id': userId,
        'type': type,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      await _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$type diaper logged! ✅')));
    }
  }
}
