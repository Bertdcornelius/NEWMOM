import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/feeding_repository.dart';
import '../../repositories/sleep_repository.dart';
import '../../repositories/care_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/glass_morph_ui.dart';
import '../../widgets/lazy_indexed_stack.dart';
import '../../widgets/premium_ui_components.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import 'feeding_screen.dart';
import 'sleep_screen.dart';
import 'history_screen.dart';
import 'mom_care_screen.dart';
import 'diaper_screen.dart';
import 'pumping_tracker_screen.dart';
import 'profile_screen.dart';
import 'explore_screen.dart';
import 'ai_chat_screen.dart';
import '../auth/welcome_screen.dart';
import '../../widgets/mini_features/hydration_tracker.dart';
import 'package:quick_actions/quick_actions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _setupQuickActions();
  }

  void _setupQuickActions() {
    const QuickActions quickActions = QuickActions();
    
    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'action_diaper') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DiaperScreen()));
      } else if (shortcutType == 'action_feed') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedingScreen()));
      } else if (shortcutType == 'action_sleep') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepScreen()));
      }
    });

    // Setting up the icons to use distinct native Android drawables
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(type: 'action_diaper', localizedTitle: 'Log Diaper', icon: 'ic_action_diaper'),
      const ShortcutItem(type: 'action_feed', localizedTitle: 'Log Feed', icon: 'ic_action_feed'),
      const ShortcutItem(type: 'action_sleep', localizedTitle: 'Log Sleep', icon: 'ic_action_sleep'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      extendBody: true,
      body: LazyIndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardContent(),
          ExploreScreen(),
          AIChatScreen(),
          MomCareScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: SlidingGlassNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        icons: const [Icons.home_rounded, Icons.explore_rounded, Icons.auto_awesome_rounded, Icons.favorite_rounded, Icons.person_rounded],
        labels: const [
          'Home',
          'Explore',
          'AI',
          'Care',
          'Profile',
        ],
      ),
    );
  }

}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  String _babyName = "Baby";
  DateTime? _babyBirthday;
  Map<String, dynamic>? _lastFeed;
  Map<String, dynamic>? _lastSleep;
  List<Map<String, dynamic>> _diaperLogs = [];
  List<Map<String, dynamic>> _recentLogs = [];
  String _activeAlarmNote = 'No alarm set';
  String _activeAlarmTime = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final storage = context.read<LocalStorageService>();
    final authRepo = context.read<AuthRepository>();
    
    if (authRepo.currentUser == null) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => WelcomeScreen()),
          (route) => false,
        );
      }
      return;
    }
    
    final feedingRepo = context.read<FeedingRepository>();
      final profileRes = await authRepo.getProfile();
      if (profileRes.isSuccess && profileRes.data != null) {
        _babyName = profileRes.data!['baby_name'] ?? 'Baby';
      }

      final prefs = await SharedPreferences.getInstance();
      _activeAlarmNote = prefs.getString('custom_alarm_note') ?? 'No alarm set';
      _activeAlarmTime = prefs.getString('custom_alarm_time') ?? '';
    final bdayStr = storage.getString('baby_birthday');
    if (bdayStr != null) {
       _babyBirthday = DateTime.tryParse(bdayStr);
    }
    
    try {
      final sleepRepo = context.read<SleepRepository>();
      final careRepo = context.read<CareRepository>();
      
      // _babyName = storage.getString('baby_name') ?? "Baby"; // Moved to authRepo.getProfile()
      
      final feedRes = await feedingRepo.getLastFeed();
      _lastFeed = feedRes.data;

      final sleepRes = await sleepRepo.getSleepLogs(limit: 1);
      _lastSleep = (sleepRes.data != null && sleepRes.data!.isNotEmpty) ? sleepRes.data!.first : null;
      
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final diaperRes = await careRepo.getDiaperLogs(startDate: startOfToday);
      _diaperLogs = diaperRes.data ?? [];
      
      // Fetch 5 recent history mixed events
      final recentFeeds = (await feedingRepo.getFeeds(limit: 5)).data ?? [];
      final recentSleeps = (await sleepRepo.getSleepLogs(limit: 5)).data ?? [];
      final recentDiapers = (await careRepo.getDiaperLogs(limit: 5)).data ?? [];
      
      final List<Map<String, dynamic>> mixed = [];
      for (var f in recentFeeds) { var i = Map<String,dynamic>.from(f); i['type_lbl'] = 'Feed'; i['sort_time'] = _parseUtc(f['created_at']); mixed.add(i); }
      for (var s in recentSleeps) { var i = Map<String,dynamic>.from(s); i['type_lbl'] = 'Sleep'; i['sort_time'] = _parseUtc(s['start_time']); mixed.add(i); }
      for (var d in recentDiapers) { var i = Map<String,dynamic>.from(d); i['type_lbl'] = 'Diaper'; i['sort_time'] = _parseUtc(d['created_at']); mixed.add(i); }
      
      mixed.sort((a,b) => b['sort_time'].compareTo(a['sort_time']));
      _recentLogs = mixed.take(6).toList();
      
    } catch (e) {
      debugPrint("Error loading dashboard data: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20.0, MediaQuery.of(context).padding.top + 16.0, 20.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child)),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF67B29F), Color(0xFF81C7E1)], // custom teal to blue gradient
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF67B29F).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('☀️ ', style: TextStyle(fontSize: 16)),
                                    Text(_getGreeting(), style: PremiumTypography(context).body.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500)),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen())),
                                      child: Container(
                                         padding: const EdgeInsets.all(6),
                                         decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                                         child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Mom & $_babyName', style: PremiumTypography(context).h1.copyWith(color: Colors.white, fontSize: 32)),
                                const SizedBox(height: 8),
                                Text('Ready to start tracking ✨', style: PremiumTypography(context).body.copyWith(color: Colors.white)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
                                  color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                  const HydrationTracker(),
                  const SizedBox(height: 32),
                  
                  // Quick Stats Carousel
                  Text('Quick Stats', style: PremiumTypography(context).h2),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) => Opacity(opacity: value, child: Transform.translate(offset: Offset(30 * (1 - value), 0), child: child)),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                           _buildQuickStatCard(
                              'Last Feed',
                              _formatTime(_lastFeed?['created_at']),
                              Icons.baby_changing_station,
                              PremiumColors(context).warmPeach,
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedingScreen())).then((_) => _loadData()),
                              heroTag: 'feeding_card',
                              titleHeroTag: 'feeding_card_title',
                           ),
                           const SizedBox(width: 16),
                           _buildQuickStatCard(
                              'Sleeping',
                              _getSleepStatus(),
                              Icons.bedtime,
                              PremiumColors(context).sereneBlue,
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepScreen())).then((_) => _loadData()),
                              heroTag: 'sleep_card',
                              titleHeroTag: 'sleep_card_title',
                           ),
                           const SizedBox(width: 16),
                             _buildQuickStatCard(
                              'Quick Reminder',
                              _activeAlarmTime.isEmpty ? 'Tap to Set' : _activeAlarmTime,
                              Icons.alarm,
                              PremiumColors(context).softAmber,
                              _setCustomAlarmDialog,
                              subtitle: _activeAlarmNote,
                           ),
                           const SizedBox(width: 16),
                           _buildQuickStatCard(
                              'Diapers',
                              _getDiaperCount(),
                              Icons.child_care,
                              PremiumColors(context).sageGreen,
                              _logDiaper,
                              subtitle: _getLastDiaperTime(),
                           ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent History', style: PremiumTypography(context).h2),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())).then((_) => _loadData()),
                        child: Row(
                          children: [
                            Text('See All', style: PremiumTypography(context).bodyBold.copyWith(color: PremiumColors(context).warmPeach)),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFFFF9E80)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _recentLogs.isEmpty 
                      ? Center(child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text("No history yet. Start tracking!", style: PremiumTypography(context).body),
                        ))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentLogs.length,
                          itemBuilder: (context, index) {
                              final log = _recentLogs[index];
                              return _buildRecentLogTile(log);
                          },
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap, {String? subtitle, String? heroTag, String? titleHeroTag}) {
      Widget card = PremiumCard(
              width: 160,
              padding: const EdgeInsets.all(16),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // This prevents the overflow
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                  PremiumBubbleIcon(icon: icon, color: color, size: 24, padding: 12),
                  const SizedBox(height: 12),
                  Text(title, style: PremiumTypography(context).caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(value, style: PremiumTypography(context).h2.copyWith(fontSize: 22), maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(subtitle, style: PremiumTypography(context).caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]
              ],
          ),
      );

      return Semantics(
          button: true,
          label: '$title tracker. Status: $value. ${subtitle ?? ""}',
          child: GestureDetector(
              onTap: onTap,
              child: heroTag != null ? Hero(tag: heroTag, child: card) : card,
          ),
      );
  }

  Widget _buildRecentLogTile(Map<String, dynamic> log) {
      final typeLbl = log['type_lbl'];
      final time = log['sort_time'] as DateTime;
      
      IconData icon = Icons.check_circle;
      Color color = PremiumColors(context).sageGreen;
      String title = "$typeLbl";
      String subtitle = _formatTime(time);

      if (typeLbl == 'Feed') {
          icon = Icons.restaurant_rounded;
          color = PremiumColors(context).warmPeach;
          String type = log['type'] ?? 'Bottle';
          title = "Fed - $type";
          if (type == 'breast') subtitle += " • ${log['duration_min']} mins";
          if (type == 'bottle') subtitle += " • ${log['amount_ml']} ml";
      } else if (typeLbl == 'Sleep') {
          icon = Icons.bedtime_rounded;
          color = PremiumColors(context).sereneBlue;
          if (log['end_time'] != null) {
               final end = _parseUtc(log['end_time']);
               final dur = end.difference(time);
               title = "Slept";
               subtitle += " • ${_formatDurationSimple(dur)}";
          } else {
               title = "Sleeping";
               subtitle = "Started ${_formatTime(time)}";
          }
      } else if (typeLbl == 'Diaper') {
          icon = Icons.child_care_rounded;
          color = PremiumColors(context).sageGreen;
          title = "Diaper changed";
          String typ = log['type'] ?? 'Wet';
          subtitle += " • $typ";
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DataTile(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: PremiumColors(context).surfaceMuted,
          child: Row(
            children: [
              PremiumBubbleIcon(icon: icon, color: color, size: 20, padding: 10),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: PremiumTypography(context).bodyBold),
                  const SizedBox(height: 2),
                  Text(subtitle, style: PremiumTypography(context).caption),
                ],
              )
            ],
          )
        ),
      );
  }

  String _getGreeting() {
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 12) return 'Good Morning,';
      if (hour >= 12 && hour < 17) return 'Good Afternoon,';
      if (hour >= 17 && hour < 21) return 'Good Evening,';
      return 'Good Night,';
  }

  DateTime _parseUtc(String dateStr) {
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
          return DateTime.parse('${dateStr}Z');
      }
      return DateTime.parse(dateStr);
  }

  String _formatTime(dynamic dateStr) {
      if (dateStr == null) return "None";
      try {
          final date = (dateStr is String ? DateTime.parse(dateStr) : (dateStr as DateTime)).toLocal();
          final now = DateTime.now();
          final diff = now.difference(date);
          if (diff.inSeconds.abs() < 60) return "Just now"; 
          if (diff.inDays > 0) return "${diff.inDays}d ago";
          if (diff.inHours > 0) return "${diff.inHours}h ago";
          if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
          return "Just now";
      } catch (e) {
          return "Unknown";
      }
  }

  String _getSleepStatus() {
      if (_lastSleep == null) return "None";
      if (_lastSleep!['end_time'] == null) {
          final start = _parseUtc(_lastSleep!['start_time']).toLocal();
          final duration = DateTime.now().difference(start);
          return "Sleeping for ${_formatDurationSimple(duration)}";
      } else {
          final end = _parseUtc(_lastSleep!['end_time']).toLocal();
          final ago = DateTime.now().difference(end);
          return "Slept ${_formatDurationSimple(ago)} ago"; 
      }
  }

  String _formatDurationSimple(Duration d) {
      if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
      return "${d.inMinutes}m";
  }

  Future<void> _setCustomAlarmDialog() async {
      TimeOfDay? time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
      );
      if (time == null) return;

      String note = "Baby Reminder";
      if (!mounted) return;

      await showDialog(
          context: context,
          builder: (ctx) {
              final tc = TextEditingController(text: note);
              return AlertDialog(
                  title: const Text('Alarm Note'),
                  content: TextField(
                      controller: tc,
                      decoration: const InputDecoration(hintText: 'E.g. Time for medicine!'),
                      autofocus: true,
                  ),
                  actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                          onPressed: () {
                              note = tc.text.trim().isEmpty ? note : tc.text.trim();
                              Navigator.pop(ctx);
                          },
                          child: const Text('Set Alarm')
                      ),
                  ]
              );
          }
      );

      try {
          // Native Android Alarm intent
          final intent = AndroidIntent(
              action: 'android.intent.action.SET_ALARM',
              arguments: <String, dynamic>{
                  'android.intent.extra.alarm.HOUR': time.hour,
                  'android.intent.extra.alarm.MINUTES': time.minute,
                  'android.intent.extra.alarm.MESSAGE': note,
                  'android.intent.extra.alarm.SKIP_UI': true,
              },
          );
          await intent.launch();

          final prefs = await SharedPreferences.getInstance();
          final timeFormatted = time.format(context);
          await prefs.setString('custom_alarm_time', timeFormatted);
          await prefs.setString('custom_alarm_note', note);
          
          if (mounted) {
              setState(() {
                  _activeAlarmTime = timeFormatted;
                  _activeAlarmNote = note;
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone alarm scheduled safely!')));
          }
      } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to set system alarm: $e')));
      }
  }

  String _getDiaperCount() {
      return "${_diaperLogs.length} today";
  }

  String _getLastDiaperTime() {
      if (_diaperLogs.isEmpty) return "None today";
      return "Last: ${_formatTime(_diaperLogs.first['created_at'])}";
  }

  void _logDiaper() {
       showModalBottomSheet(
           context: context,
           shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
           builder: (context) => Padding(
               padding: const EdgeInsets.all(24),
               child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                       Text("Log Diaper", style: PremiumTypography(context).h2),
                       const SizedBox(height: 24),
                       Row(
                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                           children: [
                               _buildDiaperOption(Icons.water_drop, "Pee", Colors.blue),
                               _buildDiaperOption(Icons.warning_amber_rounded, "Poop", Colors.brown),
                               _buildDiaperOption(Icons.warning_rounded, "Both", Colors.orange),
                           ],
                       ),
                       const SizedBox(height: 24),
                   ],
               ),
           )
       );
  }

  Widget _buildDiaperOption(IconData icon, String label, Color color) {
      return Semantics(
          button: true,
          label: 'Log $label diaper',
          child: GestureDetector(
              onTap: () async {
                  final auth = context.read<AuthRepository>();
                  final care = context.read<CareRepository>();
                  final user = auth.currentUser;
                  if (user != null) {
                      await care.saveDiaperLog({
                          'id': const Uuid().v4(),
                          'user_id': user.id,
                          'type': label.toLowerCase(),
                          'created_at': DateTime.now().toUtc().toIso8601String(),
                      });
                      _loadData();
                      if (mounted) Navigator.pop(context);
                  }
              },
              child: Column(
                  children: [
                      PremiumBubbleIcon(icon: icon, color: color, size: 28, padding: 16),
                      const SizedBox(height: 8),
                      Text(label, style: PremiumTypography(context).bodyBold),
                  ],
              ),
          ),
      );
  }
}
