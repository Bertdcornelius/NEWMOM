import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/care_repository.dart';
import '../../viewmodels/tracker_viewmodels.dart';
import '../../widgets/premium_ui_components.dart';

class DiaperScreen extends StatelessWidget {
  const DiaperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DiaperViewModel(context.read<CareRepository>()),
      child: const _DiaperScreenView(),
    );
  }
}

class _DiaperScreenView extends StatelessWidget {
  const _DiaperScreenView();

  int min(int a, int b) => a < b ? a : b;

  String _getPatternInsight(int total) {
    if (total >= 8) return '🟢 Great! $total changes today — excellent hydration!';
    if (total >= 5) return '🟡 $total changes so far — on track for the day.';
    if (total >= 1) return '🔵 $total changes today — keep monitoring.';
    return '⚪ No changes logged yet today.';
  }

  Future<void> _handleSave(BuildContext context, String type) async {
    final user = context.read<AuthRepository>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in'), backgroundColor: Colors.red));
      return;
    }
    
    final vm = context.read<DiaperViewModel>();
    final success = await vm.saveDiaperLog({
      'user_id': user.id,
      'type': type,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$type diaper logged! ✅')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Failed to log diaper'), backgroundColor: Colors.red));
        vm.clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiaperViewModel>();
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    // If there's an uncontrolled error fetching the stream
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (vm.errorMessage != null && !vm.errorMessage!.contains('save')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage!), backgroundColor: Colors.red));
        vm.clearError();
      }
    });

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Diaper Tracker', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: vm.isLoading
          ? Center(child: CircularProgressIndicator(color: colors.sageGreen))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
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
                                  _summaryBubble(context, '💧', 'Wet', '${vm.todayPee}', Colors.blue, colors),
                                  const SizedBox(width: 12),
                                  _summaryBubble(context, '💩', 'Dirty', '${vm.todayPoop}', Colors.brown, colors),
                                  const SizedBox(width: 12),
                                  _summaryBubble(context, '📋', 'Total', '${vm.todayTotal}', colors.sageGreen, colors),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Quick Log Buttons
                        Text('Quick Log', style: typo.h2),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _quickLogBtn(context, 'Wet', '💧', PremiumColors(context).sereneBlue, 'pee', colors),
                            const SizedBox(width: 16),
                            _quickLogBtn(context, 'Dirty', '💩', const Color(0xFF8D6E63), 'poop', colors),
                            const SizedBox(width: 16),
                            _quickLogBtn(context, 'Mixed', '🤢', PremiumColors(context).softAmber, 'both', colors),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Pattern Analysis
                        if (vm.logs.length >= 3) ...[
                          PremiumCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    PremiumBubbleIcon(icon: Icons.auto_graph_rounded, color: colors.gentlePurple, size: 24, padding: 12),
                                    const SizedBox(width: 16),
                                    Text('Pattern Insights', style: typo.title),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(_getPatternInsight(vm.todayTotal), style: typo.body),
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
                            Text('${vm.logs.length} entries', style: typo.caption),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (vm.logs.isEmpty)
                          PremiumCard(child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(child: Text('No diaper logs yet', style: typo.body)),
                          ))
                        else
                          ...List.generate(min(vm.logs.length, 20), (i) {
                            final log = vm.logs[i];
                            return _buildLogTile(context, log, colors, typo, i);
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

  Widget _summaryBubble(BuildContext context, String emoji, String label, String value, Color color, PremiumColors colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 4),
            Text(label, style: PremiumTypography(context).caption.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _quickLogBtn(BuildContext context, String label, String emoji, Color color, String type, PremiumColors colors) {
    return Expanded(
      child: _ScaleOnTapItem(
        onTap: () => _handleSave(context, type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(label, style: PremiumTypography(context).bodyBold.copyWith(color: color, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogTile(BuildContext context, Map<String, dynamic> log, PremiumColors colors, PremiumTypography typo, int index) {
    final type = log['type'] ?? 'unknown';
    final emoji = type == 'pee' ? '💧' : type == 'poop' ? '💩' : '🤢';
    final color = type == 'pee' ? colors.sereneBlue : type == 'poop' ? const Color(0xFF8D6E63) : colors.softAmber;
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
}

// Reusable scale-on-tap interaction
class _ScaleOnTapItem extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ScaleOnTapItem({required this.child, required this.onTap});

  @override
  State<_ScaleOnTapItem> createState() => _ScaleOnTapItemState();
}

class _ScaleOnTapItemState extends State<_ScaleOnTapItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap(); },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
