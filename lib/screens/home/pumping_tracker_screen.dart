import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';
import '../../services/local_storage_service.dart';
import '../../widgets/premium_ui_components.dart';

class PumpingTrackerScreen extends StatefulWidget {
  const PumpingTrackerScreen({super.key});

  @override
  State<PumpingTrackerScreen> createState() => _PumpingTrackerScreenState();
}

class _PumpingTrackerScreenState extends State<PumpingTrackerScreen> {
  List<Map<String, dynamic>> _sessions = [];
  double _milkStash = 0;

  // Timer
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  bool _isTimerRunning = false;
  String _selectedSide = 'Left';
  int _amountMl = 60;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _uiTimer?.cancel();
    super.dispose();
  }

  void _loadData() {
    final ls = context.read<LocalStorageService>();
    final raw = ls.getString('pumping_sessions');
    if (raw != null) _sessions = List<Map<String, dynamic>>.from(jsonDecode(raw));
    _milkStash = double.tryParse(ls.getString('milk_stash') ?? '0') ?? 0;
    if (mounted) setState(() {});
  }

  Future<void> _saveData() async {
    final ls = context.read<LocalStorageService>();
    await ls.saveString('pumping_sessions', jsonEncode(_sessions));
    await ls.saveString('milk_stash', _milkStash.toString());
  }

  void _toggleTimer() {
    setState(() {
      if (_isTimerRunning) {
        _stopwatch.stop();
        _isTimerRunning = false;
        _uiTimer?.cancel();
      } else {
        _stopwatch.reset();
        _stopwatch.start();
        _isTimerRunning = true;
        _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
      }
    });
  }

  String _formatStopwatch() {
    final elapsed = _stopwatch.elapsed;
    final m = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final s = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _saveSession() {
    final durationMin = _stopwatch.elapsed.inMinutes.clamp(1, 120);
    _sessions.insert(0, {
      'side': _selectedSide,
      'duration_min': durationMin,
      'amount_ml': _amountMl,
      'date': DateFormat('MMM d, h:mm a').format(DateTime.now()),
      'timestamp': DateTime.now().toIso8601String(),
    });
    _milkStash += _amountMl;
    _stopwatch.stop();
    _stopwatch.reset();
    _isTimerRunning = false;
    _uiTimer?.cancel();
    _saveData();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pump session saved! 🍼')));
  }


  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Pumping Tracker', style: typo.h2),
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
                  // Milk Stash Card
                  PremiumCard(
                    child: Row(
                      children: [
                        PremiumBubbleIcon(icon: Icons.inventory_2_outlined, color: colors.sereneBlue, size: 24, padding: 14),
                        const SizedBox(width: 16),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Milk Stash', style: typo.caption),
                            Text('${_milkStash.toStringAsFixed(0)} ml', style: GoogleFonts.plusJakartaSans(
                              fontSize: 24, fontWeight: FontWeight.w800, color: colors.sereneBlue,
                            )),
                          ],
                        )),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _stashBtn(Icons.remove, () {
                              setState(() { _milkStash = (_milkStash - 30).clamp(0, 99999); });
                              _saveData();
                            }, colors),
                            const SizedBox(width: 8),
                            _stashBtn(Icons.add, () {
                              setState(() { _milkStash += 30; });
                              _saveData();
                            }, colors),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Timer Section
                  PremiumCard(
                    child: Column(
                      children: [
                        Text('Pump Timer', style: typo.title),
                        const SizedBox(height: 20),

                        // Side Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: ['Left', 'Right', 'Both'].map((side) {
                            final isSelected = _selectedSide == side;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedSide = side),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? colors.gentlePurple : colors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(100),
                                  ), // Closing BoxDecoration
                                  child: Text(side, style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : colors.textSecondary,
                                  )),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Timer Display
                        Container(
                          width: 160, height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isTimerRunning ? colors.gentlePurple.withValues(alpha: 0.1) : colors.surfaceMuted,
                            border: Border.all(color: colors.gentlePurple, width: 4),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_formatStopwatch(), style: GoogleFonts.plusJakartaSans(
                                fontSize: 40, fontWeight: FontWeight.w800, color: colors.textPrimary,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              )),
                              Text(_isTimerRunning ? 'Pumping...' : 'Ready', style: typo.caption),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Timer Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 56,
                              icon: Icon(
                                _isTimerRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                                color: colors.gentlePurple,
                              ),
                              onPressed: _toggleTimer,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Amount Slider
                        Text('Amount: $_amountMl ml', style: typo.bodyBold),
                        Slider(
                          value: _amountMl.toDouble(),
                          min: 10,
                          max: 300,
                          divisions: 29,
                          activeColor: colors.gentlePurple,
                          label: '$_amountMl ml',
                          onChanged: (v) => setState(() => _amountMl = v.toInt()),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: PremiumActionButton(
                            label: 'Save Session',
                            icon: Icons.check_circle_outline_rounded,
                            color: colors.gentlePurple,
                            onTap: _saveSession,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // History
                  Text('Session History', style: typo.h2),
                  const SizedBox(height: 12),

                  if (_sessions.isEmpty)
                    PremiumCard(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('No sessions yet', style: typo.body)),
                    ))
                  else
                    ...List.generate(_sessions.length > 15 ? 15 : _sessions.length, (i) {
                      final s = _sessions[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DataTile(
                          onTap: () => _deleteSession(i),
                          child: Row(
                            children: [
                              PremiumBubbleIcon(icon: Icons.water_drop_outlined, color: colors.gentlePurple, size: 20, padding: 10),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${s['side']} • ${s['duration_min']} min • ${s['amount_ml']} ml',
                                      style: typo.bodyBold),
                                  Text(s['date'] ?? '', style: typo.caption),
                                ],
                              )),
                              Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 20),
                            ],
                          ),
                        ),
                      );
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

  Widget _stashBtn(IconData icon, VoidCallback onTap, PremiumColors colors) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: colors.textPrimary),
      ),
    );
  }

  void _deleteSession(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _milkStash -= (_sessions[index]['amount_ml'] as num?)?.toDouble() ?? 0;
              if (_milkStash < 0) _milkStash = 0;
              _sessions.removeAt(index);
              _saveData();
              Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
