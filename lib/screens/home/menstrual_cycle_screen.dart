import 'package:flutter/material.dart';
import '../../widgets/premium_ui_components.dart';
import '../../repositories/care_repository.dart';
import '../../repositories/auth_repository.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class MenstrualCycleScreen extends StatefulWidget {
  const MenstrualCycleScreen({super.key});

  @override
  State<MenstrualCycleScreen> createState() => _MenstrualCycleScreenState();
}

class _MenstrualCycleScreenState extends State<MenstrualCycleScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cycles = [];
  int _averageCycleLength = 28; // Default

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final res = await context.read<CareRepository>().getMenstrualCycles();
    if (res.isSuccess && res.data != null) {
        _cycles = res.data!;
    }
    
    _calculateAverages();
    setState(() => _isLoading = false);
  }

  void _calculateAverages() {
    if (_cycles.length >= 2) {
       // Sort descending
       final sorted = List<Map<String, dynamic>>.from(_cycles);
       sorted.sort((a,b) => DateTime.parse(b['start_date']).compareTo(DateTime.parse(a['start_date'])));
       
       int totalDays = 0;
       int pairs = 0;
       
       for (int i = 0; i < sorted.length - 1; i++) {
           final curr = DateTime.parse(sorted[i]['start_date']);
           final prev = DateTime.parse(sorted[i+1]['start_date']);
           final diff = curr.difference(prev).inDays;
           if (diff > 15 && diff < 60) { // Sane limits
               totalDays += diff;
               pairs++;
           }
       }
       
       if (pairs > 0) {
           _averageCycleLength = (totalDays / pairs).round();
       }
    }
  }

  void _logPeriodStatus() {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    // Check if there is an active period (start but no end, or ended very recently)
    // For simplicity, we just prompt to log a new start date or end date for the most recent
    
    if (_cycles.isEmpty || _cycles.first['end_date'] != null) {
        // Log new start
        _selectDateAndLog(true);
    } else {
        // End current
       _selectDateAndLog(false);
    }
  }

  Future<void> _selectDateAndLog(bool isStart) async {
      final now = DateTime.now();
      final initial = _cycles.isNotEmpty && !isStart 
          ? DateTime.parse(_cycles.first['start_date']) 
          : now;

      final selected = await showDatePicker(
          context: context, 
          initialDate: initial, 
          firstDate: now.subtract(const Duration(days: 90)), 
          lastDate: now
      );
      
      if (selected == null) return;
      
      if (isStart) {
          final user = context.read<AuthRepository>().currentUser;
          if (user == null) return;
          
          final newItem = {
              'id': const Uuid().v4(),
              'user_id': user.id,
              'start_date': selected.toIso8601String(),
              'end_date': null,
              'notes': '',
              'created_at': DateTime.now().toUtc().toIso8601String()
          };
          setState(() {
              _cycles.insert(0, newItem);
              _cycles.sort((a,b) => DateTime.parse(b['start_date']).compareTo(DateTime.parse(a['start_date'])));
          });
          final result = await context.read<CareRepository>().saveMenstrualCycle(newItem);
          if (!result.isSuccess && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to save cycle'), backgroundColor: Colors.red));
          }
      } else {
          if (_cycles.isNotEmpty) {
              final id = _cycles.first['id'];
              setState(() {
                  _cycles.first['end_date'] = selected.toIso8601String();
              });
              final result = await context.read<CareRepository>().updateMenstrualCycle(id, {'end_date': selected.toIso8601String()});
              if (!result.isSuccess && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to update cycle'), backgroundColor: Colors.red));
              }
          }
      }
      _calculateAverages();
  }
  
  void _editCycle(int index) {
      final cycle = _cycles[index];
      DateTime start = DateTime.parse(cycle['start_date']);
      DateTime? end = cycle['end_date'] != null ? DateTime.parse(cycle['end_date']) : null;
      
      showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                  backgroundColor: PremiumColors(context).surface,
                  title: Text("Edit Cycle", style: PremiumTypography(context).h2),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          ListTile(
                              title: const Text("Start Date"),
                              trailing: Text(DateFormat('MMM d, y').format(start)),
                              onTap: () async {
                                  final d = await showDatePicker(context: context, initialDate: start, firstDate: DateTime(2023), lastDate: DateTime.now());
                                  if (d != null) setDialogState(() => start = d);
                              },
                          ),
                          ListTile(
                              title: const Text("End Date"),
                              trailing: Text(end != null ? DateFormat('MMM d, y').format(end!) : 'Ongoing'),
                              onTap: () async {
                                  final d = await showDatePicker(context: context, initialDate: end ?? DateTime.now(), firstDate: start, lastDate: DateTime.now());
                                  if (d != null) setDialogState(() => end = d);
                              },
                          ),
                          TextButton(
                              onPressed: () { setDialogState(() => end = null); },
                              child: const Text("Mark as Ongoing")
                          )
                      ],
                  ),
                  actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                      TextButton(
                         onPressed: () {
                             setState(() {
                                 _cycles[index]['start_date'] = start.toIso8601String();
                                 _cycles[index]['end_date'] = end?.toIso8601String();
                             });
                             context.read<CareRepository>().updateMenstrualCycle(cycle['id'], {
                                 'start_date': start.toIso8601String(),
                                 'end_date': end?.toIso8601String()
                             });
                             _calculateAverages();
                             Navigator.pop(context);
                         }, 
                         child: const Text("Save")
                      )
                  ],
              )
          )
      );
  }

  void _deleteCycle(int index) {
      final id = _cycles[index]['id'];
      setState(() {
          _cycles.removeAt(index);
      });
      context.read<CareRepository>().deleteMenstrualCycle(id);
      _calculateAverages();
  }

  Map<String, dynamic> _getPrediction() {
      if (_cycles.isEmpty) return {'day': 0, 'next': null, 'status': 'No data'};
      
      final latest = DateTime.parse(_cycles.first['start_date']);
      final now = DateTime.now();
      final currentDay = now.difference(latest).inDays + 1; // Day 1 is start date
      
      final nextPeriod = latest.add(Duration(days: _averageCycleLength));
      final daysUntilNext = nextPeriod.difference(now).inDays;
      
      String status = "";
      bool isPeriod = _cycles.first['end_date'] == null;
      
      if (isPeriod) {
          status = "Period (Day $currentDay)";
      } else if (daysUntilNext < 0) {
          status = "Period is late by ${daysUntilNext.abs()} days";
      } else if (daysUntilNext <= 3) {
          status = "Period expected soon ($daysUntilNext days)";
      } else {
           // Basic fertile window prediction (14 days before next period)
           final ovulation = nextPeriod.subtract(const Duration(days: 14));
           final diffOvu = ovulation.difference(now).inDays;
           if (diffOvu >= -2 && diffOvu <= 2) {
               status = "Fertile Window";
           } else {
               status = "Cycle Day $currentDay";
           }
      }
      
      return {
          'day': currentDay,
          'next': nextPeriod,
          'daysUntil': daysUntilNext,
          'status': status,
          'isPeriod': isPeriod
      };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
        return PremiumScaffold(
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: const Center(child: CircularProgressIndicator()),
        );
    }
    
    final prediction = _getPrediction();
    final isPeriod = prediction['isPeriod'] == true;
    final statusColor = isPeriod ? const Color(0xFFE8A0A0) : PremiumColors(context).sereneBlue;

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Cycle Tracker', style: PremiumTypography(context).h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          children: [
             // Dynamic Core Dashboard
             TweenAnimationBuilder<double>(
                 tween: Tween(begin: 0.0, end: 1.0),
                 duration: const Duration(milliseconds: 800),
                 builder: (context, value, child) => Transform.scale(
                     scale: 0.9 + (0.1 * value),
                     child: Opacity(opacity: value, child: child),
                 ),
                 child: Container(
                     width: double.infinity,
                     padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                     decoration: BoxDecoration(
                         gradient: LinearGradient(
                             colors: [statusColor.withValues(alpha: 0.8), statusColor],
                             begin: Alignment.topLeft,
                             end: Alignment.bottomRight,
                         ),
                         borderRadius: BorderRadius.circular(40),
                         boxShadow: [
                             BoxShadow(color: statusColor.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8))
                         ]
                     ),
                     child: Column(
                         children: [
                             Text(prediction['status'], style: PremiumTypography(context).h2.copyWith(color: Colors.white, fontSize: 28), textAlign: TextAlign.center),
                             if (prediction['next'] != null) ...[
                                 const SizedBox(height: 12),
                                 Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                     decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                                     child: Text(
                                         "Next predicted: ${DateFormat('MMM d').format(prediction['next'])}", 
                                         style: PremiumTypography(context).bodyBold.copyWith(color: Colors.white)
                                     ),
                                 )
                             ]
                         ],
                     ),
                 ),
             ),
             
             const SizedBox(height: 32),
             
             // Primary Action
             Row(
                children: [
                    Expanded(
                        child: PremiumActionButton(
                            label: isPeriod ? 'Log Period End' : 'Log Period Start',
                            icon: Icons.water_drop_rounded,
                            color: const Color(0xFFE8A0A0),
                            onTap: _logPeriodStatus,
                        )
                    )
                ],
             ),
             
             const SizedBox(height: 48),
             
             // History
             Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                     Text('Cycle History', style: PremiumTypography(context).h2),
                     Text('Avg: $_averageCycleLength days', style: PremiumTypography(context).caption),
                 ],
             ),
             const SizedBox(height: 16),
             
             if (_cycles.isEmpty)
                Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text("No cycles logged yet.", style: PremiumTypography(context).body, textAlign: TextAlign.center),
                )
             else
                ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cycles.length,
                    itemBuilder: (context, index) {
                        final c = _cycles[index];
                        final start = DateTime.parse(c['start_date']);
                        final end = c['end_date'] != null ? DateTime.parse(c['end_date']) : null;
                        
                        String durationStr = "Ongoing";
                        if (end != null) {
                            durationStr = "${end.difference(start).inDays + 1} days";
                        }
                        
                        // Calculate cycle length if there's a previous cycle
                        String cycleLengthStr = "";
                        if (index < _cycles.length - 1) {
                             final prevStart = DateTime.parse(_cycles[index+1]['start_date']);
                             final len = start.difference(prevStart).inDays;
                             cycleLengthStr = " • $len day cycle";
                        }

                        return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DataTile(
                                backgroundColor: PremiumColors(context).surfaceMuted,
                                onTap: () => _editCycle(index),
                                child: Row(
                                    children: [
                                        PremiumBubbleIcon(icon: Icons.calendar_month_rounded, color: const Color(0xFFE8A0A0), size: 24, padding: 12),
                                        const SizedBox(width: 16),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                    Text(DateFormat('MMMM d, yyyy').format(start), style: PremiumTypography(context).bodyBold),
                                                    const SizedBox(height: 4),
                                                    Text("Period: $durationStr$cycleLengthStr", style: PremiumTypography(context).caption),
                                                ]
                                            )
                                        ),
                                        IconButton(
                                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                            onPressed: () => _deleteCycle(index)
                                        )
                                    ],
                                ),
                            )
                        );
                    }
                ),
          ]
        ),
      ),
    );
  }
}
