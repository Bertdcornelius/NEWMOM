import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/local_storage_service.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/care_repository.dart';
import '../../viewmodels/tracker_viewmodels.dart';
import '../../widgets/premium_ui_components.dart';

class PumpingTrackerScreen extends StatelessWidget {
  const PumpingTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PumpingViewModel(context.read<CareRepository>()),
      child: const _PumpingTrackerScreenView(),
    );
  }
}

class _PumpingTrackerScreenView extends StatefulWidget {
  const _PumpingTrackerScreenView();

  @override
  State<_PumpingTrackerScreenView> createState() => _PumpingTrackerScreenViewState();
}

class _PumpingTrackerScreenViewState extends State<_PumpingTrackerScreenView> {
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
    _loadLocalStash();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _uiTimer?.cancel();
    super.dispose();
  }

  void _loadLocalStash() {
    final ls = context.read<LocalStorageService>();
    setState(() {
      _milkStash = double.tryParse(ls.getString('milk_stash') ?? '0') ?? 0;
    });
  }

  Future<void> _updateStash(double amount) async {
    final ls = context.read<LocalStorageService>();
    setState(() => _milkStash = amount);
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

  Future<void> _onSaveSessionPressed() async {
    final user = context.read<AuthRepository>().currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in'), backgroundColor: Colors.red));
      return;
    }

    final durationMin = _stopwatch.elapsed.inMinutes.clamp(1, 120);
    _milkStash += _amountMl;
    _stopwatch.stop();
    _stopwatch.reset();
    _isTimerRunning = false;
    _uiTimer?.cancel();
    
    final newSession = {
      'user_id': user.id,
      'side': _selectedSide,
      'duration_min': durationMin,
      'amount_ml': _amountMl,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    final vm = context.read<PumpingViewModel>();
    final success = await vm.saveEntry(newSession);
    
    if (mounted) {
      _updateStash(_milkStash);
      setState(() {});
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pump session saved! 🍼')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Failed to log pump session'), backgroundColor: Colors.red));
        vm.clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PumpingViewModel>();
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    // Global error listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (vm.errorMessage != null && !vm.errorMessage!.contains('save') && !vm.errorMessage!.contains('delete')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage!), backgroundColor: Colors.red));
        vm.clearError();
      }
    });

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
                              _updateStash(_milkStash);
                            }, colors),
                            const SizedBox(width: 8),
                            _stashBtn(Icons.add, () {
                              setState(() { _milkStash += 30; });
                              _updateStash(_milkStash);
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
                                  ),
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
                            onTap: _onSaveSessionPressed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // History
                  Text('Session History', style: typo.h2),
                  const SizedBox(height: 12),

                  if (vm.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (vm.entries.isEmpty)
                    PremiumCard(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('No sessions yet', style: typo.body)),
                    ))
                  else
                    Column(
                      children: List.generate(
                        vm.entries.length > 15 ? 15 : vm.entries.length,
                        (index) {
                          final s = vm.entries[index];
                          return _buildSessionTile(context, s, vm, colors, typo);
                        }
                      ),
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

  void _deleteSession(BuildContext context, Map<String, dynamic> item, PumpingViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session?'),
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
                  } else {
                     setState(() {
                       _milkStash -= (item['amount_ml'] as num?)?.toDouble() ?? 0;
                       if (_milkStash < 0) _milkStash = 0;
                     });
                     _updateStash(_milkStash);
                  }
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(BuildContext context, Map<String, dynamic> s, PumpingViewModel vm, PremiumColors colors, PremiumTypography typo) {
    String dateStr = s['date'] ?? '';
    if (dateStr.isEmpty && s['timestamp'] != null) {
      dateStr = DateFormat('MMM d, h:mm a').format(DateTime.parse(s['timestamp']).toLocal());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DataTile(
        onTap: () => _deleteSession(context, s, vm),
        child: Row(
          children: [
            PremiumBubbleIcon(icon: Icons.water_drop_outlined, color: colors.gentlePurple, size: 20, padding: 10),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s['side']} • ${s['duration_min']} min • ${s['amount_ml']} ml',
                    style: typo.bodyBold),
                Text(dateStr, style: typo.caption),
              ],
            )),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
