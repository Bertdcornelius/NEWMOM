import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/care_repository.dart';
import '../../widgets/premium_ui_components.dart';

class TeethingTrackerScreen extends StatefulWidget {
  const TeethingTrackerScreen({super.key});

  @override
  State<TeethingTrackerScreen> createState() => _TeethingTrackerScreenState();
}

class _TeethingTrackerScreenState extends State<TeethingTrackerScreen> {
  // Map of tooth index -> {erupted: bool, date: String, notes: String}
  Map<String, Map<String, dynamic>> _teethData = {};

  // Baby teeth layout — 20 teeth
  static const toothNames = [
    // Upper row (right to left from baby's perspective, displayed L-R)
    'Upper Right 2nd Molar', 'Upper Right 1st Molar', 'Upper Right Canine', 'Upper Right Lateral', 'Upper Right Central',
    'Upper Left Central', 'Upper Left Lateral', 'Upper Left Canine', 'Upper Left 1st Molar', 'Upper Left 2nd Molar',
    // Lower row
    'Lower Left 2nd Molar', 'Lower Left 1st Molar', 'Lower Left Canine', 'Lower Left Lateral', 'Lower Left Central',
    'Lower Right Central', 'Lower Right Lateral', 'Lower Right Canine', 'Lower Right 1st Molar', 'Lower Right 2nd Molar',
  ];

  static const toothLabels = [
    'E', 'D', 'C', 'B', 'A', 'A', 'B', 'C', 'D', 'E',
    'E', 'D', 'C', 'B', 'A', 'A', 'B', 'C', 'D', 'E',
  ];

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
    final ss = context.read<CareRepository>();
    final data = (await ss.getTeethingData()).data ?? [];
    
    // Map list to our specific format
    _teethData = {};
    for (var item in data) {
      _teethData[item['tooth_index'].toString()] = {
        'id': item['id'],
        'erupted': true,
        'date': item['erupted_date'],
        'notes': item['notes'],
      };
    }
    
    if (mounted) setState(() {});
  }

  Future<void> _saveTooth(int index, String date, String notes) async {
    final user = context.read<AuthRepository>().currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in. Please sign in first.'), backgroundColor: Colors.red));
      return;
    }
    final ss = context.read<CareRepository>();
    final result = await ss.saveTeethingData({
      'user_id': user.id,
      'tooth_index': index,
      'erupted_date': date,
      'notes': notes,
    });
    if (!result.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to save'), backgroundColor: Colors.red));
    }
    _loadData();
  }

  int get _eruptedCount => _teethData.values.where((t) => t['erupted'] == true).length;


  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Teething Tracker', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress
                  PremiumCard(
                    child: Row(
                      children: [
                        PremiumBubbleIcon(icon: Icons.mood_rounded, color: colors.warmPeach, size: 24, padding: 14),
                        const SizedBox(width: 16),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Teeth Erupted', style: typo.caption),
                            Text('$_eruptedCount / 20', style: PremiumTypography(context).bodyBold.copyWith(
                              fontSize: 24, fontWeight: FontWeight.w800, color: colors.warmPeach,
                            )),
                          ],
                        )),
                        // Progress circle
                        SizedBox(
                          width: 56, height: 56,
                          child: CircularProgressIndicator(
                            value: _eruptedCount / 20.0,
                            backgroundColor: colors.surfaceMuted,
                            strokeWidth: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tooth Chart
                  PremiumCard(
                    child: Column(
                      children: [
                        Text('Tooth Chart', style: typo.title),
                        const SizedBox(height: 8),
                        Text('Tap a tooth to mark it', style: typo.caption),
                        const SizedBox(height: 20),

                        // Upper jaw
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(10, (i) => _buildTooth(i, colors)),
                        ),
                        Container(height: 2, width: 280, color: colors.surfaceMuted),
                        const SizedBox(height: 6),
                        // Lower jaw
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(10, (i) => _buildTooth(i + 10, colors)),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legendDot(colors.warmPeach, 'Erupted'),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Timeline
                  Text('Eruption Timeline', style: typo.h2),
                  const SizedBox(height: 12),

                  ..._buildTimeline(colors, typo),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTooth(int index, PremiumColors colors) {
    final key = index.toString();
    final data = _teethData[key];
    final isErupted = data?['erupted'] == true;

    return GestureDetector(
      onTap: () => _toggleTooth(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 26, height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isErupted ? colors.warmPeach : colors.surfaceMuted,
          borderRadius: BorderRadius.circular(index < 10 ? 6 : 6)
              .copyWith(
                topLeft: Radius.circular(index < 10 ? 8 : 4),
                topRight: Radius.circular(index < 10 ? 8 : 4),
                bottomLeft: Radius.circular(index < 10 ? 4 : 8),
                bottomRight: Radius.circular(index < 10 ? 4 : 8),
              ),
          border: Border.all(
            color: isErupted ? colors.warmPeach : colors.textMuted.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isErupted ? [BoxShadow(color: colors.warmPeach.withValues(alpha: 0.3), blurRadius: 6)] : [],
        ),
        child: Center(
          child: Text(
            toothLabels[index],
            style: PremiumTypography(context).bodyBold.copyWith(
              fontSize: 10, fontWeight: FontWeight.w800,
              color: isErupted ? Colors.white : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: PremiumTypography(context).caption),
      ],
    );
  }

  void _toggleTooth(int index) {
    final key = index.toString();
    final current = _teethData[key];
    final isErupted = current?['erupted'] == true;

    if (isErupted) {
      // Show info / option to remove
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(toothNames[index]),
          content: Text('Erupted: ${current?['date'] ?? 'Unknown'}\n${current?['notes'] ?? ''}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            TextButton(
              onPressed: () async {
                final ss = context.read<CareRepository>();
                if (current?['id'] != null) {
                  await ss.deleteTeethingData(current!['id']);
                }
                _loadData();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      // Mark as erupted
      final notesC = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Mark ${toothNames[index]}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date: ${DateFormat('MMM d, yyyy').format(DateTime.now())}'),
              const SizedBox(height: 12),
              TextField(
                controller: notesC,
                decoration: const InputDecoration(labelText: 'Notes (optional)', hintText: 'e.g., fussy, drooling'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                _saveTooth(index, DateFormat('MMM d, yyyy').format(DateTime.now()), notesC.text);
                Navigator.pop(ctx);
            },
              child: const Text('Mark Erupted'),
            ),
          ],
        ),
      );
    }
  }

  List<Widget> _buildTimeline(PremiumColors colors, PremiumTypography typo) {
    final erupted = _teethData.entries
        .where((e) => e.value['erupted'] == true)
        .toList()
      ..sort((a, b) {
        try {
          final da = DateFormat('MMM d, yyyy').parse(a.value['date']);
          final db = DateFormat('MMM d, yyyy').parse(b.value['date']);
          return db.compareTo(da);
        } catch (_) { return 0; }
      });

    if (erupted.isEmpty) {
      return [
        PremiumCard(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text('No teeth erupted yet', style: typo.body)),
        )),
      ];
    }

    return erupted.map((e) {
      final idx = int.tryParse(e.key) ?? 0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: DataTile(
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: colors.warmPeach.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Center(child: Text('🦷', style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(idx < toothNames.length ? toothNames[idx] : 'Tooth', style: typo.bodyBold),
                  Text(e.value['date'] ?? '', style: typo.caption),
                ],
              )),
            ],
          ),
        ),
      );
    }).toList();
  }
}
