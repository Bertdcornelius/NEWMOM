import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../widgets/premium_ui_components.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _groupedLogs = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final service = context.read<SupabaseService>();
    final feeds = await service.getFeeds();
    final sleeps = await service.getSleepLogs();
    final diapers = await service.getDiaperLogs();
    
    // 1. Unify and Tag
    final List<Map<String, dynamic>> allLogs = [];
    
    for (var f in feeds) {
      final Map<String, dynamic> item = Map.from(f);
      item['data_type'] = 'feed';
      // Robust UTC -> Local conversion
      // Assuming Supabase returns ISO strings. If 'Z' is missing, append it to force UTC interpretation, then convert to Local.
      var createdStr = f['created_at'].toString();
      if (!createdStr.endsWith('Z') && !createdStr.contains('+')) createdStr += 'Z';
      item['sort_time'] = DateTime.parse(createdStr).toLocal();
      allLogs.add(item);
    }
    
    for (var s in sleeps) {
      final Map<String, dynamic> item = Map.from(s);
      item['data_type'] = 'sleep';
      var startStr = s['start_time'].toString();
      if (!startStr.endsWith('Z') && !startStr.contains('+')) startStr += 'Z';
      item['sort_time'] = DateTime.parse(startStr).toLocal();
      allLogs.add(item);
    }

    for (var d in diapers) {
      final Map<String, dynamic> item = Map.from(d);
      item['data_type'] = 'diaper';
      var createdStr = d['created_at'].toString();
      if (!createdStr.endsWith('Z') && !createdStr.contains('+')) createdStr += 'Z';
      item['sort_time'] = DateTime.parse(createdStr).toLocal();
      allLogs.add(item);
    }

    // 2. Sort Descending
    allLogs.sort((a, b) => b['sort_time'].compareTo(a['sort_time']));

    // 3. Group by Day
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var log in allLogs) {
      final date = log['sort_time'] as DateTime;
      final key = DateFormat('yyyy-MM-dd').format(date);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(log);
    }

    if (mounted) {
      setState(() {
        _groupedLogs = grouped;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String id, String type) async {
      final service = context.read<SupabaseService>();
      if (type == 'feed') {
          await service.deleteFeed(id);
      } else if (type == 'sleep') {
          await service.deleteSleepLog(id);
      } else if (type == 'diaper') {
          await service.deleteDiaperLog(id);
      }
      _loadData(); // This should trigger a refresh
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleted")));
  }

  void _confirmDelete(String id, String type) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              title: Text("Delete Entry"),
              content: Text("Are you sure?"),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                  TextButton(
                      onPressed: () {
                          Navigator.pop(context);
                          _deleteItem(id, type);
                      }, 
                      child: Text("Delete", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.redAccent : Colors.red))
                  ),
              ],
          ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Sort keys (dates) descending
    final sortedKeys = _groupedLogs.keys.toList()..sort((a, b) => b.compareTo(a));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumScaffold(
      
      appBar: AppBar(
        title: Text("History", style: PremiumTypography(context).h2),
        backgroundColor: PremiumColors(context).surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : sortedKeys.isEmpty 
          ? Center(child: Text("No history logs found.", style: PremiumTypography(context).body))
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
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                    final dateKey = sortedKeys[index];
                  final logs = _groupedLogs[dateKey]!;
                  final dateTitle = DateFormat('EEEE, MMM d, y').format(DateTime.parse(dateKey));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: PremiumColors(context).surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    ),
                    child: ExpansionTile(
                      initiallyExpanded: index == 0, // Expand today/first day by default
                      shape: const Border(), // Remove default borders
                      title: Text(dateTitle, style: PremiumTypography(context).title),
                      leading: PremiumBubbleIcon(icon: Icons.calendar_today_rounded, color: PremiumColors(context).textSecondary, size: 20, padding: 8),
                      childrenPadding: const EdgeInsets.all(12),
                      children: logs.map((log) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildLogTile(log),
                      )).toList(),
                    ),
                  );
              },
            ),
          ),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> log) {
      final dataType = log['data_type'];
      final time = log['sort_time'] as DateTime;
      
      if (dataType == 'feed') {
         final type = log['type'];
         String details = "";
         if (type == 'breast') details = "${log['side']} side, ${log['duration_min']} min";
         if (type == 'bottle') details = "${log['amount_ml']} ml";
         if (type == 'solid') details = "Solid: ${log['notes'] ?? 'Food'}";

         return DataTile(
            onTap: () => _showOptions(log),
            backgroundColor: PremiumColors(context).surfaceMuted,
            child: Row(
              children: [
                PremiumBubbleIcon(icon: Icons.restaurant_rounded, color: PremiumColors(context).warmPeach, size: 22, padding: 10),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${type.toString().toUpperCase()} - ${DateFormat('h:mm a').format(time)}", style: PremiumTypography(context).bodyBold),
                      const SizedBox(height: 2),
                      Text(details, style: PremiumTypography(context).caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
         );
      } else if (dataType == 'sleep') {
         final start = time;
         final end = log['end_time'] != null ? DateTime.parse(log['end_time']) : null;
         final duration = end?.difference(start);

         return DataTile(
            onTap: () => _showOptions(log),
            backgroundColor: PremiumColors(context).surfaceMuted,
            child: Row(
              children: [
                PremiumBubbleIcon(icon: Icons.bedtime_rounded, color: PremiumColors(context).sereneBlue, size: 22, padding: 10),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("SLEEP - ${DateFormat('h:mm a').format(start)}", style: PremiumTypography(context).bodyBold),
                      const SizedBox(height: 2),
                      Text(end == null ? "Running..." : "Slept for ${_formatDuration(duration!)}", style: PremiumTypography(context).caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
         );
      } else {
         final type = log['type']; 
         String emoji = "❓";
         if (type == 'pee') emoji = "💧 Pee";
         if (type == 'poop') emoji = "💩 Poop";
         if (type == 'both') emoji = "🤢 Both";

         return DataTile(
             onTap: () => _showOptions(log),
             backgroundColor: PremiumColors(context).surfaceMuted,
             child: Row(
               children: [
                 PremiumBubbleIcon(icon: Icons.child_care_rounded, color: PremiumColors(context).sageGreen, size: 22, padding: 10),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text("$emoji - ${DateFormat('h:mm a').format(time)}", style: PremiumTypography(context).bodyBold),
                       const SizedBox(height: 2),
                       if (log['notes'] != null && log['notes'].toString().isNotEmpty)
                         Text(log['notes'], style: PremiumTypography(context).caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                     ],
                   ),
                 ),
               ],
             ),
         );
      }
  }

  void _showOptions(Map<String, dynamic> log) {
      final id = log['id'];
      final type = log['data_type'];
      
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
                              if (type == 'feed') {
                                  _editFeed(log);
                              } else if (type == 'sleep') {
                                  _editSleep(log);
                              } else if (type == 'diaper') {
                                  _editDiaper(log);
                              }
                          },
                      ),
                      ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete'),
                          onTap: () {
                              Navigator.pop(context);
                              _confirmDelete(id, type);
                          },
                      ),
                  ],
              ),
          ),
      );
  }

  void _editFeed(Map<String, dynamic> log) {
      DateTime selectedDate = log['sort_time'];
      final durationController = TextEditingController(text: log['duration_min']?.toString() ?? '');
      final amountController = TextEditingController(text: log['amount_ml']?.toString() ?? '');
      final type = log['type'];

      showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                  title: Text("Edit $type Feed"),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          _buildDateRow("Date", selectedDate, (d) {
                              setDialogState(() => selectedDate = DateTime(d.year, d.month, d.day, selectedDate.hour, selectedDate.minute));
                          }),
                          _buildTimeRow("Time", selectedDate, (t) {
                               setDialogState(() => selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, t.hour, t.minute));
                          }),
                          if (type == 'breast')
                              TextField(controller: durationController, decoration: const InputDecoration(labelText: "Duration (min)"), keyboardType: TextInputType.number),
                          if (type == 'bottle')
                              TextField(controller: amountController, decoration: const InputDecoration(labelText: "Amount (ml)"), keyboardType: TextInputType.number),
                      ],
                  ),
                  actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                      TextButton(
                          onPressed: () async {
                              // Strict Future Check
                              if (selectedDate.isAfter(DateTime.now())) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot save future date!")));
                                  return;
                              }

                              final updates = <String, dynamic>{
                                  'created_at': selectedDate.toUtc().toIso8601String(),
                              };
                              
                              if (type == 'breast' && durationController.text.isNotEmpty) {
                                  updates['duration_min'] = int.tryParse(durationController.text);
                              }
                              if (type == 'bottle' && amountController.text.isNotEmpty) {
                                  updates['amount_ml'] = int.tryParse(amountController.text);
                              }

                              await context.read<SupabaseService>().updateFeed(log['id'], updates);
                              _loadData();
                              Navigator.pop(context);
                          }, 
                          child: Text("Save")
                      )
                  ],
              ),
          ),
      );
  }

  void _editSleep(Map<String, dynamic> log) {
      DateTime startTime = DateTime.parse(log['start_time']); // Already forced local? No.
      // In _loadData, we set 'sort_time' to Local. But 'start_time' string remains raw unless we modified log map?
      // Step 1624: "item['sort_time'] = DateTime.parse(startStr).toLocal();" but 'start_time' key is from DB.
      // So startTime here needs parsing + local.
      if (!log['start_time'].toString().endsWith('Z')) {
        startTime = DateTime.parse(log['start_time'] + 'Z').toLocal();
      } else {
        startTime = DateTime.parse(log['start_time']).toLocal();
      }

      DateTime? endTime;
      if (log['end_time'] != null) {
          if (!log['end_time'].toString().endsWith('Z')) {
            endTime = DateTime.parse(log['end_time'] + 'Z').toLocal();
          } else {
            endTime = DateTime.parse(log['end_time']).toLocal();
          }
      }

      showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                  title: Text("Edit Sleep"),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          _buildDateRow("Start Date", startTime, (d) {
                              setDialogState(() => startTime = DateTime(d.year, d.month, d.day, startTime.hour, startTime.minute));
                          }),
                          _buildTimeRow("Start Time", startTime, (t) {
                               setDialogState(() => startTime = DateTime(startTime.year, startTime.month, startTime.day, t.hour, t.minute));
                          }),
                          const Divider(),
                          ListTile(
                              title: Text("End Time"),
                              subtitle: Text(endTime == null ? "Still sleeping (Tap to set)" : DateFormat('MMM d, h:mm a').format(endTime!)),
                              trailing: endTime != null ? IconButton(icon: Icon(Icons.clear), onPressed: () => setDialogState(() => endTime = null)) : null,
                              onTap: () async {
                                  final initial = endTime ?? DateTime.now();
                                  final d = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2023), lastDate: DateTime.now());
                                  if (d != null) {
                                      final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
                                      if (t != null) {
                                          setDialogState(() {
                                              endTime = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                                          });
                                      }
                                  }
                              },
                          ),
                      ],
                  ),
                  actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                      TextButton(
                          onPressed: () async {
                              final now = DateTime.now();
                              if (startTime.isAfter(now) || (endTime != null && endTime!.isAfter(now))) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot save future date!")));
                                  return;
                              }
                              // Also validate End > Start
                              if (endTime != null && endTime!.isBefore(startTime)) {
                                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("End time must be after Start time!")));
                                   return;
                              }

                              final updates = <String, dynamic>{
                                  'start_time': startTime.toUtc().toIso8601String(),
                                  'end_time': endTime?.toUtc().toIso8601String(),
                              };
                              await context.read<SupabaseService>().updateSleepLog(log['id'], updates);
                              _loadData();
                              Navigator.pop(context);
                          }, 
                          child: Text("Save")
                      )
                  ],
              ),
          ),
      );
  }

  void _editDiaper(Map<String, dynamic> log) {
      DateTime selectedDate = log['sort_time'];
      String type = log['type'];

      showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                  title: Text("Edit Diaper Log"),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          _buildDateRow("Date", selectedDate, (d) {
                              setDialogState(() => selectedDate = DateTime(d.year, d.month, d.day, selectedDate.hour, selectedDate.minute));
                          }),
                          _buildTimeRow("Time", selectedDate, (t) {
                               setDialogState(() => selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, t.hour, t.minute));
                          }),
                          const SizedBox(height: 16),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                  _buildTypeChip("Pee", 'pee', type, (v) => setDialogState(() => type = v)),
                                  _buildTypeChip("Poop", 'poop', type, (v) => setDialogState(() => type = v)),
                                  _buildTypeChip("Both", 'both', type, (v) => setDialogState(() => type = v)),
                              ],
                          )
                      ],
                  ),
                  actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                      TextButton(
                          onPressed: () async {
                              if (selectedDate.isAfter(DateTime.now())) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot save future date!")));
                                  return;
                              }
                              await context.read<SupabaseService>().updateDiaperLog(log['id'], {
                                  'created_at': selectedDate.toUtc().toIso8601String(),
                                  'type': type
                              });
                              _loadData();
                              Navigator.pop(context);
                          }, 
                          child: Text("Save")
                      )
                  ],
              ),
          ),
      );
  }

  Widget _buildDateRow(String label, DateTime date, Function(DateTime) onPick) {
      return ListTile(
          title: Text(label),
          trailing: Text(DateFormat('MMM d, y').format(date)),
          onTap: () async {
              final d = await showDatePicker(
                  context: context, 
                  initialDate: date, 
                  firstDate: DateTime(2023), 
                  lastDate: DateTime.now() 
              );
              if (d != null) onPick(d);
          },
      );
  }

  Widget _buildTimeRow(String label, DateTime date, Function(TimeOfDay) onPick) {
      return ListTile(
          title: Text(label),
          trailing: Text(DateFormat('h:mm a').format(date)),
          onTap: () async {
              final t = await showTimePicker(
                  context: context, 
                  initialTime: TimeOfDay.fromDateTime(date)
              );
              if (t != null) onPick(t);
          },
      );
  }

  Widget _buildTypeChip(String label, String value, String current, Function(String) onSelect) {
      final isSelected = value == current;
      return GestureDetector(
          onTap: () => onSelect(value),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
          ),
      );
  }
  
  String _formatDuration(Duration d) {
    if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
    return "${d.inMinutes}m";
  }
}
