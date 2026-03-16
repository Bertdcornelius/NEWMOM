import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/family_repository.dart';
import '../../widgets/premium_ui_components.dart';

class FamilySharingScreen extends StatefulWidget {
  const FamilySharingScreen({super.key});

  @override
  State<FamilySharingScreen> createState() => _FamilySharingScreenState();
}

class _FamilySharingScreenState extends State<FamilySharingScreen> {
  Map<String, dynamic>? _circle;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _hasCircle = false;

  static const roles = ['Parent', 'Grandparent', 'Caregiver', 'Sibling', 'Aunt/Uncle'];
  static const roleEmojis = {'Parent': '👨‍👩‍👧', 'Grandparent': '👴', 'Caregiver': '🧑‍🍼', 'Sibling': '👦', 'Aunt/Uncle': '🤗'};
  static const roleColors = [Colors.blue, Colors.purple, Colors.teal, Colors.orange, Colors.pink];

  @override
  void initState() {
    super.initState();
    _loadCircle();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCircle() async {
    setState(() => _isLoading = true);
    try {
      final service = context.read<FamilyRepository>();
      final circle = await service.getMyFamilyCircle();
      if (circle != null) {
        final members = await service.getFamilyMembers(circle['id'].toString());
        if (mounted) {
          setState(() {
            _circle = circle;
            _members = members;
            _hasCircle = true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() { _hasCircle = false; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading family circle: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Family Circle', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.gentlePurple))
          : _hasCircle ? _buildCircleView(colors, typo) : _buildNoCircleView(colors, typo),
    );
  }

  // --- No Circle View (Create or Join) ---
  Widget _buildNoCircleView(PremiumColors colors, PremiumTypography typo) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.people_rounded, size: 80, color: colors.gentlePurple.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text('No Family Circle Yet', style: typo.h1),
          const SizedBox(height: 8),
          Text('Create one or join an existing circle', style: typo.body, textAlign: TextAlign.center),
          const SizedBox(height: 40),

          // Create Circle Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _showCreateCircle,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: Text('Create a Family Circle', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.gentlePurple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Join Circle Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _showJoinCircle,
              icon: Icon(Icons.group_add_rounded, color: colors.sereneBlue),
              label: Text('Join with Invite Code', style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, color: colors.sereneBlue,
              )),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.sereneBlue.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // How it works
          PremiumCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    PremiumBubbleIcon(icon: Icons.info_outline_rounded, color: colors.sereneBlue, size: 18, padding: 8),
                    const SizedBox(width: 10),
                    Text('How it Works', style: typo.title),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '1. Create a Family Circle to get an invite code\n'
                  '2. Share the code with family members\n'
                  '3. They install the app, sign up, and enter the code\n'
                  '4. Everyone in the circle sees each other\'s role',
                  style: typo.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Circle View (Has a circle) ---
  Widget _buildCircleView(PremiumColors colors, PremiumTypography typo) {
    final inviteCode = _circle?['invite_code'] ?? '';
    final circleName = _circle?['name'] ?? 'Family Circle';

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invite Code Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colors.gentlePurple, colors.sereneBlue],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: colors.gentlePurple.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(circleName.toUpperCase(), style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 2,
                      )),
                      const SizedBox(height: 8),
                      Text(inviteCode, style: GoogleFonts.plusJakartaSans(
                        fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4,
                      )),
                      const SizedBox(height: 12),
                      Text('Share this code with family members', style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, color: Colors.white70,
                      )),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Share.share(
                            'Join my baby\'s Family Circle on Neo! 👶\n\nUse invite code: $inviteCode\n\n1. Install the Neo Baby Tracker app\n2. Create an account\n3. Go to Family Circle → Join with Invite Code\n4. Enter code: $inviteCode',
                            subject: 'Join my Family Circle',
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share Code'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Members
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Members', style: typo.h2),
                    Text('${_members.length} people', style: typo.caption),
                  ],
                ),
                const SizedBox(height: 12),

                if (_members.isEmpty)
                  PremiumCard(child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Column(
                      children: [
                        Icon(Icons.people_outline_rounded, size: 48, color: colors.textMuted),
                        const SizedBox(height: 12),
                        Text('No members yet', style: typo.body),
                        const SizedBox(height: 4),
                        Text('Share the code to invite family', style: typo.caption),
                      ],
                    )),
                  ))
                else
                  ...List.generate(_members.length, (i) {
                    final m = _members[i];
                    final role = m['role'] ?? 'Parent';
                    final emoji = roleEmojis[role] ?? '👤';
                    final color = roleColors[roles.indexOf(role).clamp(0, roleColors.length - 1)];
                    final isOwner = _circle?['owner_id'] == context.read<FamilyRepository>().currentUser?.id;
                    final isSelf = m['user_id'] == context.read<FamilyRepository>().currentUser?.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DataTile(
                        onTap: isOwner && !isSelf ? () => _showRemoveDialog(m) : null,
                        child: Row(
                          children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(m['display_name'] ?? '', style: typo.bodyBold),
                                    if (isSelf) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: colors.sageGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text('You', style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10, fontWeight: FontWeight.w700, color: colors.sageGreen,
                                        )),
                                      ),
                                    ],
                                  ],
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(role, style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11, fontWeight: FontWeight.w700, color: color,
                                  )),
                                ),
                              ],
                            )),
                            if (isOwner && !isSelf)
                              Icon(Icons.close_rounded, color: colors.textMuted, size: 18),
                          ],
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
    );
  }

  // --- Create Circle Dialog ---
  void _showCreateCircle() {
    final nameC = TextEditingController(text: 'My Family');
    final colors = PremiumColors(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.textMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Create Family Circle', style: PremiumTypography(context).h2),
            const SizedBox(height: 16),
            TextField(
              controller: nameC,
              decoration: InputDecoration(
                labelText: 'Circle Name',
                prefixIcon: Icon(Icons.family_restroom_rounded, color: colors.gentlePurple),
                filled: true,
                fillColor: colors.surfaceMuted,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: PremiumActionButton(
                label: 'Create Circle',
                icon: Icons.add_circle_outline_rounded,
                color: colors.gentlePurple,
                onTap: () async {
                  if (nameC.text.isEmpty) return;
                  Navigator.pop(ctx);
                  try {
                    final code = await context.read<FamilyRepository>().createFamilyCircle(nameC.text);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Circle created! Invite code: $code')),
                      );
                    }
                    _loadCircle();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Join Circle Dialog ---
  void _showJoinCircle() {
    final codeC = TextEditingController();
    final nameC = TextEditingController();
    String selectedRole = 'Parent';
    final colors = PremiumColors(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setBS) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.textMuted, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Join a Family Circle', style: PremiumTypography(context).h2),
              const SizedBox(height: 16),
              TextField(
                controller: codeC,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Invite Code',
                  hintText: 'e.g. ABC123',
                  prefixIcon: Icon(Icons.vpn_key_rounded, color: colors.sereneBlue),
                  filled: true,
                  fillColor: colors.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameC,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  prefixIcon: Icon(Icons.person_rounded, color: colors.gentlePurple),
                  filled: true,
                  fillColor: colors.surfaceMuted,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Text('Your Role', style: PremiumTypography(context).title),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: roles.map((role) {
                  return ChoiceChip(
                    label: Text('${roleEmojis[role]} $role'),
                    selected: selectedRole == role,
                    onSelected: (v) => setBS(() => selectedRole = role),
                    selectedColor: colors.gentlePurple.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PremiumActionButton(
                  label: 'Join Circle',
                  icon: Icons.group_add_rounded,
                  color: colors.sereneBlue,
                  onTap: () async {
                    if (codeC.text.isEmpty || nameC.text.isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      final result = await context.read<FamilyRepository>().joinFamilyCircle(
                        codeC.text, nameC.text, selectedRole,
                      );
                      if (mounted) {
                        if (result) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Successfully joined the family circle! 🎉')),
                          );
                          _loadCircle();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid invite code. Please check and try again.')),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Remove Member Dialog ---
  void _showRemoveDialog(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${member['display_name']}?'),
        content: const Text('This person will be removed from the family circle.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<FamilyRepository>().removeFamilyMember(member['id'].toString());
                _loadCircle();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
