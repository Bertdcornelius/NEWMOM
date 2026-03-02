import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import 'feeding_screen.dart';
import 'sleep_screen.dart';
import 'notes_screen.dart';
import 'mom_care_screen.dart';
import 'milestones_screen.dart';
import 'routine_screen.dart';
import 'vaccine_screen.dart';
import 'prescription_screen.dart';
import '../../services/monetization_service.dart';
import '../../widgets/ad_banner.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/glass_morph_ui.dart';
import '../../widgets/premium_ui_components.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _babyName;
  Map<String, dynamic>? _lastFeed;
  Map<String, dynamic>? _lastSleep;
  List<Map<String, dynamic>> _diaperLogs = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = context.read<SupabaseService>();
    final localStorage = context.read<LocalStorageService>();
    final savedName = localStorage.getString('baby_name');
    final profile = await service.getProfile();
    // Fix 1: Use dedicated getLastFeed
    final lastFeed = await service.getLastFeed();
    final sleepLogs = await service.getSleepLogs();
    final diapers = await service.getDiaperLogs();

    if (mounted) {
      setState(() {
        _babyName = profile?['baby_name'] ?? savedName ?? 'Baby';
        _lastFeed = lastFeed; // Source of Truth
        if (sleepLogs.isNotEmpty) _lastSleep = sleepLogs.first; 
        _diaperLogs = diapers;
        _isLoading = false;

        if (profile != null) {
             context.read<MonetizationService>().checkStatus();
        }
      });
    }

    if ((profile == null || profile['baby_name'] == null) && savedName == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnboarding(context));
    }
  }

  void _checkOnboarding(BuildContext context) async {
      final nameController = TextEditingController();
      await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
              title: Text("Welcome!"),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      Text("What is your baby's name?"),
                      TextField(controller: nameController, decoration: const InputDecoration(hintText: "Baby Name")),
                  ],
              ),
              actions: [
                  TextButton(
                      onPressed: () async {
                          if (nameController.text.isNotEmpty) {
                               await context.read<SupabaseService>().updateProfile({'baby_name': nameController.text});
                               await context.read<LocalStorageService>().saveString('baby_name', nameController.text);
                              _loadData();
                              Navigator.pop(context);
                          }
                      },
                      child: Text("Start"),
                  )
              ],
          ),
      );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_currentIndex) {
        case 1:
            bodyContent = const HistoryScreen();
            break;
        case 2:
            bodyContent = const MomCareScreen();
            break;
        case 3:
             bodyContent = const ProfileScreen();
             break;
        default:
            bodyContent = _buildDashboardContent();
    }

    return PremiumScaffold(
      extendBody: true,
      
      body: Stack(
        children: [
           SafeArea(child: bodyContent),
        ],
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildDashboardContent() {
      return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_getGreeting(), style: PremiumTypography(context).body),
                              const SizedBox(height: 4),
                              Text('Mom & $_babyName', style: PremiumTypography(context).h1),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: PremiumColors(context).surface, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08), 
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: PremiumColors(context).sereneBlue,
                              child: Text(
                                _babyName != null && _babyName!.isNotEmpty ? _babyName![0].toUpperCase() : 'B',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Quick Stats Carousel
                      SingleChildScrollView(
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
                             ),
                             const SizedBox(width: 16),
                             _buildQuickStatCard(
                                'Sleeping',
                                _getSleepStatus(),
                                Icons.bedtime,
                                PremiumColors(context).sereneBlue,
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepScreen())).then((_) => _loadData()),
                             ),
                             const SizedBox(width: 16),
                               _buildQuickStatCard(
                                'Quick Reminder',
                                _calculateNextFeed(),
                                Icons.alarm,
                                PremiumColors(context).softAmber,
                                _setNextFeedTime,
                                subtitle: _calculateNextFeedTime(),
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


                      const SizedBox(height: 32),
                      Text('Explore', style: PremiumTypography(context).h2),
                      const SizedBox(height: 16),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                        children: [
                           _buildFeatureCard('Milestones', 'Track Growth', Icons.star_rounded, PremiumColors(context).softAmber, () => _navigateWithAdWall('milestones', const MilestonesScreen())),
                           _buildFeatureCard('Mom\'s Brain', 'Notes & Thoughts', Icons.psychology_rounded, PremiumColors(context).gentlePurple, () => _navigateWithAdWall('notes', const NotesScreen())),
                           _buildFeatureCard('Routines', 'Daily Schedule', Icons.schedule_rounded, PremiumColors(context).sereneBlue, () => _navigateWithAdWall('routine', const RoutineScreen())),
                           _buildFeatureCard('Health', 'Vaccines & Meds', Icons.medical_services_rounded, PremiumColors(context).sageGreen, () {
                               showModalBottomSheet(
                                   context: context, 
                                   shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                                   
                                   builder: (context) => Padding(
                                     padding: const EdgeInsets.symmetric(vertical: 16.0),
                                     child: Column(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                           Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: PremiumColors(context).textMuted, borderRadius: BorderRadius.circular(2))),
                                           ListTile(leading: PremiumBubbleIcon(icon: Icons.vaccines, color: PremiumColors(context).sageGreen, size: 20, padding: 8), title: Text('Vaccines', style: PremiumTypography(context).title), onTap: () { Navigator.pop(context); _navigateWithAdWall('vaccine', const VaccineScreen()); }),
                                           ListTile(leading: PremiumBubbleIcon(icon: Icons.medication, color: PremiumColors(context).sereneBlue, size: 20, padding: 8), title: Text('Prescriptions', style: PremiumTypography(context).title), onTap: () { Navigator.pop(context); _navigateWithAdWall('prescription', const PrescriptionScreen()); }),
                                       ],
                                     ),
                                   )
                               );
                           }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AdBannerWidget(),
          ],
      );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap, {String? subtitle}) {
      return GestureDetector(
          onTap: onTap,
          child: PremiumCard(
              width: 156,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                  PremiumBubbleIcon(icon: icon, color: color, size: 24, padding: 12),
                  const SizedBox(height: 12),
                  Text(title, style: PremiumTypography(context).caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: PremiumTypography(context).h2),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle, style: PremiumTypography(context).caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]
              ],
          ),
          ),
      );
  }

  Widget _buildFeatureCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
      return GestureDetector(
          onTap: onTap,
          child: PremiumCard(
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  PremiumBubbleIcon(icon: icon, color: color, size: 24, padding: 12),
                  const SizedBox(height: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(title, style: PremiumTypography(context).title),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: PremiumTypography(context).body, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
          ),
          ),
      );
  }

  // --- Time-Based Greeting ---
  String _getGreeting() {
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 12) return 'Good Morning,';
      if (hour >= 12 && hour < 17) return 'Good Afternoon,';
      if (hour >= 17 && hour < 21) return 'Good Evening,';
      return 'Good Night,';
  }

  // --- Ad Wall Navigation (Tiered Double-Ad Strategy) ---
  void _navigateWithAdWall(String featureId, Widget screen) {
      final monetization = context.read<MonetizationService>();

      // If trial still active (not post-trial), navigate directly
      if (!monetization.isPostTrial) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          return;
      }

      // Check for existing 6-hour unlock
      if (!monetization.isFeatureLocked(featureId)) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
          return;
      }

      // STEP 1: Show 15-second "Loading Ad" Gate
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Loading Ad...", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text("Please wait 15 seconds", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
              ),
          ),
      );

      // After 15 seconds, show the Offer Dialog
      Future.delayed(const Duration(seconds: 15), () {
          Navigator.pop(context); // Close loading dialog
          _showTieredOfferDialog(featureId, screen);
      });
  }

  void _showTieredOfferDialog(String featureId, Widget screen) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
              title: Text("Premium Feature"),
              content: Text("Choose how you'd like to access this feature:"),
              actions: [
                  // Option A: Use Once
                  TextButton(
                      onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
                      },
                      child: Text("Use Once"),
                  ),
                  // Option B: Unlock 6 Hours (Second Ad)
                  ElevatedButton(
                      onPressed: () {
                          Navigator.pop(dialogContext);
                          _showSecondAdForUnlock(featureId, screen);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                      child: Text("Watch Ad → Unlock 6 Hours"),
                  ),
                  // Option C: Go Premium
                  TextButton(
                      onPressed: () {
                          Navigator.pop(dialogContext);
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      },
                      child: Text("Go Premium", style: TextStyle(color: Colors.green)),
                  ),
              ],
          ),
      );
  }

  void _showSecondAdForUnlock(String featureId, Widget screen) {
      // Show second 15s ad
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Watching Ad for 6-Hour Unlock...", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text("15 seconds remaining", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
              ),
          ),
      );

      Future.delayed(const Duration(seconds: 15), () async {
          Navigator.pop(context); // Close ad dialog

          // Save 6-hour unlock
          final monetization = context.read<MonetizationService>();
          await monetization.unlockForHours(featureId, 6);

          // Navigate to feature
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      });
  }

  // --- HELPERS ---

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

  // Fix 3: Sleep Display Logic
  String _getSleepStatus() {
      if (_lastSleep == null) return "None";
      if (_lastSleep!['end_time'] == null) {
          // Active: Show Duration
          final start = _parseUtc(_lastSleep!['start_time']).toLocal();
          final duration = DateTime.now().difference(start);
          return "Sleeping for ${_formatDurationSimple(duration)}";
      } else {
          // Finished: Show "Slept Xh ago" based on endTime
          final end = _parseUtc(_lastSleep!['end_time']).toLocal();
          final ago = DateTime.now().difference(end);
          return "Slept ${_formatDurationSimple(ago)} ago"; 
      }
  }

  String _formatDurationSimple(Duration d) {
      if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
      return "${d.inMinutes}m";
  }

  // Fix 2: Next Feed Logic
  String _calculateNextFeed() {
      if (_lastFeed == null) return "Start a feed!";
      if (_lastFeed!['next_due'] == null) return "No Reminder Set"; 

      try {
          final next = _parseUtc(_lastFeed!['next_due']).toLocal();
          final now = DateTime.now();
          final diff = next.difference(now);
          
          if (diff.isNegative) {
             return "Overdue by ${_formatDurationSimple(diff.abs())}"; // Fix 4: Overdue
          }
          
          if (diff.inHours > 0) return "${diff.inHours}h ${diff.inMinutes.remainder(60)}m left";
          return "${diff.inMinutes}m left";
      } catch (e) {
          return "--";
      }
  }

  String _calculateNextFeedTime() {
       if (_lastFeed == null || _lastFeed!['next_due'] == null) return "";
       try {
           final next = _parseUtc(_lastFeed!['next_due']).toLocal();
           return "@ ${DateFormat('h:mm a').format(next)}";
       } catch (e) {
           return "";
       }
  }

  Future<void> _setNextFeedTime() async {
      if (_lastFeed == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Log a feed first!")));
          return;
      }

      final TimeOfDay? time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
          helpText: "Set Next Feed Reminder"
      );

      if (time != null) {
           final now = DateTime.now();
           var nextDate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
           if (nextDate.isBefore(now)) {
               nextDate = nextDate.add(const Duration(days: 1)); 
           }

           setState(() => _isLoading = true);

           // Update DB
           final service = context.read<SupabaseService>();
           // Fix 4a: Convert manual time to UTC before saving
           await service.updateFeed(_lastFeed!['id'], {'next_due': nextDate.toUtc().toIso8601String()});
           
           // Refresh
           final freshFeed = await service.getLastFeed();

           setState(() {
               _lastFeed = freshFeed;
               _isLoading = false;
           });
           
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reminder Set!")));
      }
  }

  // Diaper Logic
  String _getDiaperCount() {
       final now = DateTime.now();
       final todayLogs = _diaperLogs.where((l) {
           final date = _parseUtc(l['created_at']).toLocal();
           return date.year == now.year && date.month == now.month && date.day == now.day;
       }).toList();
 
       int pee = todayLogs.where((l) => l['type'] == 'pee' || l['type'] == 'both').length;
       int poop = todayLogs.where((l) => l['type'] == 'poop' || l['type'] == 'both').length;
 
       return "$pee 💧  $poop 💩";
   }

  String _getLastDiaperTime() {
      if (_diaperLogs.isEmpty) return "None today";
      final last = _diaperLogs.first; // Already sorted desc
      return "Last: ${_formatTime(last['created_at'])}";
  }
 
  void _logDiaper() {
       showModalBottomSheet(
           context: context,
           builder: (context) => Container(
               padding: const EdgeInsets.all(24),
               child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                       Text("Log Diaper", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 24),
                       Row(
                           mainAxisAlignment: MainAxisAlignment.spaceAround,
                           children: [
                               _buildDiaperBtn("Pee", "💧", Colors.blue, 'pee'),
                               _buildDiaperBtn("Poop", "💩", Colors.brown, 'poop'),
                               _buildDiaperBtn("Both", "🤢", Colors.orange, 'both'),
                           ],
                       ),
                       const SizedBox(height: 24),
                   ],
               ),
           ),
       );
   }
 
  Widget _buildDiaperBtn(String label, String emoji, Color color, String type) {
       return InkWell(
           onTap: () {
               Navigator.pop(context);
               _saveDiaperLog(type);
           },
           child: Column(
               children: [
                   Container(
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                       child: Text(emoji, style: const TextStyle(fontSize: 32)),
                   ),
                   const SizedBox(height: 8),
                   Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
               ],
           ),
       );
   }
 
  Future<void> _saveDiaperLog(String type) async {
       setState(() => _isLoading = true);
       final userId = context.read<SupabaseService>().currentUser?.id;
       if (userId != null) {
           await context.read<SupabaseService>().saveDiaperLog({
               'id': const Uuid().v4(),
               'user_id': userId,
               'type': type,
               'created_at': DateTime.now().toUtc().toIso8601String(),
           });
           await _loadData();
       }
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Diaper Logged!")));
   }
}
