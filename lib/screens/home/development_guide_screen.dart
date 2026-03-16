import 'package:flutter/material.dart';
import '../../widgets/premium_ui_components.dart';

class DevelopmentGuideScreen extends StatefulWidget {
  const DevelopmentGuideScreen({super.key});

  @override
  State<DevelopmentGuideScreen> createState() => _DevelopmentGuideScreenState();
}

class _DevelopmentGuideScreenState extends State<DevelopmentGuideScreen> {
  int _expandedIndex = -1;

  static const stages = [
    {
      'range': '0 – 3 Months',
      'emoji': '🍼',
      'color': 0xFFF28482,
      'milestones': [
        '👀 Follows objects with eyes',
        '😊 Social smiling begins',
        '🗣 Coos and makes gurgling sounds',
        '💪 Lifts head during tummy time',
        '✊ Grasps objects placed in hand',
        '👂 Startles at loud sounds',
      ],
      'tips': [
        'Do tummy time 3-5 times daily',
        'Talk and sing to your baby often',
        'Respond to cries promptly',
        'Keep black & white contrast toys nearby',
      ],
    },
    {
      'range': '3 – 6 Months',
      'emoji': '🎯',
      'color': 0xFFA2D2FF,
      'milestones': [
        '🔄 Rolls from tummy to back',
        '🤲 Reaches for and grabs toys',
        '😂 Laughs out loud',
        '🍽 Ready for solid food introduction',
        '🗣 Babbles with consonant sounds',
        '🦵 Supports weight on legs when held',
      ],
      'tips': [
        'Introduce single-ingredient foods',
        'Play peek-a-boo for cognitive growth',
        'Provide safe objects to mouth and explore',
        'Establish a consistent bedtime routine',
      ],
    },
    {
      'range': '6 – 9 Months',
      'emoji': '🧸',
      'color': 0xFFCDB4DB,
      'milestones': [
        '🪑 Sits without support',
        '🦀 Starts crawling or scooting',
        '👋 Waves bye-bye',
        '🔍 Develops object permanence',
        '🗣 Says "mama" or "dada" (non-specific)',
        '🍝 Picks up food with pincer grasp',
      ],
      'tips': [
        'Baby-proof your home for crawling',
        'Offer finger foods for self-feeding',
        'Read board books together daily',
        'Name objects and body parts',
      ],
    },
    {
      'range': '9 – 12 Months',
      'emoji': '🎂',
      'color': 0xFFFFB703,
      'milestones': [
        '🧍 Pulls to stand and cruises furniture',
        '👣 May take first steps',
        '👆 Points at things of interest',
        '🗣 Says 1-3 words with meaning',
        '🥤 Drinks from a sippy cup',
        '🎭 Shows separation anxiety',
      ],
      'tips': [
        'Encourage walking with push toys',
        'Set clear and gentle boundaries',
        'Play stacking and sorting games',
        'Celebrate every small achievement!',
      ],
    },
    {
      'range': '12 – 18 Months',
      'emoji': '🚶',
      'color': 0xFF84A59D,
      'milestones': [
        '🚶 Walks independently',
        '🗣 Vocabulary grows to 10-20 words',
        '✏️ Scribbles with crayons',
        '🧩 Stacks 2-3 blocks',
        '🥄 Tries to use a spoon',
        '💃 Dances to music',
      ],
      'tips': [
        'Encourage pretend play',
        'Limit screen time',
        'Offer choices to build independence',
        'Visit parks for gross motor development',
      ],
    },
    {
      'range': '18 – 24 Months',
      'emoji': '🗣',
      'color': 0xFF8D99AE,
      'milestones': [
        '🗣 Combines 2 words ("more milk")',
        '🏃 Runs and climbs',
        '🖍 Draws lines and circles',
        '👫 Parallel play with other kids',
        '👗 Helps undress themselves',
        '🧩 Completes simple puzzles',
      ],
      'tips': [
        'Read together for 15-20 min daily',
        'Encourage social play with peers',
        'Use positive reinforcement',
        'Start introducing potty awareness',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Development Guide', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumCard(
                    child: Row(
                      children: [
                        PremiumBubbleIcon(icon: Icons.auto_stories_rounded, color: colors.sageGreen, size: 24, padding: 14),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Baby Milestones', style: typo.title),
                            Text('What to expect at each stage', style: typo.caption),
                          ],
                        )),
                      ],
                  )),
                  const SizedBox(height: 20),

                  ...List.generate(stages.length, (i) {
                    final stage = stages[i];
                    final isExpanded = _expandedIndex == i;
                    final stageColor = Color(stage['color'] as int);
                    final milestones = stage['milestones'] as List<String>;
                    final tips = stage['tips'] as List<String>;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isExpanded ? stageColor.withValues(alpha: 0.08) : colors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isExpanded ? stageColor : colors.surfaceMuted,
                              width: isExpanded ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: colors.isDark ? 0.15 : 0.06),
                                blurRadius: 16, offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(stage['emoji'] as String, style: const TextStyle(fontSize: 28)),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(stage['range'] as String, style: typo.bodyBold.copyWith(color: stageColor)),
                                      Text('${milestones.length} milestones', style: typo.caption),
                                    ],
                                  )),
                                  AnimatedRotation(
                                    turns: isExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Icon(Icons.keyboard_arrow_down_rounded, color: colors.textMuted),
                                  ),
                                ],
                              ),

                              if (isExpanded) ...[
                                const SizedBox(height: 16),
                                Text('Milestones', style: typo.title.copyWith(color: stageColor)),
                                const SizedBox(height: 8),
                                ...milestones.map((m) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(m, style: typo.body),
                                )),
                                const Divider(height: 24),
                                Text('💡 Tips & Activities', style: typo.title.copyWith(color: stageColor)),
                                const SizedBox(height: 8),
                                ...tips.map((t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('• ', style: typo.body.copyWith(color: stageColor)),
                                      Expanded(child: Text(t, style: typo.body)),
                                    ],
                                  ),
                                )),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
