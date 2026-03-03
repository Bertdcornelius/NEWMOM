import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../models/feed_model.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/premium_ui_components.dart';

class FeedingScreen extends StatefulWidget {
  const FeedingScreen({super.key});

  @override
  State<FeedingScreen> createState() => _FeedingScreenState();
}

class _FeedingScreenState extends State<FeedingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Breast Feeding State
  String _selectedSide = 'L';
  int _durationMinutes = 15;
  
  // Timer State
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _uiTimer;
  bool _isTimerRunning = false;

  // Bottle Feeding State
  int _amountMl = 120;
  
  // Solid Feeding State
  final _solidTypeController = TextEditingController();

  // General State
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now(); // For past logs
  
  // Reminder State
  bool _remindMe = false; // Fix 2: Default to false
  int _reminderInterval = 3; // Hours
  TimeOfDay? _customReminderTime;
  final _reminderNoteController = TextEditingController();
  int _activeReminderCount = 0;
  String? _nextReminderTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadActiveReminders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _solidTypeController.dispose();
    _stopwatch.stop();
    _uiTimer?.cancel();
    super.dispose();
  }

  // --- Timer Logic ---
  void _toggleTimer() {
      setState(() {
          if (_isTimerRunning) {
              _stopwatch.stop();
              _isTimerRunning = false;
              _uiTimer?.cancel();
              // Update duration slider based on elapsed time (rounded up to nearest minute)
              _durationMinutes = (_stopwatch.elapsed.inMinutes == 0 && _stopwatch.elapsed.inSeconds > 0) ? 1 : _stopwatch.elapsed.inMinutes;
              if (_durationMinutes == 0) _durationMinutes = 1; 
              if (_durationMinutes > 60) _durationMinutes = 60;
          } else {
              _stopwatch.start();
              _isTimerRunning = true;
              _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                  setState(() {}); // Refresh UI
              });
          }
      });
  }

  String _formatStopwatch() {
      final elapsed = _stopwatch.elapsed;
      final String minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
      final String seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
      return "$minutes:$seconds";
  }

  // --- Save Logic ---
  Future<void> _saveFeed(String type) async {
    setState(() => _isLoading = true);
    final supabaseService = context.read<SupabaseService>();
    final notificationService = context.read<NotificationService>();
    final user = supabaseService.currentUser;

    if (user == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in')));
        setState(() => _isLoading = false);
        return;
    }

    DateTime? nextDue;
    if (_remindMe) {
        if (_customReminderTime != null) {
            final now = DateTime.now();
            nextDue = DateTime(now.year, now.month, now.day, _customReminderTime!.hour, _customReminderTime!.minute);
            if (nextDue.isBefore(now)) {
                nextDue = nextDue.add(const Duration(days: 1));
            }
        } else {
             // Calculate from the FEED TIME (_selectedDate), not Now
             nextDue = _selectedDate.add(Duration(hours: _reminderInterval));
        }
    }

    final feed = Feed(
      id: Uuid().v4(),
      userId: user.id,
      type: type,
      side: type == 'breast' ? _selectedSide : null,
      amountMl: type == 'bottle' ? _amountMl : null,
      durationMin: type == 'breast' ? _durationMinutes : null,
      nextDue: nextDue,
      createdAt: _selectedDate,
      notes: type == 'solid' ? _solidTypeController.text : null, // Fix 1: Save Solid Food Name
    );

    await supabaseService.saveFeed(feed.toJson());

    // Schedule Reminder if enabled
    if (_remindMe && nextDue != null) {
        if (nextDue.isAfter(DateTime.now())) {
            final reminderId = nextDue.millisecondsSinceEpoch % 100000;
            final noteText = _reminderNoteController.text.trim();
            final body = noteText.isNotEmpty ? noteText : 'Time to feed your baby';
            await notificationService.scheduleReminder(reminderId, nextDue, '🍼 Feeding Time!', body);
            _loadActiveReminders();
        }
    }
    
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feed Saved! Next: ${_remindMe ? DateFormat('h:mm a').format(_customReminderTime != null ? DateTime(2024,1,1,_customReminderTime!.hour, _customReminderTime!.minute) : DateTime.now().add(Duration(hours: _reminderInterval))) : "None"}')));
        Navigator.pop(context);
    }
    
    setState(() => _isLoading = false);
  }

  // --- UI Builders ---

  Future<void> _pickDateTime() async {
      final now = DateTime.now();
      final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2024),
          lastDate: now,
      );
      if (date == null) return;

      final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time == null) return;

      final combinedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (combinedDate.isAfter(now)) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot select future time!")));
          return;
      }

      setState(() {
          _selectedDate = combinedDate;
      });
  }

  Widget _buildDateSelectorRow() {
      return GestureDetector(
          onTap: _pickDateTime,
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                  color: PremiumColors(context).surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PremiumColors(context).surfaceMuted, width: 2),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Text("Date & Time", style: PremiumTypography(context).body),
                      Row(
                          children: [
                              Text(DateFormat('MMM d, h:mm a').format(_selectedDate), style: PremiumTypography(context).bodyBold),
                              const SizedBox(width: 8),
                              Icon(Icons.edit_calendar_rounded, size: 20, color: PremiumColors(context).textSecondary),
                          ],
                      ),
                  ],
              ),
          ),
      );
  }

  Future<void> _loadActiveReminders() async {
    final notificationService = context.read<NotificationService>();
    final reminders = await notificationService.getActiveReminders();
    if (mounted) {
      setState(() {
        _activeReminderCount = reminders.length;
        if (reminders.isNotEmpty) {
          // Find the next upcoming reminder (smallest ID = earliest epoch)
          _nextReminderTime = '${_activeReminderCount} active';
        } else {
          _nextReminderTime = null;
        }
      });
    }
  }

  Widget _buildReminderSection() {
      return Card(
          margin: const EdgeInsets.only(top: 16),
          color: Colors.grey[50],
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  children: [
                      Row(
                          children: [
                              Icon(Icons.alarm, color: Colors.blueGrey),
                              const SizedBox(width: 8),
                              Text("Remind me next time?", style: TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Switch(value: _remindMe, onChanged: (v) => setState(() => _remindMe = v)),
                          ],
                      ),
                      // Active reminders info
                      if (_activeReminderCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.notifications_active, size: 16, color: Colors.green),
                              const SizedBox(width: 6),
                              Text('$_activeReminderCount reminder${_activeReminderCount == 1 ? '' : 's'} active',
                                style: TextStyle(fontSize: 13, color: Colors.green[700])),
                            ],
                          ),
                        ),
                      if (_remindMe) ...[
                          const Divider(),
                          Row(
                              children: [
                                  ChoiceChip(
                                      label: Text("3 Hrs"),
                                      selected: _reminderInterval == 3 && _customReminderTime == null,
                                      onSelected: (b) => setState(() { if(b) { _reminderInterval = 3; _customReminderTime = null; } }),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                      label: Text("4 Hrs"),
                                      selected: _reminderInterval == 4 && _customReminderTime == null,
                                      onSelected: (b) => setState(() { if(b) { _reminderInterval = 4; _customReminderTime = null; } }),
                                  ),
                                  const SizedBox(width: 8),
                                  ActionChip(
                                      label: Text(_customReminderTime == null ? "Custom" : _customReminderTime!.format(context)),
                                      avatar: Icon(Icons.access_time, size: 16),
                                      backgroundColor: _customReminderTime != null ? Colors.pink[100] : null,
                                      onPressed: () async {
                                          final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                          if (t != null) setState(() => _customReminderTime = t);
                                      },
                                  ),
                              ],
                          ),
                          const SizedBox(height: 12),
                          // Description / Remarks text field
                          TextField(
                            controller: _reminderNoteController,
                            decoration: InputDecoration(
                              labelText: 'Reminder note (optional)',
                              hintText: 'e.g. Bottle feed, Solid snacks',
                              prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            style: TextStyle(fontSize: 14),
                          ),
                      ]
                  ],
              ),
          ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      
      appBar: AppBar(
        title: Text('Log Feed', style: PremiumTypography(context).h2),
        backgroundColor: PremiumColors(context).surface,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: PremiumColors(context).warmPeach,
          unselectedLabelColor: PremiumColors(context).textSecondary,
          indicatorColor: PremiumColors(context).warmPeach,
          tabs: const [
            Tab(text: 'Breast', icon: Icon(Icons.child_care_rounded)),
            Tab(text: 'Bottle', icon: Icon(Icons.local_drink_rounded)),
            Tab(text: 'Solids', icon: Icon(Icons.restaurant_rounded)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBreastFeedTab(),
                    _buildBottleFeedTab(),
                    _buildSolidFeedTab(),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: AdBannerWidget(),
              ),
            ],
          ),
    );
  }

  Widget _buildBreastFeedTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Date Selector
            _buildDateSelectorRow(),
            const SizedBox(height: 24),
            // Side Selector
            Text('Select Side', style: PremiumTypography(context).title),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSideButton('L'),
                _buildSideButton('R'),
              ],
            ),
            const Divider(height: 32),
            
            // Timer Section
            Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: _isTimerRunning ? PremiumColors(context).warmPeach.withValues(alpha: 0.1) : PremiumColors(context).surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ]
                ),
                child: Column(
                    children: [
                        Text(_formatStopwatch(), style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _isTimerRunning ? PremiumColors(context).warmPeach : PremiumColors(context).textPrimary, fontFeatures: const [FontFeature.tabularFigures()])),
                        IconButton(
                            iconSize: 56,
                            icon: Icon(_isTimerRunning ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, color: PremiumColors(context).warmPeach),
                            onPressed: _toggleTimer,
                        ),
                        Text(_isTimerRunning ? "Tracking..." : "Start Timer", style: PremiumTypography(context).caption),
                    ],
                ),
            ),
            
            const SizedBox(height: 24),
            
            // Manual Slider (Syncs with Timer)
            Text('Total Duration: $_durationMinutes min', style: PremiumTypography(context).bodyBold),
            Slider(
              value: _durationMinutes.toDouble(),
              min: 1,
              max: 60,
              divisions: 59,
              activeColor: PremiumColors(context).warmPeach,
              label: '$_durationMinutes min',
              onChanged: (val) {
                   // Only allow manual change if timer is NOT running specific logic, OR just allow it override
                   if (!_isTimerRunning) {
                       setState(() => _durationMinutes = val.toInt());
                   }
              },
            ),

            _buildReminderSection(),
            const SizedBox(height: 32),
            PremiumActionButton(
              label: 'Save Log',
              icon: Icons.check_circle_outline_rounded,
              color: PremiumColors(context).warmPeach,
              onTap: () => _saveFeed('breast'),
            ),
          ],
        ),
    );
  }

  Widget _buildBottleFeedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildDateSelectorRow(),
          const SizedBox(height: 24),
          Text('Amount (ml)', style: PremiumTypography(context).title),
          const SizedBox(height: 16),
          // Circular or Big Display
          Container(
              width: 160, height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: PremiumColors(context).surface, border: Border.all(color: PremiumColors(context).sereneBlue, width: 4), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 8))]),
              child: Text('$_amountMl ml', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: PremiumColors(context).sereneBlue)),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _amountMl.toDouble(),
            min: 10,
            max: 300,
            divisions: 29,
            activeColor: PremiumColors(context).sereneBlue,
            label: '$_amountMl ml',
            onChanged: (val) => setState(() => _amountMl = val.toInt()),
          ),
          
          _buildReminderSection(),
          const SizedBox(height: 32),
          PremiumActionButton(
            label: 'Save Log',
            icon: Icons.check_circle_outline_rounded,
            color: PremiumColors(context).sereneBlue,
            onTap: () => _saveFeed('bottle'),
          ),
        ],
      ),
    );
  }

  Widget _buildSolidFeedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildDateSelectorRow(),
          const SizedBox(height: 16),
          TextField(
            controller: _solidTypeController,
            decoration: InputDecoration(
              labelText: 'What did baby eat?',
              hintText: 'e.g., Mashed Potatoes',
              filled: true,
              fillColor: PremiumColors(context).surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              prefixIcon: Icon(Icons.restaurant_rounded, color: PremiumColors(context).sageGreen),
            ),
          ),
          
          _buildReminderSection(),
          const SizedBox(height: 32),
          PremiumActionButton(
            label: 'Save Log',
            icon: Icons.check_circle_outline_rounded,
            color: PremiumColors(context).sageGreen,
            onTap: () => _saveFeed('solid'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSideButton(String side) {
    final isSelected = _selectedSide == side;
    return InkWell(
      onTap: () => setState(() => _selectedSide = side),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isSelected ? PremiumColors(context).warmPeach : PremiumColors(context).surface,
          border: isSelected ? null : Border.all(color: PremiumColors(context).surfaceMuted, width: 4),
          shape: BoxShape.circle,
          boxShadow: isSelected ? [BoxShadow(color: PremiumColors(context).warmPeach.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        alignment: Alignment.center,
        child: Text(
          side,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            color: isSelected ? Colors.white : PremiumColors(context).textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
