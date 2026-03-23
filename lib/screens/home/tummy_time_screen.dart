import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../../services/local_storage_service.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/care_repository.dart';
import '../../widgets/premium_ui_components.dart';
import '../../widgets/tummy_time/timer_card.dart';
import '../../widgets/tummy_time/weekly_chart.dart';
import '../../widgets/tummy_time/session_list.dart';

class TummyTimeScreen extends StatefulWidget {
  const TummyTimeScreen({super.key});

  @override
  State<TummyTimeScreen> createState() => _TummyTimeScreenState();
}

class _TummyTimeScreenState extends State<TummyTimeScreen> {
  List<Map<String, dynamic>> _sessions = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  int _dailyGoalMin = 30;
  bool _isLoading = true;

  // Timer
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  bool _isTimerRunning = false;

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

  Future<void> _loadData() async {
    final ss = context.read<CareRepository>();
    final ls = context.read<LocalStorageService>();
    
    final data = (await ss.getTummyTimeSessions()).data ?? [];
    _dailyGoalMin = int.tryParse(ls.getString('tummy_goal') ?? '30') ?? 30;
    
    if (mounted) {
      setState(() {
        _sessions = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSession(int durSec) async {
    final user = context.read<AuthRepository>().currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in'), backgroundColor: Colors.red));
      return;
    }
    final ss = context.read<CareRepository>();
    final newSession = {
      'user_id': user.id,
      'duration_sec': durSec,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Optimistic UI update
    _sessions.insert(0, newSession);
    _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 500));
    
    final result = await ss.saveTummyTimeSession(newSession);
    if (!result.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to save'), backgroundColor: Colors.red));
    }
    _loadData(); // Refresh to get proper IDs and dates
  }

  Future<void> _updateGoal(int goal) async {
    final ls = context.read<LocalStorageService>();
    await ls.saveString('tummy_goal', goal.toString());
    setState(() => _dailyGoalMin = goal);
  }

  void _toggleTimer() {
    setState(() {
      if (_isTimerRunning) {
        _stopwatch.stop();
        _isTimerRunning = false;
        _uiTimer?.cancel();
        // Auto-save session
        final durSec = _stopwatch.elapsed.inSeconds;
        if (durSec > 0) {
          _saveSession(durSec);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tummy time saved! 🎉')));
        }
        _stopwatch.reset();
      } else {
        _stopwatch.reset();
        _stopwatch.start();
        _isTimerRunning = true;
        _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
      }
    });
  }

  String _formatElapsed() {
    final e = _stopwatch.elapsed;
    final m = (e.inMinutes % 60).toString().padLeft(2, '0');
    final s = (e.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int get _todayTotalSec {
    final now = DateTime.now();
    return _sessions.where((s) {
      try {
        final d = DateTime.parse(s['timestamp']);
        return d.year == now.year && d.month == now.month && d.day == now.day;
      } catch (_) { return false; }
    }).fold<int>(0, (sum, s) => sum + (s['duration_sec'] as int? ?? 0));
  }

  double get _todayProgress {
    final totalMin = _todayTotalSec / 60.0;
    return (totalMin / _dailyGoalMin).clamp(0.0, 1.0);
  }

  // Weekly data for bar chart
  List<int> get _weeklyData {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return _sessions.where((s) {
        try {
          final d = DateTime.parse(s['timestamp']);
          return d.year == day.year && d.month == day.month && d.day == day.day;
        } catch (_) { return false; }
      }).fold<int>(0, (sum, s) => sum + (s['duration_sec'] as int? ?? 0));
    });
  }


  @override
  Widget build(BuildContext context) {
    final typo = PremiumTypography(context);

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Tummy Time', style: typo.h2),
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
                  TummyTimeTimerCard(
                    isTimerRunning: _isTimerRunning,
                    formattedTime: _formatElapsed(),
                    todayProgress: _todayProgress,
                    todayMin: _todayTotalSec / 60.0,
                    dailyGoalMin: _dailyGoalMin,
                    onToggleTimer: _toggleTimer,
                    onEditGoal: _showGoalDialog,
                  ),
                  const SizedBox(height: 24),

                  TummyTimeWeeklyChart(
                    weeklyData: _weeklyData,
                    dailyGoalMin: _dailyGoalMin,
                  ),
                  const SizedBox(height: 24),

                  TummyTimeSessionList(
                    sessions: _sessions,
                    listKey: _listKey,
                    onDeleteSession: _deleteSession,
                    isLoading: _isLoading,
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

  void _showGoalDialog() {
    int tempGoal = _dailyGoalMin;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Daily Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$tempGoal minutes', style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800)),
              Slider(
                value: tempGoal.toDouble(),
                min: 5, max: 120, divisions: 23,
                activeColor: PremiumColors(context).softAmber,
                onChanged: (v) => setD(() => tempGoal = v.toInt()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                _updateGoal(tempGoal);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
            onPressed: () async {
              final item = _sessions[index];
              final ss = context.read<CareRepository>();
              
              // Animated removal
              _listKey.currentState?.removeItem(
                index,
                (context, animation) => TummyTimeSessionList.buildSessionTile(
                  item, index, animation, PremiumColors(context), PremiumTypography(context), () {}
                ),
                duration: const Duration(milliseconds: 300),
              );
              _sessions.removeAt(index);
              
              if (item['id'] != null) {
                await ss.deleteTummyTimeSession(item['id']);
              }
              
              if (mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
