import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../services/local_storage_service.dart';
import '../../widgets/premium_ui_components.dart';

class FoodIntroScreen extends StatefulWidget {
  const FoodIntroScreen({super.key});

  @override
  State<FoodIntroScreen> createState() => _FoodIntroScreenState();
}

class _FoodIntroScreenState extends State<FoodIntroScreen> {
  List<Map<String, dynamic>> _foods = [];
  String _selectedCategory = 'All';

  static const categories = ['All', 'Fruits', 'Veggies', 'Grains', 'Protein', 'Dairy'];
  static const categoryEmojis = {'Fruits': '🍎', 'Veggies': '🥦', 'Grains': '🌾', 'Protein': '🍗', 'Dairy': '🧀'};
  static const reactionColors = {'none': Colors.green, 'mild': Colors.orange, 'allergic': Colors.red};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadData() {
    final ls = context.read<LocalStorageService>();
    final raw = ls.getString('food_intro_list');
    if (raw != null) _foods = List<Map<String, dynamic>>.from(jsonDecode(raw));
    if (mounted) setState(() {});
  }

  Future<void> _saveData() async {
    final ls = context.read<LocalStorageService>();
    await ls.saveString('food_intro_list', jsonEncode(_foods));
  }

  List<Map<String, dynamic>> get _filteredFoods {
    if (_selectedCategory == 'All') return _foods;
    return _foods.where((f) => f['category'] == _selectedCategory).toList();
  }


  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);
    final filtered = _filteredFoods;

    final safeCount = _foods.where((f) => f['reaction'] == 'none').length;
    final mildCount = _foods.where((f) => f['reaction'] == 'mild').length;
    final allergyCount = _foods.where((f) => f['reaction'] == 'allergic').length;

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Food Introduction', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: colors.sageGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Stats
                  Row(
                    children: [
                      _statChip('✅ $safeCount Safe', Colors.green, colors),
                      const SizedBox(width: 8),
                      _statChip('⚠️ $mildCount Mild', Colors.orange, colors),
                      const SizedBox(width: 8),
                      _statChip('🚫 $allergyCount Allergic', Colors.red, colors),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Category Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? colors.sageGreen : colors.surface,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                cat == 'All' ? '🍽 All' : '${categoryEmojis[cat] ?? ''} $cat',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : colors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Food Grid
                  Text('Introduced Foods (${filtered.length})', style: typo.h2),
                  const SizedBox(height: 12),

                  if (filtered.isEmpty)
                    PremiumCard(child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Column(
                        children: [
                          Icon(Icons.restaurant_rounded, size: 48, color: colors.textMuted),
                          const SizedBox(height: 12),
                          Text('No foods logged yet', style: typo.body),
                          const SizedBox(height: 4),
                          Text('Tap + to add a food', style: typo.caption),
                        ],
                      )),
                    ))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _buildFoodCard(filtered[i], colors, typo, i),
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, Color color, PremiumColors colors) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(label, style: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w700, color: color,
        ))),
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food, PremiumColors colors, PremiumTypography typo, int index) {
    final reaction = food['reaction'] ?? 'none';
    final rColor = reactionColors[reaction] ?? Colors.green;
    final emoji = categoryEmojis[food['category']] ?? '🍽';

    return GestureDetector(
      onLongPress: () => _deleteFood(food),
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: rColor, shape: BoxShape.circle),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(food['name'] ?? '', style: typo.bodyBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(food['date'] ?? '', style: typo.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final nameC = TextEditingController();
    String category = 'Fruits';
    String reaction = 'none';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PremiumColors(context).surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: PremiumColors(context).textMuted, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Log New Food', style: PremiumTypography(context).h2),
              const SizedBox(height: 16),
              TextField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: 'Food Name',
                  prefixIcon: Icon(Icons.restaurant, color: PremiumColors(context).sageGreen),
                  filled: true,
                  fillColor: PremiumColors(context).surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Text('Category', style: PremiumTypography(context).title),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Fruits', 'Veggies', 'Grains', 'Protein', 'Dairy'].map((c) {
                  return ChoiceChip(
                    label: Text('${categoryEmojis[c]} $c'),
                    selected: category == c,
                    onSelected: (v) => setBS(() => category = c),
                    selectedColor: PremiumColors(context).sageGreen.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Reaction', style: PremiumTypography(context).title),
              const SizedBox(height: 8),
              Row(
                children: [
                  _reactionChip('None', 'none', Colors.green, reaction, (v) => setBS(() => reaction = v)),
                  const SizedBox(width: 8),
                  _reactionChip('Mild', 'mild', Colors.orange, reaction, (v) => setBS(() => reaction = v)),
                  const SizedBox(width: 8),
                  _reactionChip('Allergic', 'allergic', Colors.red, reaction, (v) => setBS(() => reaction = v)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PremiumActionButton(
                  label: 'Add Food',
                  icon: Icons.check_circle_outline_rounded,
                  color: PremiumColors(context).sageGreen,
                  onTap: () {
                    if (nameC.text.isEmpty) return;
                    _foods.add({
                      'name': nameC.text,
                      'category': category,
                      'reaction': reaction,
                      'date': DateTime.now().toString().split(' ')[0],
                    });
                    _saveData();
                    Navigator.pop(ctx);
                    _loadData();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reactionChip(String label, String value, Color color, String current, Function(String) onSelect) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : PremiumColors(context).surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
          ),
          child: Center(child: Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? color : PremiumColors(context).textSecondary,
          ))),
        ),
      ),
    );
  }

  void _deleteFood(Map<String, dynamic> food) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${food['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _foods.remove(food);
              _saveData();
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
