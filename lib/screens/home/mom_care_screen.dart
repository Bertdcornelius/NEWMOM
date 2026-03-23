import 'package:flutter/material.dart';
import '../../widgets/premium_ui_components.dart';
import '../../services/local_storage_service.dart';
import '../../repositories/care_repository.dart';
import '../../repositories/auth_repository.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'menstrual_cycle_screen.dart';
import 'postpartum_wellness_screen.dart';
import 'notes_screen.dart';
import '../../widgets/mini_features/hydration_tracker.dart';

class MomCareScreen extends StatefulWidget {
  const MomCareScreen({super.key});

  @override
  State<MomCareScreen> createState() => _MomCareScreenState();
}

class _MomCareScreenState extends State<MomCareScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _checklist = [];
  bool _isLoading = true;
  late AnimationController _progressController;

  static final Map<String, IconData> _taskIcons = {
    'prenatal vitamins': Icons.medication_rounded,
    'vitamins': Icons.medication_rounded,
    'pain medication': Icons.healing_rounded,
    'medication': Icons.healing_rounded,
    'drink': Icons.water_drop_rounded,
    'water': Icons.water_drop_rounded,
    'rest': Icons.self_improvement_rounded,
    'sleep': Icons.bedtime_rounded,
    'yoga': Icons.self_improvement_rounded,
    'exercise': Icons.fitness_center_rounded,
    'walk': Icons.directions_walk_rounded,
    'eat': Icons.restaurant_rounded,
    'meal': Icons.restaurant_rounded,
    'snack': Icons.cookie_rounded,
    'pump': Icons.water_drop_outlined,
    'shower': Icons.shower_rounded,
    'journal': Icons.menu_book_rounded,
    'meditate': Icons.spa_rounded,
    'stretch': Icons.accessibility_new_rounded,
  };

  static final List<Color> _taskColors = [
    const Color(0xFFF28482), // warmPeach
    const Color(0xFFA2D2FF), // sereneBlue
    const Color(0xFF84A59D), // sageGreen
    const Color(0xFFCDB4DB), // gentlePurple
    const Color(0xFFFFB703), // softAmber
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _loadState();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  IconData _getIconForTask(String title) {
    final lower = title.toLowerCase();
    for (final entry in _taskIcons.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return Icons.check_circle_outline_rounded;
  }

  Color _getColorForIndex(int index) => _taskColors[index % _taskColors.length];

  Future<void> _loadState() async {
    final res = await context.read<CareRepository>().getMomCareChecklist();
    
    if (res.isSuccess && (res.data?.isNotEmpty ?? false)) {
        _checklist = res.data!;
        setState(() => _isLoading = false);
        _progressController.forward(from: 0);
    } else {
        _initDefaultList();
    }
  }

  Future<void> _initDefaultList() async {
      final user = context.read<AuthRepository>().currentUser;
      if (user == null) {
          setState(() => _isLoading = false);
          return;
      }
      
      final defaults = ['Prenatal Vitamins', 'Drink 2L Water', 'Rest for 30 mins'];
      for (var title in defaults) {
          final newItem = {
              'id': const Uuid().v4(),
              'user_id': user.id,
              'title': title,
              'checked': false,
              'created_at': DateTime.now().toUtc().toIso8601String(),
          };
          _checklist.add(newItem);
          await context.read<CareRepository>().saveMomCareChecklist(newItem);
      }
      
      setState(() => _isLoading = false);
      _progressController.forward(from: 0);
  }

  Future<void> _toggleItem(int index) async {
    final item = _checklist[index];
    final bool newStatus = !(item['checked'] as bool);
    
    setState(() {
      item['checked'] = newStatus;
      
      // Auto-sort completed to bottom
      if (newStatus) {
         _checklist.removeAt(index);
         _checklist.add(item);
      } else {
         _checklist.removeAt(index);
         _checklist.insert(0, item);
      }
    });

    await context.read<CareRepository>().updateMomCareChecklist(item['id'], {'checked': newStatus});
    _progressController.forward(from: 0);
  }

  int get _completedCount => _checklist.where((i) => i['checked'] == true).length;
  double get _progress => _checklist.isEmpty ? 0 : _completedCount / _checklist.length;

  void _addItem() {
      final controller = TextEditingController();
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              backgroundColor: PremiumColors(context).surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text("New Self-Care Goal", style: PremiumTypography(context).h2),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: PremiumTypography(context).title,
                    decoration: InputDecoration(
                      labelText: "Task Name",
                      hintText: "e.g. Yoga, Meditate, Walk",
                      filled: true,
                      fillColor: PremiumColors(context).surfaceMuted,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: Icon(Icons.add_task_rounded, color: PremiumColors(context).sageGreen),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['Yoga', 'Meditate', 'Walk', 'Journal'].map((s) =>
                      ActionChip(
                        label: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: PremiumColors(context).sageGreen.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        onPressed: () => controller.text = s,
                      ),
                    ).toList(),
                  ),
                ],
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel", style: TextStyle(color: PremiumColors(context).textSecondary))),
                  TextButton(
                      onPressed: () async {
                          if (controller.text.isNotEmpty) {
                              final user = context.read<AuthRepository>().currentUser;
                              if (user != null) {
                                  final newItem = {
                                      'id': const Uuid().v4(),
                                      'user_id': user.id,
                                      'title': controller.text.trim(),
                                      'checked': false,
                                      'created_at': DateTime.now().toUtc().toIso8601String(),
                                  };
                                   setState(() => _checklist.insert(0, newItem));
                                   final result = await context.read<CareRepository>().saveMomCareChecklist(newItem);
                                   if (!result.isSuccess && mounted) {
                                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to save'), backgroundColor: Colors.red));
                                   }
                                  _progressController.forward(from: 0);
                              }
                              Navigator.pop(context);
                          }
                      }, 
                      child: Text("Add", style: TextStyle(fontWeight: FontWeight.bold, color: PremiumColors(context).sageGreen)),
                  )
              ],
          ),
      );
  }

  void _deleteItem(int index) async {
      final id = _checklist[index]['id'];
      setState(() => _checklist.removeAt(index));
      await context.read<CareRepository>().deleteMomCareChecklist(id);
      _progressController.forward(from: 0);
  }

  Future<void> _resetAll() async {
      final repo = context.read<CareRepository>();
      setState(() { for (var item in _checklist) { item['checked'] = false; } });
      
      for (var item in _checklist) {
         repo.updateMomCareChecklist(item['id'], {'checked': false});
      }
      _progressController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PremiumScaffold(
         appBar: AppBar(backgroundColor: Colors.transparent),
         body: const Center(child: CircularProgressIndicator())
      );
    }

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Wellness Hub', style: PremiumTypography(context).h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_checklist.any((i) => i['checked'] == true))
            IconButton(
              onPressed: _resetAll,
              icon: Icon(Icons.refresh_rounded, color: PremiumColors(context).softAmber),
              tooltip: 'Reset dailies',
            ),
        ],
      ),
      body: SingleChildScrollView(
         physics: const BouncingScrollPhysics(),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildProgressHeader(),
               const SizedBox(height: 32),
               
               Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Wellness Tools", style: PremiumTypography(context).h2),
               ),
               const SizedBox(height: 16),
               _buildToolsCarousel(),
               
               const SizedBox(height: 32),
               const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: HydrationTracker(),
               ),
               
               const SizedBox(height: 32),
               Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Text("Daily Goals", style: PremiumTypography(context).h2),
                     ]
                  ),
               ),
               const SizedBox(height: 16),
               _buildChecklist(),
               
               // Inline Add Habit Button
               Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: PremiumActionButton(
                      label: "Add Habit",
                      icon: Icons.add_rounded,
                      color: PremiumColors(context).textSecondary,
                      onTap: _addItem,
                  ),
               ),
               const SizedBox(height: 100),
            ],
         ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    final completedText = _completedCount == _checklist.length && _checklist.isNotEmpty
        ? "All done! You're amazing 🎉"
        : "$_completedCount of ${_checklist.length} goals crushed";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [PremiumColors(context).warmPeach, const Color(0xFFF0A080)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: PremiumColors(context).warmPeach.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8))]
          ),
          child: Row(
            children: [
              // Animated circular progress
              SizedBox(
                width: 72, height: 72,
                child: AnimatedBuilder(
                  animation: _progressController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _CircularProgressPainter(
                        progress: _progress * _progressController.value,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        progressColor: Colors.white,
                        strokeWidth: 6,
                      ),
                      child: Center(
                        child: Text("${(_progress * 100).toInt()}%", style: PremiumTypography(context).h2.copyWith(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Progress", style: PremiumTypography(context).h2.copyWith(color: Colors.white, fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(completedText, style: PremiumTypography(context).body.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolsCarousel() {
      return SizedBox(
          height: 140,
          child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              children: [
                  _buildToolCard(
                      "Cycle Tracker", "Log your period", 
                      Icons.water_drop_rounded, 
                      const Color(0xFFE8A0A0), 
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MenstrualCycleScreen()))
                  ),
                  const SizedBox(width: 16),
                  _buildToolCard(
                      "Postpartum Check", "Wellness pulse", 
                      Icons.favorite_rounded, 
                      PremiumColors(context).sereneBlue, 
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostpartumWellnessScreen()))
                  ),
                  const SizedBox(width: 16),
                  _buildToolCard(
                      "Mom's Notes", "Clear your head", 
                      Icons.psychology_rounded, 
                      PremiumColors(context).gentlePurple, 
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()))
                  ),
              ],
          ),
      );
  }

  Widget _buildToolCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
      return GestureDetector(
          onTap: onTap,
          child: Container(
              width: 160,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: PremiumColors(context).surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))
                  ]
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: Icon(icon, color: color, size: 24),
                      ),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text(title, style: PremiumTypography(context).bodyBold),
                              const SizedBox(height: 4),
                              Text(subtitle, style: PremiumTypography(context).caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                      )
                  ],
              ),
          ),
      );
  }

  Widget _buildChecklist() {
      if (_checklist.isEmpty) {
          return Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text("No daily goals set. Take it easy today! ☁️", style: PremiumTypography(context).caption)),
          );
      }
      
      return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _checklist.length,
          itemBuilder: (context, index) {
              final item = _checklist[index];
              final isChecked = item['checked'] as bool;
              final title = item['title'] as String;
              final color = _getColorForIndex(index);
              final icon = _getIconForTask(title);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (index * 80)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(offset: Offset(30 * (1 - value), 0), child: child),
                  ),
                  child: GestureDetector(
                    onTap: () => _toggleItem(index),
                    onLongPress: () => _deleteItem(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: PremiumColors(context).surface,
                        border: Border.all(
                          color: isChecked ? PremiumColors(context).sageGreen.withValues(alpha: 0.5) : Colors.transparent, 
                          width: 2
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isChecked ? PremiumColors(context).sageGreen.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Row(
                        children: [
                          // Animated checkmark
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isChecked ? PremiumColors(context).sageGreen : color.withValues(alpha: 0.1),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: isChecked
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18, key: ValueKey('check'))
                                  : Icon(icon, color: color, size: 18, key: const ValueKey('icon')),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: PremiumTypography(context).title.copyWith(
                                decoration: isChecked ? TextDecoration.lineThrough : null,
                                color: isChecked 
                                    ? PremiumColors(context).textSecondary.withValues(alpha: 0.6)
                                    : PremiumColors(context).textPrimary,
                                fontSize: 18,
                              ),
                              child: Text(title),
                            ),
                          ),
                          if (isChecked) 
                              Icon(Icons.star_rounded, color: PremiumColors(context).softAmber, size: 18)
                        ],
                      ),
                    ),
                  ),
                ),
              );
          }
      );
  }
}

// Custom circular progress painter
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    this.strokeWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return progress != oldDelegate.progress || progressColor != oldDelegate.progressColor;
  }
}
