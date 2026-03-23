import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/feeding_viewmodel.dart';
import '../../widgets/premium_ui_components.dart';

class FeedingScreen extends StatefulWidget {
  const FeedingScreen({super.key});

  @override
  State<FeedingScreen> createState() => _FeedingScreenState();
}

class _FeedingScreenState extends State<FeedingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _solidTypeController = TextEditingController();
  final TextEditingController _reminderNoteController = TextEditingController();
  final List<String> _solidQuickTags = ['Puree', 'Mashed', 'Chunks', 'Fruit', 'Veggie', 'Cereal', 'Meat'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _solidTypeController.dispose();
    _reminderNoteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(FeedingViewModel vm) async {
      final now = DateTime.now();
      final date = await showDatePicker(
          context: context,
          initialDate: vm.selectedDate,
          firstDate: DateTime(2024),
          lastDate: now,
      );
      if (date == null) return;

      if (!mounted) return;
      final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(vm.selectedDate),
      );
      if (time == null) return;

      final combinedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (combinedDate.isAfter(now)) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot select future time!")));
          return;
      }

      vm.setDate(combinedDate);
  }

  Widget _buildDateSelectorRow(FeedingViewModel vm) {
      return DataTile(
          onTap: () => _pickDateTime(vm),
          backgroundColor: PremiumColors(context).surface,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                      Text("Date & Time", style: PremiumTypography(context).body),
                      Row(
                          children: [
                              Text(DateFormat('MMM d, h:mm a').format(vm.selectedDate), style: PremiumTypography(context).bodyBold),
                              const SizedBox(width: 8),
                              Icon(Icons.edit_calendar_rounded, size: 20, color: PremiumColors(context).textSecondary),
                          ],
                      ),
                  ],
              ),
          );
  }

  Widget _buildReminderSection(FeedingViewModel vm) {
      return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: PremiumCard(
              padding: const EdgeInsets.all(16),
              child: Column(
              children: [
                  Row(
                      children: [
                          PremiumBubbleIcon(icon: Icons.notifications_active_rounded, color: PremiumColors(context).sereneBlue, size: 20, padding: 8),
                          const SizedBox(width: 12),
                          Text("Remind me next time?", style: PremiumTypography(context).bodyBold),
                          const Spacer(),
                          Switch(value: vm.remindMe, activeThumbColor: PremiumColors(context).warmPeach, onChanged: (v) => vm.setRemindMe(v)),
                      ],
                  ),
                  if (vm.activeReminderCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 44),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 16, color: PremiumColors(context).sageGreen),
                          const SizedBox(width: 6),
                          Text('${vm.activeReminderCount} active reminder${vm.activeReminderCount == 1 ? '' : 's'}',
                            style: PremiumTypography(context).caption.copyWith(color: PremiumColors(context).sageGreen)),
                        ],
                      ),
                    ),
                  if (vm.remindMe) ...[
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: [
                                _buildReminderChip(vm, "3 Hrs", 3, null),
                                const SizedBox(width: 8),
                                _buildReminderChip(vm, "4 Hrs", 4, null),
                                const SizedBox(width: 8),
                                ActionChip(
                                    label: Text(vm.customReminderTime == null ? "Custom" : vm.customReminderTime!.format(context), style: TextStyle(color: vm.customReminderTime != null ? Colors.white : PremiumColors(context).textPrimary, fontWeight: FontWeight.bold)),
                                    avatar: Icon(Icons.access_time_rounded, size: 16, color: vm.customReminderTime != null ? Colors.white : PremiumColors(context).textSecondary),
                                    backgroundColor: vm.customReminderTime != null ? PremiumColors(context).warmPeach : PremiumColors(context).surfaceMuted,
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    onPressed: () async {
                                        final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                        if (t != null) vm.setCustomReminderTime(t);
                                    },
                                ),
                            ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _reminderNoteController,
                        decoration: InputDecoration(
                          labelText: 'Reminder note (optional)',
                          hintText: 'e.g. Next is Bottle feed',
                          prefixIcon: Icon(Icons.note_alt_outlined, size: 20, color: PremiumColors(context).textSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: PremiumColors(context).surfaceMuted)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: PremiumColors(context).surfaceMuted)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: PremiumColors(context).warmPeach)),
                          filled: true,
                          fillColor: PremiumColors(context).surfaceMuted.withValues(alpha: 0.3),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        style: PremiumTypography(context).body,
                      ),
                  ]
              ],
            ),
          ),
      );
  }

  Widget _buildReminderChip(FeedingViewModel vm, String label, int hours, TimeOfDay? custom) {
      final isSelected = vm.reminderInterval == hours && vm.customReminderTime == custom;
      return ChoiceChip(
          label: Text(label, style: TextStyle(color: isSelected ? Colors.white : PremiumColors(context).textPrimary, fontWeight: FontWeight.bold)),
          selected: isSelected,
          selectedColor: PremiumColors(context).warmPeach,
          backgroundColor: PremiumColors(context).surfaceMuted,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onSelected: (b) { if(b) { vm.setReminderInterval(hours); vm.setCustomReminderTime(custom); } },
      );
  }

  Future<void> _handleSave(FeedingViewModel vm, String type) async {
    final success = await vm.saveFeed(type, _solidTypeController.text, _reminderNoteController.text);
    if (success && mounted) {
      if (vm.remindMe) {
        String timeStr = "None";
        if (vm.customReminderTime != null) {
          timeStr = DateFormat('h:mm a').format(DateTime(2024,1,1,vm.customReminderTime!.hour, vm.customReminderTime!.minute));
        } else {
          timeStr = DateFormat('h:mm a').format(vm.selectedDate.add(Duration(hours: vm.reminderInterval)));
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feed Saved! Next: $timeStr')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feed Saved!')));
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeedingViewModel>();

    return PremiumScaffold(
      appBar: AppBar(
        title: const Hero(tag: 'feeding_card_title', child: Text('Feeding Tracker')),
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
      body: Hero(
        tag: 'feeding_card',
        child: Material(
          color: Colors.transparent,
          child: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBreastFeedTab(vm),
                        _buildBottleFeedTab(vm),
                        _buildSolidFeedTab(vm),
                      ],
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildBreastFeedTab(FeedingViewModel vm) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildDateSelectorRow(vm),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSideSwitcher(vm, 'L', 'Left Breast'),
                const SizedBox(width: 24),
                _buildSideSwitcher(vm, 'R', 'Right Breast'),
              ],
            ),
            const SizedBox(height: 40),
            
            // Ultra Premium Timer Ring
            GestureDetector(
              onTap: vm.toggleTimer,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glowing rings
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    width: vm.isTimerRunning ? 260 : 220,
                    height: vm.isTimerRunning ? 260 : 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PremiumColors(context).warmPeach.withValues(alpha: vm.isTimerRunning ? 0.05 : 0.0),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    width: vm.isTimerRunning ? 220 : 200,
                    height: vm.isTimerRunning ? 220 : 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PremiumColors(context).warmPeach.withValues(alpha: vm.isTimerRunning ? 0.1 : 0.0),
                    ),
                  ),
                  // Inner solid button
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: vm.isTimerRunning 
                              ? [const Color(0xFFFF9E80), const Color(0xFFFF7043)]
                              : [PremiumColors(context).surface, PremiumColors(context).surfaceMuted],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: vm.isTimerRunning ? const Color(0xFFFF9E80).withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          )
                        ]
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Text(vm.formattedStopwatch, style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: vm.isTimerRunning ? Colors.white : PremiumColors(context).textPrimary, fontFeatures: const [FontFeature.tabularFigures()])),
                            const SizedBox(height: 8),
                            Icon(vm.isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: vm.isTimerRunning ? Colors.white : PremiumColors(context).warmPeach, size: 40),
                            const SizedBox(height: 4),
                            Text(vm.isTimerRunning ? "PAUSE" : "START", style: PremiumTypography(context).caption.copyWith(color: vm.isTimerRunning ? Colors.white70 : PremiumColors(context).textSecondary, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            PremiumCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Suckling Time', style: PremiumTypography(context).bodyBold),
                      Text('${vm.durationMinutes} min', style: PremiumTypography(context).h2.copyWith(color: PremiumColors(context).warmPeach)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: PremiumColors(context).warmPeach,
                      inactiveTrackColor: PremiumColors(context).surfaceMuted,
                      thumbColor: PremiumColors(context).warmPeach,
                      overlayColor: PremiumColors(context).warmPeach.withValues(alpha: 0.2),
                      trackHeight: 8,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                    ),
                    child: Slider(
                      value: vm.durationMinutes.toDouble(),
                      min: 1, max: 60, divisions: 59,
                      onChanged: (val) => vm.setDuration(val.toInt()),
                    ),
                  ),
                ],
              ),
            ),

            _buildReminderSection(vm),
            const SizedBox(height: 48),
            PremiumActionButton(
              label: 'Save Breast Feed',
              icon: Icons.check_circle_rounded,
              color: PremiumColors(context).warmPeach,
              onTap: () => _handleSave(vm, 'breast'),
            ),
            const SizedBox(height: 32),
          ],
        ),
    );
  }

  Widget _buildBottleFeedTab(FeedingViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildDateSelectorRow(vm),
          const SizedBox(height: 32),
          
          Container(
              width: 220, height: 220,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                gradient: RadialGradient(
                  colors: [PremiumColors(context).sereneBlue.withValues(alpha: 0.1), Colors.transparent],
                  stops: const [0.5, 1.0],
                )
              ),
              child: Container(
                width: 170, height: 170,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: PremiumColors(context).surface, 
                  border: Border.all(color: PremiumColors(context).sereneBlue.withValues(alpha: 0.3), width: 8), 
                  boxShadow: [BoxShadow(color: PremiumColors(context).sereneBlue.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 12))]
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${vm.amountMl}', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: PremiumColors(context).sereneBlue, height: 1.0)),
                    Text('ml', style: PremiumTypography(context).bodyBold.copyWith(color: PremiumColors(context).textSecondary)),
                  ],
                ),
              ),
          ),
          const SizedBox(height: 32),
          
          PremiumCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Volume', style: PremiumTypography(context).bodyBold),
                    Icon(Icons.water_drop_rounded, color: PremiumColors(context).sereneBlue, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: PremiumColors(context).sereneBlue,
                    inactiveTrackColor: PremiumColors(context).surfaceMuted,
                    thumbColor: PremiumColors(context).sereneBlue,
                    overlayColor: PremiumColors(context).sereneBlue.withValues(alpha: 0.2),
                    trackHeight: 12,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                  ),
                  child: Slider(
                    value: vm.amountMl.toDouble(),
                    min: 10, max: 300, divisions: 29,
                    onChanged: (val) => vm.setAmount(val.toInt()),
                  ),
                ),
              ],
            ),
          ),
          
          _buildReminderSection(vm),
          const SizedBox(height: 48),
          PremiumActionButton(
            label: 'Save Bottle Feed',
            icon: Icons.check_circle_rounded,
            color: PremiumColors(context).sereneBlue,
            onTap: () => _handleSave(vm, 'bottle'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSolidFeedTab(FeedingViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateSelectorRow(vm),
          const SizedBox(height: 32),
          
          Text('What did baby eat?', style: PremiumTypography(context).h2),
          const SizedBox(height: 12),
          TextField(
            controller: _solidTypeController,
            decoration: InputDecoration(
              hintText: 'e.g., Sweet Potato Puree, Banana',
              filled: true,
              fillColor: PremiumColors(context).surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              prefixIcon: Icon(Icons.restaurant_rounded, color: PremiumColors(context).sageGreen),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            ),
            style: PremiumTypography(context).bodyBold,
          ),
          const SizedBox(height: 20),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _solidQuickTags.map((tag) => ActionChip(
              label: Text(tag, style: TextStyle(color: PremiumColors(context).textSecondary, fontWeight: FontWeight.w600)),
              backgroundColor: PremiumColors(context).surfaceMuted,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () {
                final current = _solidTypeController.text;
                if (current.isEmpty) {
                  _solidTypeController.text = tag;
                } else {
                  _solidTypeController.text = "$current, $tag";
                }
              },
            )).toList(),
          ),
          
          const SizedBox(height: 16),
          _buildReminderSection(vm),
          const SizedBox(height: 48),
          PremiumActionButton(
            label: 'Save Solid Food Log',
            icon: Icons.check_circle_rounded,
            color: PremiumColors(context).sageGreen,
            onTap: () => _handleSave(vm, 'solid'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildSideSwitcher(FeedingViewModel vm, String side, String label) {
    final isSelected = vm.selectedSide == side;
    return GestureDetector(
      onTap: () => vm.setSide(side),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? PremiumColors(context).warmPeach : PremiumColors(context).surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? PremiumColors(context).warmPeach : PremiumColors(context).surfaceMuted,
            width: 2,
          ),
          boxShadow: isSelected ? [BoxShadow(color: PremiumColors(context).warmPeach.withValues(alpha:0.3), blurRadius: 16, offset: const Offset(0, 8))] : [],
        ),
        child: Column(
          children: [
            Text(side, style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : PremiumColors(context).textPrimary,
            )),
            const SizedBox(height: 4),
            Text(label, style: PremiumTypography(context).caption.copyWith(color: isSelected ? Colors.white70 : PremiumColors(context).textSecondary)),
          ],
        ),
      ),
    );
  }
}
