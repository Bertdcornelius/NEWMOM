import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../repositories/care_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/premium_ui_components.dart';

class PostpartumWellnessScreen extends StatefulWidget {
  const PostpartumWellnessScreen({super.key});

  @override
  State<PostpartumWellnessScreen> createState() => _PostpartumWellnessScreenState();
}

class _PostpartumWellnessScreenState extends State<PostpartumWellnessScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _moodLogs = [];
  bool _showEpdsPrompt = false;

  final List<Map<String, dynamic>> _moodOptions = [
    {'label': 'Great', 'emoji': '✨', 'score': 5, 'color': Colors.greenAccent.shade700},
    {'label': 'Good', 'emoji': '😊', 'score': 4, 'color': Colors.lightGreen},
    {'label': 'Okay', 'emoji': '😐', 'score': 3, 'color': Colors.orangeAccent},
    {'label': 'Tough', 'emoji': '😮‍💨', 'score': 2, 'color': Colors.deepOrangeAccent},
    {'label': 'Struggling', 'emoji': '🌧️', 'score': 1, 'color': Colors.redAccent},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = context.read<CareRepository>();
    final result = await repo.getMoodLogs();
    if (result.isSuccess && result.data != null) {
      _moodLogs = result.data!;
    }
    _analyzeMoodForEpds();
    if (mounted) setState(() => _isLoading = false);
  }

  void _analyzeMoodForEpds() {
    if (_moodLogs.length < 3) return;
    int lowMoodCount = 0;
    for (var i = 0; i < 3; i++) {
      if ((_moodLogs[i]['score'] as int? ?? 3) <= 2) {
        lowMoodCount++;
      }
    }
    if (lowMoodCount >= 3) {
      _showEpdsPrompt = true;
    }
  }

  Future<void> _logMood(int score) async {
    final auth = context.read<AuthRepository>();
    final user = auth.currentUser;
    if (user == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not logged in. Please sign in first.'), backgroundColor: Colors.red));
      return;
    }

    final newLog = {
      'id': const Uuid().v4(),
      'user_id': user.id,
      'score': score,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    setState(() => _moodLogs.insert(0, newLog));

    final repo = context.read<CareRepository>();
    final result = await repo.saveMoodLog(newLog);
    if (!result.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to save mood'), backgroundColor: Colors.red));
    }

    _analyzeMoodForEpds();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    final todayLogged = _moodLogs.isNotEmpty && 
        DateTime.parse(_moodLogs.first['created_at']).toLocal().day == DateTime.now().day;

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Wellness & Mood', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showEpdsPrompt)
                  _buildEpdsPrompt(colors, typo),
                
                if (_showEpdsPrompt) const SizedBox(height: 24),

                Text('Daily Check-In', style: typo.h2),
                const SizedBox(height: 8),
                Text('How are you feeling today, mama?', style: typo.body.copyWith(color: colors.textSecondary)),
                const SizedBox(height: 16),

                if (todayLogged)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.sereneBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.sereneBlue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text('🌱', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text('Mood Logged Today', style: typo.title),
                        const SizedBox(height: 4),
                        Text('Thank you for checking in with yourself.', textAlign: TextAlign.center, style: typo.body.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  )
                else
                  Column(
                    children: _moodOptions.map((mood) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _logMood(mood['score']),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surfaceMuted,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.transparent),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: (mood['color'] as Color).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(child: Text(mood['emoji'] as String, style: const TextStyle(fontSize: 24))),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(mood['label'] as String, style: typo.bodyBold.copyWith(fontSize: 16)),
                              ),
                              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    )).toList(),
                  ),

                const SizedBox(height: 32),
                
                Text('Recent History', style: typo.h2),
                const SizedBox(height: 16),

                if (_moodLogs.isEmpty)
                  Text('No mood logs yet. Start checking in daily!', style: typo.body.copyWith(color: colors.textSecondary))
                else
                  ..._moodLogs.take(7).map((log) {
                    final score = log['score'] as int? ?? 3;
                    final moodOpt = _moodOptions.firstWhere((o) => o['score'] == score, orElse: () => _moodOptions[2]);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DataTile(
                        child: Row(
                          children: [
                            Text(moodOpt['emoji'] as String, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 16),
                            Expanded(child: Text(moodOpt['label'] as String, style: typo.bodyBold)),
                            Text(DateFormat('MMM d').format(DateTime.parse(log['created_at']).toLocal()), style: typo.caption),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 80),
              ],
            ),
          ),
    );
  }

  Widget _buildEpdsPrompt(PremiumColors colors, PremiumTypography typo) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.warmPeach.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.warmPeach, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: colors.warmPeach, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text('Extra Support Needed?', style: typo.title)),
            ],
          ),
          const SizedBox(height: 16),
          Text('You\'ve logged some tough days recently. Postpartum depression is common and treatable. Would you like to take a quick, standard assessment (EPDS) to help understand how you\'re feeling?', style: typo.body.copyWith(height: 1.5)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: PremiumActionButton(
              label: 'Take Assessment',
              icon: Icons.shield_rounded,
              color: colors.warmPeach,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('EPDS Survey would launch here.')));
              },
            ),
          ),
        ],
      ),
    );
  }
}
