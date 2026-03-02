import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../../services/supabase_service.dart';
import '../../models/sleep_model.dart';
import '../../widgets/premium_ui_components.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  DateTime? _startTime;
  Timer? _timer;
  Duration _duration = Duration.zero;
  bool _isSleeping = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleSleep() async {
    if (_isSleeping) {
      // Stop Sleep
      _timer?.cancel();
      await _saveSleepLog();
      setState(() {
        _isSleeping = false;
        _startTime = null;
        _duration = Duration.zero;
      });
    } else {
      // Start Sleep
      setState(() {
        _isSleeping = true;
        _startTime = DateTime.now();
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _duration = DateTime.now().difference(_startTime!);
        });
      });
    }
  }

  Future<void> _saveSleepLog() async {
    setState(() => _isLoading = true);
    final supabaseService = context.read<SupabaseService>();
    final user = supabaseService.currentUser;

    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in')));
      setState(() => _isLoading = false);
      return;
    }

    // Capture values before async gap
    final startTime = _startTime!;
    final endTime = DateTime.now();

    final log = SleepLog(
      id: Uuid().v4(),
      userId: user.id,
      startTime: startTime,
      endTime: endTime,
      createdAt: DateTime.now(),
    );

    // Save using raw insert for now since service method might need update or generic usage
    // Using the service placeholder method or extending it
    try {
        await supabaseService.saveSleepLog(log.toJson()); // We need to add this method to service
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sleep Logged!')));
    } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => _isLoading = false);
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumScaffold(
      
      appBar: AppBar(
        title: Text('Sleep Tracker', style: PremiumTypography(context).h2),
        backgroundColor: PremiumColors(context).surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: _isSleeping ? PremiumColors(context).sereneBlue.withValues(alpha: 0.15) : PremiumColors(context).softAmber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  )
                ]
              ),
              child: Icon(
                _isSleeping ? Icons.bedtime_rounded : Icons.wb_sunny_rounded,
                size: 100,
                color: _isSleeping ? PremiumColors(context).sereneBlue : PremiumColors(context).softAmber,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _isSleeping ? 'Baby is Sleeping' : 'Baby is Awake',
              style: PremiumTypography(context).h2,
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _formatDuration(_duration),
                style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: PremiumColors(context).textPrimary, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
            const SizedBox(height: 48),
            if (_isLoading)
               CircularProgressIndicator(color: PremiumColors(context).sereneBlue)
            else
              Column(
                children: [
                  PremiumActionButton(
                    label: _isSleeping ? 'Wake Up' : 'Start Sleep',
                    icon: _isSleeping ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: _isSleeping ? PremiumColors(context).warmPeach : PremiumColors(context).sereneBlue,
                    onTap: _toggleSleep,
                  ),
                  const SizedBox(height: 24),
                  if (!_isSleeping)
                    TextButton.icon(
                      onPressed: _addManualLog,
                      icon: Icon(Icons.edit_calendar_rounded, color: PremiumColors(context).textSecondary),
                      label: Text('Log Past Sleep Manually', style: PremiumTypography(context).body),
                    )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addManualLog() async {
    final now = DateTime.now();
    final DateTime? startDate = await showDatePicker(context: context, initialDate: now, firstDate: now.subtract(const Duration(days: 7)), lastDate: now);
    if (startDate == null) return;
    
    final TimeOfDay? startTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
    if (startTime == null) return;

    final TimeOfDay? endTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 7, minute: 0));
    if (endTime == null) return;

    // Construct DateTime objects (Local)
    final startLocal = DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute);
    var endLocal = DateTime(startDate.year, startDate.month, startDate.day, endTime.hour, endTime.minute);
    
    // Handle overnight sleep (if end time is before start time, assume next day)
    if (endLocal.isBefore(startLocal)) {
        endLocal = endLocal.add(const Duration(days: 1));
    }

    setState(() => _isLoading = true);
    final supabaseService = context.read<SupabaseService>();
    final user = supabaseService.currentUser;

    if (user != null) {
        final log = SleepLog(
          id: Uuid().v4(),
          userId: user.id,
          startTime: startLocal.toUtc(), // Fix: Force UTC
          endTime: endLocal.toUtc(),     // Fix: Force UTC
          createdAt: DateTime.now().toUtc(),
        );

        await supabaseService.saveSleepLog(log.toJson()); // Model needs to be checked if it double-converts?
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manual Sleep Saved!')));
    }
    setState(() => _isLoading = false);
  }
}
