import 'package:flutter/material.dart';
import '../../widgets/premium_ui_components.dart';
import 'notes_screen.dart';
import 'milestones_screen.dart';
import 'vaccine_screen.dart';
import 'prescription_screen.dart';
import 'growth_tracker_screen.dart';
import 'diaper_screen.dart';
import 'pumping_tracker_screen.dart';
import 'food_intro_screen.dart';
import 'tummy_time_screen.dart';
import 'teething_tracker_screen.dart';
import 'feeding_analytics_screen.dart';
import 'sleep_analytics_screen.dart';
import 'reports_screen.dart';
import 'appointments_screen.dart';
import 'photo_gallery_screen.dart';
import 'white_noise_screen.dart';
import 'development_guide_screen.dart';
import 'babysitter_mode_screen.dart';
import 'data_export_screen.dart';
import 'family_sharing_screen.dart';
import 'milk_stash_screen.dart';
import 'emergency_hub_screen.dart';
import 'postpartum_wellness_screen.dart';
import 'baby_book_generator.dart';
import 'ai_chat_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    if (_isLoading) return _buildShimmerLoading();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: colors.sageGreen,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 16),
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Explore', style: typo.h1),
                  const SizedBox(height: 4),
                  Text('Track & manage everything for your baby', style: typo.body),
                ],
              )),
            const SizedBox(height: 24),
            
            // AI Spotlight Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AIChatScreen()));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6E85B7), Color(0xFFB39DDB)], // Deep Serene Blue to Soft Purple
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6E85B7).withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      )
                    ]
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text('NEO AI', style: typo.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            ),
                            const SizedBox(height: 16),
                            Text('Ask anything about your baby\'s health.', style: typo.h2.copyWith(color: Colors.white, fontSize: 24)),
                            const SizedBox(height: 8),
                            Text('24/7 Pediatric knowledge at your fingertips.', style: typo.body.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 36),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Grouped List of Features
            _buildGroupedList(),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // Build features list — cached to avoid rebuilds
  List<Map<String, dynamic>> _buildFeatures() => [
    {'cat': 'Trackers', 'title': 'Milestones', 'sub': 'Track Growth', 'icon': Icons.star_rounded, 'color': PremiumColors(context).softAmber, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MilestonesScreen()))},
    {'cat': 'Trackers', 'title': 'Growth', 'sub': 'Height & Weight', 'icon': Icons.show_chart_rounded, 'color': PremiumColors(context).warmPeach, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrowthTrackerScreen()))},
    {'cat': 'Trackers', 'title': 'Diapers', 'sub': 'Full Tracker', 'icon': Icons.child_care_rounded, 'color': Colors.brown, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiaperScreen()))},
    {'cat': 'Trackers', 'title': 'Pumping', 'sub': 'Sessions', 'icon': Icons.water_drop_outlined, 'color': PremiumColors(context).gentlePurple, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PumpingTrackerScreen()))},
    {'cat': 'Trackers', 'title': 'Milk Stash', 'sub': 'Inventory', 'icon': Icons.kitchen_rounded, 'color': PremiumColors(context).sereneBlue, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MilkStashScreen()))},
    {'cat': 'Trackers', 'title': 'Solid Foods', 'sub': 'Intro Log', 'icon': Icons.restaurant_rounded, 'color': PremiumColors(context).sageGreen, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodIntroScreen()))},
    {'cat': 'Trackers', 'title': 'Tummy Time', 'sub': 'Timer & Goals', 'icon': Icons.timer_rounded, 'color': PremiumColors(context).softAmber, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TummyTimeScreen()))},
    {'cat': 'Trackers', 'title': 'Teething', 'sub': 'Tooth Chart', 'icon': Icons.mood_rounded, 'color': PremiumColors(context).warmPeach, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeethingTrackerScreen()))},
    
    // Analytics
    {'cat': 'Analytics', 'title': 'Feed Stats', 'sub': 'Charts & Trends', 'icon': Icons.bar_chart_rounded, 'color': PremiumColors(context).warmPeach, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedingAnalyticsScreen()))},
    {'cat': 'Analytics', 'title': 'Sleep Stats', 'sub': 'Day vs Night', 'icon': Icons.nightlight_rounded, 'color': PremiumColors(context).sereneBlue, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepAnalyticsScreen()))},
    {'cat': 'Analytics', 'title': 'Reports', 'sub': 'Weekly Summary', 'icon': Icons.summarize_rounded, 'color': PremiumColors(context).sageGreen, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))},
    
    // Health
    {'cat': 'Health', 'title': 'Emergency Hub', 'sub': 'Dosages & CPR', 'icon': Icons.local_hospital_rounded, 'color': Colors.red, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyHubScreen()))},
    {'cat': 'Health', 'title': 'Vaccines', 'sub': 'Medical Records', 'icon': Icons.vaccines_rounded, 'color': PremiumColors(context).sageGreen, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaccineScreen()))},
    {'cat': 'Health', 'title': 'Meds & Rx', 'sub': 'Prescriptions', 'icon': Icons.medication_rounded, 'color': PremiumColors(context).sereneBlue, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrescriptionScreen()))},
    {'cat': 'Health', 'title': 'Appointments', 'sub': 'Doctor Visits', 'icon': Icons.calendar_month_rounded, 'color': PremiumColors(context).softAmber, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsScreen()))},
    
    // Lifestyle
    {'cat': 'Lifestyle', 'title': 'Postpartum', 'sub': 'Wellness Check', 'icon': Icons.favorite_rounded, 'color': PremiumColors(context).warmPeach, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostpartumWellnessScreen()))},
    {'cat': 'Lifestyle', 'title': 'Mom\'s Brain', 'sub': 'Notes', 'icon': Icons.psychology_rounded, 'color': PremiumColors(context).gentlePurple, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()))},
    {'cat': 'Lifestyle', 'title': 'Photos', 'sub': 'Baby Gallery', 'icon': Icons.photo_library_rounded, 'color': PremiumColors(context).gentlePurple, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoGalleryScreen()))},
    {'cat': 'Lifestyle', 'title': 'White Noise', 'sub': 'Lullabies', 'icon': Icons.music_note_rounded, 'color': PremiumColors(context).sereneBlue, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhiteNoiseScreen()))},
    {'cat': 'Lifestyle', 'title': 'Dev Guide', 'sub': 'By Age', 'icon': Icons.auto_stories_rounded, 'color': PremiumColors(context).sageGreen, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DevelopmentGuideScreen()))},
    {'cat': 'Lifestyle', 'title': 'Babysitter', 'sub': 'Guest Mode', 'icon': Icons.child_friendly_rounded, 'color': Colors.teal, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BabysitterModeScreen()))},

    // Tools / God Mode
    {'cat': 'Tools', 'title': 'Baby Book', 'sub': 'Auto Posters', 'icon': Icons.auto_awesome_rounded, 'color': PremiumColors(context).warmPeach, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BabyBookGeneratorScreen()))},
    {'cat': 'Tools', 'title': 'Export Data', 'sub': 'CSV Reports', 'icon': Icons.download_rounded, 'color': PremiumColors(context).sereneBlue, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DataExportScreen()))},
    {'cat': 'Tools', 'title': 'Family Share', 'sub': 'Invite Co-parents', 'icon': Icons.people_rounded, 'color': PremiumColors(context).gentlePurple, 'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilySharingScreen()))},
  ];

  Widget _buildGroupedList() {
    final categories = ['Trackers', 'Analytics', 'Health', 'Lifestyle', 'Tools'];
    final typo = PremiumTypography(context);
    final allFeatures = _buildFeatures();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: categories.map((cat) {
          final items = allFeatures.where((f) => f['cat'] == cat).toList();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                child: Text(
                  cat.toUpperCase(),
                  style: typo.caption.copyWith(letterSpacing: 2.0, color: PremiumColors(context).textMuted),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final feat = items[index];
                  return _ScaleOnTapItem(
                    onTap: () => feat['onTap'](),
                    child: PremiumCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          PremiumBubbleIcon(
                            icon: feat['icon'],
                            color: feat['color'],
                            size: 28,
                            padding: 14,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(feat['title'], style: typo.title.copyWith(fontSize: 18)),
                              ),
                              const SizedBox(height: 4),
                              Text(feat['sub'], style: typo.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Shimmer loading skeleton
  Widget _buildShimmerLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerBase = isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE8E8EC);
    final shimmerHighlight = isDark ? const Color(0xFF3A3A3E) : const Color(0xFFF5F5F9);

    Widget shimmerBox({double width = double.infinity, double height = 20, double radius = 12}) {
      return RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1200),
          builder: (context, value, child) {
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment(-1.0 + (value * 3), 0),
                  end: Alignment(-0.5 + (value * 3), 0),
                  colors: [shimmerBase, shimmerHighlight, shimmerBase],
                ),
              ),
            );
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          shimmerBox(width: 100, height: 28),
          const SizedBox(height: 8),
          shimmerBox(width: 200, height: 16),
          const SizedBox(height: 24),
          shimmerBox(width: double.infinity, height: 56, radius: 24),
          const SizedBox(height: 12),
          shimmerBox(width: double.infinity, height: 56, radius: 24),
          const SizedBox(height: 12),
          shimmerBox(width: double.infinity, height: 56, radius: 24),
          const SizedBox(height: 32),
          shimmerBox(width: 100, height: 22),
          const SizedBox(height: 16),
          shimmerBox(width: double.infinity, height: 56, radius: 24),
          const SizedBox(height: 12),
          shimmerBox(width: double.infinity, height: 56, radius: 24),
        ],
      ),
    );
  }
}

// Scale-on-tap micro-interaction for feature list items
class _ScaleOnTapItem extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _ScaleOnTapItem({required this.child, this.onTap});

  @override
  State<_ScaleOnTapItem> createState() => _ScaleOnTapItemState();
}

class _ScaleOnTapItemState extends State<_ScaleOnTapItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
