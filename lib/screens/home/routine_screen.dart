import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/routine_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/care_repository.dart';
import '../../widgets/premium_ui_components.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  List<Routine> _routines = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchRoutines();
  }

  Future<void> _fetchRoutines() async {
    setState(() => _isLoading = true);

    final service = context.read<CareRepository>();
    final data = (await service.getRoutines()).data ?? [];
    setState(() {
      _routines = data.map((e) => Routine.fromJson(e)).toList();
      _isLoading = false;
    });
    // Note: Ad wall is handled by Dashboard navigation
  }

  Future<void> _addRoutine() async {
    final titleController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Add Routine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Activity Name (e.g. Bath)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Time: '),
                  TextButton(
                    onPressed: () async {
                      final picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) {
                        setStateDialog(() => selectedTime = picked);
                      }
                    },
                    child: Text(selectedTime.format(context)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            TextButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                
                final user = context.read<AuthRepository>().currentUser;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in'), backgroundColor: Colors.red));
                  return;
                }

                final newRoutine = Routine(
                  id: Uuid().v4(),
                  userId: user.id,
                  title: titleController.text,
                  time: selectedTime,
                  enabled: true,
                  createdAt: DateTime.now(),
                );
                
                final service = context.read<CareRepository>();
                final result = await service.saveRoutine(newRoutine.toJson());
                if (result.isSuccess) {
                  _fetchRoutines();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Routine saved!')));
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to save'), backgroundColor: Colors.red));
                }
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      
      appBar: AppBar(
        title: Text('Routine Scheduler', style: PremiumTypography(context).h2),
        backgroundColor: PremiumColors(context).surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: PremiumColors(context).warmPeach))
          : _routines.isEmpty 
              ? Center(child: TextButton.icon(onPressed: _addRoutine, icon: Icon(Icons.add_rounded, color: PremiumColors(context).warmPeach), label: Text("Add your first routine", style: PremiumTypography(context).body)))
              : TweenAnimationBuilder<double>(
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
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _routines.length,
                    itemBuilder: (context, index) {
                      final routine = _routines[index];
                      final isLast = index == _routines.length - 1;
                      
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline
                          Column(
                            children: [
                              Text(
                                routine.time.format(context),
                                style: TextStyle(fontWeight: FontWeight.bold, color: PremiumColors(context).textSecondary),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 50,
                                  color: PremiumColors(context).warmPeach.withValues(alpha: 0.3),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Content
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: DataTile(
                                onTap: () => _showOptions(routine),
                                backgroundColor: PremiumColors(context).surface,
                                child: Row(
                                  children: [
                                    PremiumBubbleIcon(icon: _getIconForTitle(routine.title), color: PremiumColors(context).warmPeach, size: 24, padding: 12),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        routine.title,
                                        style: PremiumTypography(context).title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.more_vert_rounded, color: PremiumColors(context).textSecondary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRoutine,
        label: Text('Add Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: Icon(Icons.add_rounded, color: Colors.white),
        backgroundColor: PremiumColors(context).warmPeach,
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('bath')) return Icons.bathtub_rounded;
    if (t.contains('massage')) return Icons.spa_rounded;
    if (t.contains('vaccine') || t.contains('doctor')) return Icons.local_hospital_rounded;
    if (t.contains('feed') || t.contains('food')) return Icons.restaurant_rounded;
    if (t.contains('sleep') || t.contains('nap')) return Icons.bedtime_rounded;
    return Icons.event_rounded;
  }

  void _showOptions(Routine routine) {
      showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      ListTile(
                          leading: Icon(Icons.edit, color: Colors.blue),
                          title: Text('Edit'),
                          onTap: () {
                              Navigator.pop(context);
                              _editRoutine(routine);
                          },
                      ),
                      ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete Routine'),
                          onTap: () async {
                              Navigator.pop(context);
                              await context.read<CareRepository>().deleteRoutine(routine.id);
                              _fetchRoutines();
                          },
                      ),
                  ],
              ),
          ),
      );
  }

  void _editRoutine(Routine routine) {
      final titleController = TextEditingController(text: routine.title);
      TimeOfDay selectedTime = routine.time;

      showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
              builder: (context, setStateDialog) => AlertDialog(
                  title: Text('Edit Routine'),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          TextField(
                              controller: titleController,
                              decoration: const InputDecoration(labelText: 'Activity Name'),
                          ),
                          const SizedBox(height: 16),
                          Row(
                              children: [
                                  Text('Time: '),
                                  TextButton(
                                      onPressed: () async {
                                          final picked = await showTimePicker(context: context, initialTime: selectedTime);
                                          if (picked != null) {
                                              setStateDialog(() => selectedTime = picked);
                                          }
                                      },
                                      child: Text(selectedTime.format(context)),
                                  ),
                              ],
                          ),
                      ],
                  ),
                  actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                      TextButton(
                          onPressed: () async {
                              if (titleController.text.isNotEmpty) {
                                  final updates = {
                                      'title': titleController.text,
                                      'time': '${selectedTime.hour.toString().padLeft(2,'0')}:${selectedTime.minute.toString().padLeft(2,'0')}:00', 
                                  };
                                  await context.read<CareRepository>().updateRoutine(routine.id, updates);
                                  _fetchRoutines();
                                  Navigator.pop(context);
                              }
                          }, 
                          child: Text('Save'),
                      )
                  ],
              ),
          ),
      );
  }
}
