import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/sleep_viewmodel.dart';
import '../../widgets/premium_ui_components.dart';
import '../../widgets/sleep/sleep_orb_button.dart';

class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  Future<void> _addManualLog(BuildContext context, SleepViewModel vm) async {
    final now = DateTime.now();
    final DateTime? startDate = await showDatePicker(context: context, initialDate: now, firstDate: now.subtract(const Duration(days: 7)), lastDate: now);
    if (startDate == null) return;
    
    if (!context.mounted) return;
    final TimeOfDay? startTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 20, minute: 0));
    if (startTime == null) return;

    if (!context.mounted) return;
    final TimeOfDay? endTime = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 7, minute: 0));
    if (endTime == null) return;

    final startLocal = DateTime(startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute);
    var endLocal = DateTime(startDate.year, startDate.month, startDate.day, endTime.hour, endTime.minute);
    
    if (endLocal.isBefore(startLocal)) {
        endLocal = endLocal.add(const Duration(days: 1));
    }

    final success = await vm.saveManualLog(startLocal, endLocal);
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manual Sleep Saved!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SleepViewModel>();

    return PremiumScaffold(
      appBar: AppBar(
        title: const Text('Sleep Tracker'),
        backgroundColor: PremiumColors(context).surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
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
              // Ultra Premium Glowing Sleep Orb
              SleepOrbButton(
                isSleeping: vm.isSleeping,
                onToggle: () async {
                  final success = await vm.toggleSleep();
                  if (success && !vm.isSleeping && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sleep Logged!')));
                  }
                },
              ),
              const SizedBox(height: 48),
              
              Text(
                vm.isSleeping ? 'Baby is Sleeping' : 'Baby is Awake',
                style: PremiumTypography(context).h2,
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  vm.formattedDuration,
                  style: TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: vm.isSleeping ? PremiumColors(context).sereneBlue : PremiumColors(context).textPrimary, fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
              const SizedBox(height: 48),
              
              if (vm.isLoading)
                 CircularProgressIndicator(color: PremiumColors(context).sereneBlue)
              else if (!vm.isSleeping)
                 Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    child: PremiumActionButton(
                      label: 'Log Past Sleep Manually',
                      icon: Icons.edit_calendar_rounded,
                      color: PremiumColors(context).textSecondary,
                      onTap: () => _addManualLog(context, vm),
                    ),
                 )
            ],
          ),
        ),
      ),
    ),
    );
  }
}
