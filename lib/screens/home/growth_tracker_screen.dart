import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:math';
import '../../repositories/auth_repository.dart';
import '../../repositories/care_repository.dart';
import '../../viewmodels/tracker_viewmodels.dart';
import '../../widgets/premium_ui_components.dart';

class GrowthTrackerScreen extends StatelessWidget {
  const GrowthTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GrowthViewModel(context.read<CareRepository>()),
      child: const _GrowthTrackerScreenView(),
    );
  }
}

class _GrowthTrackerScreenView extends StatefulWidget {
  const _GrowthTrackerScreenView();

  @override
  State<_GrowthTrackerScreenView> createState() => _GrowthTrackerScreenViewState();
}

class _GrowthTrackerScreenViewState extends State<_GrowthTrackerScreenView> {
  String _selectedChart = 'weight'; // weight, height, head

  Future<void> _handleSave(BuildContext context, Map<String, dynamic> entry) async {
    final user = context.read<AuthRepository>().currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in'), backgroundColor: Colors.red));
      return;
    }
    
    final vm = context.read<GrowthViewModel>();
    final newEntry = {
      'user_id': user.id,
      'weight_kg': entry['weight'],
      'height_cm': entry['height'],
      'head_circ_cm': entry['head'],
      'timestamp': entry['timestamp'],
    };
    
    final success = await vm.saveEntry(newEntry);
    
    if (mounted) {
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Failed to save'), backgroundColor: Colors.red));
        vm.clearError();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Measurement saved! ✅')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GrowthViewModel>();
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);
    final isDark = colors.isDark;

    // Handle asynchronous uncaught stream errors globally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (vm.errorMessage != null && !vm.errorMessage!.contains('save') && !vm.errorMessage!.contains('delete')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage!), backgroundColor: Colors.red));
        vm.clearError();
      }
    });

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Growth Tracker', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: colors.sageGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart Type Selector
                  Row(
                    children: [
                      _chartTab('Weight', 'weight', Icons.monitor_weight_outlined, colors.warmPeach, colors),
                      const SizedBox(width: 10),
                      _chartTab('Height', 'height', Icons.height_rounded, colors.sereneBlue, colors),
                      const SizedBox(width: 10),
                      _chartTab('Head', 'head', Icons.circle_outlined, colors.gentlePurple, colors),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Growth Chart
                  PremiumCard(
                    child: SizedBox(
                      height: 220,
                      child: vm.entries.isEmpty
                          ? Center(child: Text('Add your first measurement!', style: typo.body))
                          : CustomPaint(
                              size: const Size(double.infinity, 220),
                              painter: _GrowthChartPainter(
                                entries: List.from(vm.entries.reversed), // Chronological for graph
                                field: _selectedChart,
                                lineColor: _selectedChart == 'weight'
                                    ? colors.warmPeach
                                    : _selectedChart == 'height'
                                        ? colors.sereneBlue
                                        : colors.gentlePurple,
                                textColor: colors.textSecondary,
                                gridColor: colors.surfaceMuted,
                                isDark: isDark,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Latest Stats
                  if (vm.entries.isNotEmpty) ...[
                    _buildLatestStats(vm.entries, colors, typo),
                    const SizedBox(height: 24),
                  ],

                  // History
                  Text('History', style: typo.h2),
                  const SizedBox(height: 12),

                  if (vm.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (vm.entries.isEmpty)
                    PremiumCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(child: Column(
                          children: [
                            Icon(Icons.straighten_rounded, size: 48, color: colors.textMuted),
                            const SizedBox(height: 12),
                            Text('No measurements yet', style: typo.body),
                            const SizedBox(height: 4),
                            Text('Tap + to add your first entry', style: typo.caption),
                          ],
                        )),
                      ),
                    )
                  else
                    Column(
                      children: List.generate(vm.entries.length, (index) {
                        final entry = vm.entries[index];
                        return _buildEntryTile(context, entry, colors, typo, vm);
                      }),
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

  Widget _chartTab(String label, String key, IconData icon, Color color, PremiumColors colors) {
    final isSelected = _selectedChart == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedChart = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? color : colors.surfaceMuted, width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : colors.textMuted, size: 22),
              const SizedBox(height: 4),
              Text(label, style: PremiumTypography(context).bodyBold.copyWith(
                fontSize: 12, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : colors.textSecondary,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestStats(List<Map<String,dynamic>> entries, PremiumColors colors, PremiumTypography typo) {
    final latest = entries.first; // Since list is reversed
    return Row(
      children: [
        _statBubble('Weight', '${latest['weight_kg'] ?? '--'} kg', colors.warmPeach, colors),
        const SizedBox(width: 12),
        _statBubble('Height', '${latest['height_cm'] ?? '--'} cm', colors.sereneBlue, colors),
        const SizedBox(width: 12),
        _statBubble('Head', '${latest['head_circ_cm'] ?? '--'} cm', colors.gentlePurple, colors),
      ],
    );
  }

  Widget _statBubble(String label, String value, Color color, PremiumColors colors) {
    return Expanded(
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(label, style: PremiumTypography(context).caption),
            const SizedBox(height: 4),
            Text(value, style: PremiumTypography(context).bodyBold.copyWith(
              fontSize: 18, fontWeight: FontWeight.w800, color: color,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTile(BuildContext context, Map<String, dynamic> entry, PremiumColors colors, PremiumTypography typo, GrowthViewModel vm) {
    String dateStr = 'Unknown';
    try {
      final dt = DateTime.parse(entry['timestamp']).toLocal();
      dateStr = DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DataTile(
        onTap: () => _showDeleteDialog(context, entry, colors, vm),
        child: Row(
          children: [
            Container(
              width: 4, height: 44,
              decoration: BoxDecoration(color: colors.sageGreen, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateStr, style: typo.bodyBold),
                const SizedBox(height: 2),
                Text('${entry['weight_kg'] ?? '--'} kg  •  ${entry['height_cm'] ?? '--'} cm  •  Head: ${entry['head_circ_cm'] ?? '--'} cm',
                    style: typo.caption),
              ],
            )),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final weightC = TextEditingController();
    final heightC = TextEditingController();
    final headC = TextEditingController();
    DateTime selectedDate = DateTime.now();
    final colors = PremiumColors(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.textMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('New Measurement', style: PremiumTypography(context).h2),
            const SizedBox(height: 20),
            _inputField(weightC, 'Weight (kg)', Icons.monitor_weight_outlined, colors.warmPeach, colors),
            const SizedBox(height: 12),
            _inputField(heightC, 'Height (cm)', Icons.height_rounded, colors.sereneBlue, colors),
            const SizedBox(height: 12),
            _inputField(headC, 'Head Circumference (cm)', Icons.circle_outlined, colors.gentlePurple, colors),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: PremiumActionButton(
                label: 'Save Measurement',
                icon: Icons.check_circle_outline_rounded,
                color: colors.sageGreen,
                onTap: () {
                  if (weightC.text.trim().isEmpty && heightC.text.trim().isEmpty && headC.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter at least one measurement.')));
                    return;
                  }
                  
                  final w = double.tryParse(weightC.text.trim());
                  final h = double.tryParse(heightC.text.trim());
                  final he = double.tryParse(headC.text.trim());

                  if ((weightC.text.trim().isNotEmpty && w == null) || 
                      (heightC.text.trim().isNotEmpty && h == null) || 
                      (headC.text.trim().isNotEmpty && he == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid numeric values.')));
                    return;
                  }

                  if ((w != null && (w <= 0 || w > 200)) || 
                      (h != null && (h <= 0 || h > 200)) || 
                      (he != null && (he <= 0 || he > 200))) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Measurements are outside realistic bounds (0-200).')));
                    return;
                  }

                  final newEntry = {
                    'weight': w,
                    'height': h,
                    'head': he,
                    'timestamp': selectedDate.toIso8601String(),
                  };
                  _handleSave(context, newEntry);
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label, IconData icon, Color color, PremiumColors colors) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color, size: 22),
        filled: true,
        fillColor: colors.surfaceMuted,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> item, PremiumColors colors, GrowthViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This measurement will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (item['id'] != null) {
                final success = await vm.deleteEntry(item['id']);
                if (ctx.mounted) {
                   Navigator.pop(ctx);
                   if (!success) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Failed to delete'), backgroundColor: Colors.red));
                     vm.clearError();
                   }
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: colors.warmPeach)),
          ),
        ],
      ),
    );
  }
}

// Custom Growth Chart Painter
class _GrowthChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> entries;
  final String field;
  final Color lineColor;
  final Color textColor;
  final Color gridColor;
  final bool isDark;

  _GrowthChartPainter({
    required this.entries,
    required this.field,
    required this.lineColor,
    required this.textColor,
    required this.gridColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    
    // Map JSON field to actual database field names used in entries
    final mappedField = field == 'weight' ? 'weight_kg' : field == 'height' ? 'height_cm' : 'head_circ_cm';

    final values = entries
        .map((e) => (e[mappedField] as num?)?.toDouble())
        .where((v) => v != null)
        .cast<double>()
        .toList();

    if (values.isEmpty) return;

    final padding = const EdgeInsets.only(left: 40, right: 16, top: 16, bottom: 28);
    final chartWidth = size.width - padding.left - padding.right;
    final chartHeight = size.height - padding.top - padding.bottom;

    final minVal = values.reduce(min) * 0.9;
    final maxVal = values.reduce(max) * 1.1;
    final range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    // Grid lines
    final gridPaint = Paint()..color = gridColor.withValues(alpha: 0.3)..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padding.top + chartHeight * (1 - i / 4);
      canvas.drawLine(Offset(padding.left, y), Offset(size.width - padding.right, y), gridPaint);
      final val = minVal + range * (i / 4);
      final tp = TextPainter(
        text: TextSpan(text: val.toStringAsFixed(1), style: TextStyle(color: textColor, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(padding.left - tp.width - 6, y - tp.height / 2));
    }

    // Data points and line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = lineColor;
    final glowPaint = Paint()..color = lineColor.withValues(alpha: 0.2);

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = padding.left + (values.length == 1 ? chartWidth / 2 : chartWidth * i / (values.length - 1));
      final y = padding.top + chartHeight * (1 - (values[i] - minVal) / range);
      points.add(Offset(x, y));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Gradient fill under the line
    final fillPath = Path.from(path);
    if (points.isNotEmpty) {
      fillPath.lineTo(points.last.dx, padding.top + chartHeight);
      fillPath.lineTo(points.first.dx, padding.top + chartHeight);
      fillPath.close();
    }
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withValues(alpha: 0.3), lineColor.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, padding.top, size.width, chartHeight));
    canvas.drawPath(fillPath, fillPaint);

    canvas.drawPath(path, linePaint);

    // Dots
    for (final p in points) {
      canvas.drawCircle(p, 7, glowPaint);
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 2, Paint()..color = isDark ? const Color(0xFF1E1E22) : Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter old) => true;
}
