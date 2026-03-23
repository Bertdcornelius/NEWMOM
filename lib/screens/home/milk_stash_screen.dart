import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../repositories/care_repository.dart';
import '../../repositories/auth_repository.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/premium_ui_components.dart';

class MilkStashScreen extends StatefulWidget {
  const MilkStashScreen({super.key});

  @override
  State<MilkStashScreen> createState() => _MilkStashScreenState();
}

class _MilkStashScreenState extends State<MilkStashScreen> {
  List<Map<String, dynamic>> _stashEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final res = await context.read<CareRepository>().getMilkStash();
    if (res.isSuccess && res.data != null) {
      _stashEntries = res.data!;
    } else {
      _stashEntries = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  double _getTotalAmount(String location) {
    double total = 0;
    for (var entry in _stashEntries) {
      String loc = entry['type']?.toString().toLowerCase() ?? 'freezer';
      
      if (loc == location) {
        total += (entry['amount_ml'] as num?)?.toDouble() ?? 0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    // Convert ml to oz (1 oz = ~29.57 ml)
    final freezerMl = _getTotalAmount('freezer');
    final fridgeMl = _getTotalAmount('fridge');
    final freezerOz = freezerMl / 29.57;
    final fridgeOz = fridgeMl / 29.57;
    final totalOz = freezerOz + fridgeOz;
    
    // Assume baby eats 25oz per day
    final daysOfFood = (totalOz / 25.0).toStringAsFixed(1);

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Milk Stash', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStashDialog,
        backgroundColor: colors.sereneBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Dash
                PremiumCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.sereneBlue.withValues(alpha: 0.15),
                        ),
                        child: Center(child: Text('❄️', style: TextStyle(fontSize: 32))),
                      ),
                      const SizedBox(height: 16),
                      Text('Estimated Supply', style: typo.caption),
                      Text('$daysOfFood Days', style: typo.h1.copyWith(color: colors.sereneBlue, fontSize: 42)),
                      const SizedBox(height: 8),
                      Text('${totalOz.toStringAsFixed(1)} total oz saved', style: typo.body),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLocationStat('Freezer', '${freezerOz.toStringAsFixed(1)} oz', colors.warmPeach, colors, typo),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildLocationStat('Fridge', '${fridgeOz.toStringAsFixed(1)} oz', colors.sageGreen, colors, typo),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Recent Additions', style: typo.h2),
                const SizedBox(height: 12),

                ..._stashEntries.take(10).map((entry) {
                  final amountMl = (entry['amount_ml'] as num?)?.toDouble() ?? 0;
                  final amountOz = amountMl / 29.57;
                  String loc = 'Freezer';
                  if (entry['type']?.toString().toLowerCase() == 'fridge') loc = 'Fridge';
                  
                  final date = DateTime.parse(entry['created_at']).toLocal();
                  final dateStr = DateFormat('MMM d, h:mm a').format(date);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DataTile(
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: loc == 'Freezer' ? colors.warmPeach.withValues(alpha: 0.1) : colors.sageGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(loc == 'Freezer' ? '❄️' : '🧊', style: const TextStyle(fontSize: 20))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${amountOz.toStringAsFixed(1)} oz', style: typo.bodyBold),
                                Text(dateStr, style: typo.caption),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.surfaceMuted,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(loc, style: typo.caption.copyWith(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                if (_stashEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text('No milk stashed yet. Tap + to add.', style: typo.body),
                    ),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
    );
  }

  Widget _buildLocationStat(String title, String value, Color color, PremiumColors colors, PremiumTypography typo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(title, style: typo.caption),
          const SizedBox(height: 4),
          Text(value, style: typo.bodyBold.copyWith(color: color, fontSize: 18)),
        ],
      ),
    );
  }

  void _showAddStashDialog() {
    final amountC = TextEditingController();
    String location = 'freezer';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PremiumColors(context).surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSS) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: PremiumColors(context).textMuted, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Stash Milk', style: PremiumTypography(context).h2),
              const SizedBox(height: 20),
              
              TextField(
                controller: amountC,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (oz)',
                  prefixIcon: Icon(Icons.water_drop_rounded, color: PremiumColors(context).sereneBlue),
                  filled: true,
                  fillColor: PremiumColors(context).surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              
              Text('Location', style: PremiumTypography(context).title),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setSS(() => location = 'freezer'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: location == 'freezer' ? PremiumColors(context).warmPeach.withValues(alpha: 0.15) : PremiumColors(context).surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: location == 'freezer' ? PremiumColors(context).warmPeach : Colors.transparent, width: 2),
                        ),
                        child: Center(child: Text('❄️ Freezer', style: PremiumTypography(context).bodyBold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setSS(() => location = 'fridge'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: location == 'fridge' ? PremiumColors(context).sageGreen.withValues(alpha: 0.15) : PremiumColors(context).surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: location == 'fridge' ? PremiumColors(context).sageGreen : Colors.transparent, width: 2),
                        ),
                        child: Center(child: Text('🧊 Fridge', style: PremiumTypography(context).bodyBold)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: PremiumActionButton(
                  label: 'Save to Stash',
                  icon: Icons.check_circle_outline_rounded,
                  color: PremiumColors(context).sereneBlue,
                  onTap: () async {
                    if (amountC.text.isEmpty) return;
                    final oz = double.tryParse(amountC.text) ?? 0;
                    if (oz <= 0) return;
                    
                    final ml = oz * 29.57;
                    final user = context.read<AuthRepository>().currentUser;
                    if (user == null) return;
                    
                    final newItem = {
                      'id': const Uuid().v4(),
                      'user_id': user.id,
                      'amount_ml': ml,
                      'type': location,
                      'notes': '',
                      'expiration_date': location == 'freezer' ? DateTime.now().add(const Duration(days: 180)).toIso8601String() : DateTime.now().add(const Duration(days: 4)).toIso8601String(),
                      'created_at': DateTime.now().toUtc().toIso8601String(),
                    };
                    
                    setState(() {
                         _stashEntries.insert(0, newItem);
                    });
                    
                    context.read<CareRepository>().saveMilkStash(newItem).then((result) {
                      if (!result.isSuccess && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message ?? 'Failed to save'), backgroundColor: Colors.red));
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Milk stashed! ❄️')));
                      }
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
