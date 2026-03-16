import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/premium_ui_components.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final ls = context.read<LocalStorageService>();
    final raw = ls.getString('appointments');
    if (raw != null) _appointments = List<Map<String, dynamic>>.from(jsonDecode(raw));
    if (mounted) setState(() {});
  }

  Future<void> _saveData() async {
    await context.read<LocalStorageService>().saveString('appointments', jsonEncode(_appointments));
  }

  List<Map<String, dynamic>> get _upcoming {
    final now = DateTime.now();
    return _appointments.where((a) {
      try { return DateTime.parse(a['datetime']).isAfter(now); } catch (_) { return false; }
    }).toList()..sort((a, b) => DateTime.parse(a['datetime']).compareTo(DateTime.parse(b['datetime'])));
  }

  List<Map<String, dynamic>> get _past {
    final now = DateTime.now();
    return _appointments.where((a) {
      try { return DateTime.parse(a['datetime']).isBefore(now); } catch (_) { return true; }
    }).toList()..sort((a, b) => DateTime.parse(b['datetime']).compareTo(DateTime.parse(a['datetime'])));
  }

  // Generate a unique notification ID from appointment data
  int _notifIdFromAppt(Map<String, dynamic> appt) {
    return (appt['datetime'].hashCode.abs()) % 100000;
  }

  void _scheduleAppointmentReminder(Map<String, dynamic> appt) {
    try {
      final dt = DateTime.parse(appt['datetime']);
      // Schedule reminder 1 hour before
      final reminderTime = dt.subtract(const Duration(hours: 1));
      if (reminderTime.isAfter(DateTime.now())) {
        final notifId = _notifIdFromAppt(appt);
        final title = '📅 ${appt['title'] ?? 'Appointment'} in 1 hour';
        final body = appt['doctor'] != null && (appt['doctor'] as String).isNotEmpty
              ? 'With Dr. ${appt['doctor']}${appt['location'] != null && (appt['location'] as String).isNotEmpty ? ' at ${appt['location']}' : ''}'
              : 'Don\'t forget your appointment!';
              
        context.read<NotificationService>().scheduleReminder(
          notifId,
          reminderTime,
          title,
          body,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling appointment reminder: $e');
    }
  }

  void _cancelAppointmentReminder(Map<String, dynamic> appt) {
    try {
      context.read<NotificationService>().cancelReminder(_notifIdFromAppt(appt));
    } catch (e) {
      debugPrint('Error canceling appointment reminder: $e');
    }
  }




  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Appointments', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.sageGreen,
          unselectedLabelColor: colors.textSecondary,
          indicatorColor: colors.sageGreen,
          tabs: [
            Tab(text: 'Upcoming (${_upcoming.length})'),
            Tab(text: 'Past (${_past.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: colors.sageGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_upcoming, colors, typo, isEmpty: 'No upcoming appointments'),
                _buildList(_past, colors, typo, isEmpty: 'No past appointments'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, PremiumColors colors, PremiumTypography typo, {String isEmpty = ''}) {
    if (items.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_rounded, size: 56, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(isEmpty, style: typo.body),
            const SizedBox(height: 8),
            Text('Tap + to schedule one', style: typo.caption),
          ],
        ),
      ));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final appt = items[i];
        String dateStr = '';
        bool isToday = false;
        try {
          final dt = DateTime.parse(appt['datetime']);
          dateStr = DateFormat('MMM d, yyyy • h:mm a').format(dt);
          final now = DateTime.now();
          isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
        } catch (_) {}

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DataTile(
            onTap: () => _showOptions(appt),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: isToday ? colors.warmPeach.withValues(alpha: 0.15) : colors.sageGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.medical_services_rounded,
                      color: isToday ? colors.warmPeach : colors.sageGreen, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(appt['title'] ?? 'Appointment', style: typo.bodyBold)),
                        if (isToday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.warmPeach.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('TODAY', style: GoogleFonts.plusJakartaSans(
                              fontSize: 10, fontWeight: FontWeight.w800, color: colors.warmPeach,
                            )),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(dateStr, style: typo.caption),
                    if (appt['doctor'] != null && (appt['doctor'] as String).isNotEmpty)
                      Text('Dr. ${appt['doctor']}', style: typo.caption.copyWith(color: colors.sageGreen)),
                    if (appt['location'] != null && (appt['location'] as String).isNotEmpty)
                      Text('📍 ${appt['location']}', style: typo.caption),
                  ],
                )),
                Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddDialog({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final titleC = TextEditingController(text: existing?['title'] ?? '');
    final doctorC = TextEditingController(text: existing?['doctor'] ?? '');
    final locationC = TextEditingController(text: existing?['location'] ?? '');
    final notesC = TextEditingController(text: existing?['notes'] ?? '');
    DateTime selectedDate;
    try {
      selectedDate = existing != null ? DateTime.parse(existing['datetime']) : DateTime.now().add(const Duration(days: 1));
    } catch (_) {
      selectedDate = DateTime.now().add(const Duration(days: 1));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PremiumColors(context).surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: PremiumColors(context).textMuted, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text(isEdit ? 'Edit Appointment' : 'Schedule Appointment', style: PremiumTypography(context).h2),
                const SizedBox(height: 16),
                _input(titleC, 'Title', Icons.event_rounded, PremiumColors(context).sageGreen),
                const SizedBox(height: 12),
                _input(doctorC, 'Doctor Name', Icons.person_rounded, PremiumColors(context).sereneBlue),
                const SizedBox(height: 12),
                _input(locationC, 'Location', Icons.location_on_rounded, PremiumColors(context).warmPeach),
                const SizedBox(height: 12),
                _input(notesC, 'Notes (optional)', Icons.note_rounded, PremiumColors(context).gentlePurple),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx, 
                      initialDate: selectedDate, 
                      firstDate: DateTime.now(), 
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(viewInsets: EdgeInsets.zero, textScaler: const TextScaler.linear(1.0)),
                        child: child!,
                      ),
                    );
                    if (date == null) return;
                    if (!ctx.mounted) return;
                    final time = await showTimePicker(
                      context: ctx, 
                      initialTime: TimeOfDay.fromDateTime(selectedDate),
                      builder: (context, child) => MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          viewInsets: EdgeInsets.zero,
                          textScaler: const TextScaler.linear(1.0),
                        ),
                        child: child!,
                      ),
                    );
                    if (time == null) return;
                    setBS(() {
                      selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: PremiumColors(context).surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, color: PremiumColors(context).softAmber),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date & Time', style: PremiumTypography(context).bodyBold),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM d, yyyy • h:mm a').format(selectedDate),
                              style: PremiumTypography(context).caption.copyWith(color: PremiumColors(context).softAmber),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: PremiumActionButton(
                    label: isEdit ? 'Update' : 'Schedule',
                    icon: Icons.check_circle_outline_rounded,
                    color: PremiumColors(context).sageGreen,
                    onTap: () {
                      if (titleC.text.isEmpty) return;
                      final apptData = {
                        'title': titleC.text,
                        'doctor': doctorC.text,
                        'location': locationC.text,
                        'notes': notesC.text,
                        'datetime': selectedDate.toIso8601String(),
                      };
                      
                      if (isEdit) {
                        // Cancel old reminder
                        _cancelAppointmentReminder(existing);
                        // Update in list
                        final idx = _appointments.indexOf(existing);
                        if (idx >= 0) {
                          _appointments[idx] = apptData;
                        }
                      } else {
                        _appointments.add(apptData);
                      }
                      
                      // Schedule reminder notification (1 hour before)
                      _scheduleAppointmentReminder(apptData);
                      
                      _saveData();
                      Navigator.pop(ctx);
                      _loadData();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit ? 'Appointment updated! Reminder set.' : 'Appointment scheduled! Reminder set 1 hour before.'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String label, IconData icon, Color color) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color, size: 22),
        filled: true,
        fillColor: PremiumColors(context).surfaceMuted,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  void _showOptions(Map<String, dynamic> appt) {
    final colors = PremiumColors(context);
    String dateStr = '';
    try {
      final dt = DateTime.parse(appt['datetime']);
      dateStr = DateFormat('MMM d, yyyy • h:mm a').format(dt);
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.textMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(appt['title'] ?? 'Appointment', style: PremiumTypography(context).h2),
            const SizedBox(height: 8),
            if (dateStr.isNotEmpty)
              Text('📅 $dateStr', style: PremiumTypography(context).body),
            if (appt['doctor'] != null && (appt['doctor'] as String).isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text('👨‍⚕️ Dr. ${appt['doctor']}', style: PremiumTypography(context).body)),
            if (appt['location'] != null && (appt['location'] as String).isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text('📍 ${appt['location']}', style: PremiumTypography(context).body)),
            if (appt['notes'] != null && (appt['notes'] as String).isNotEmpty)
              Padding(padding: const EdgeInsets.only(top: 4), child: Text('📝 ${appt['notes']}', style: PremiumTypography(context).body)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddDialog(existing: appt);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.sereneBlue,
                      side: BorderSide(color: colors.sereneBlue.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final text = '📅 Appointment: ${appt['title']}\n'
                          '${dateStr.isNotEmpty ? '🕐 $dateStr\n' : ''}'
                          '${appt['doctor'] != null && (appt['doctor'] as String).isNotEmpty ? '👨‍⚕️ Dr. ${appt['doctor']}\n' : ''}'
                          '${appt['location'] != null && (appt['location'] as String).isNotEmpty ? '📍 ${appt['location']}\n' : ''}'
                          '\n— Sent from Neo Baby Tracker';
                      Share.share(text, subject: 'Appointment: ${appt['title']}');
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.sageGreen,
                      side: BorderSide(color: colors.sageGreen.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _cancelAppointmentReminder(appt);
                      _appointments.remove(appt);
                      _saveData();
                      Navigator.pop(ctx);
                      _loadData();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
