import 'package:flutter/material.dart';
import '../../widgets/premium_ui_components.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../../repositories/auth_repository.dart';

class FamilySharingScreen extends StatefulWidget {
  const FamilySharingScreen({super.key});

  @override
  State<FamilySharingScreen> createState() => _FamilySharingScreenState();
}

class _FamilySharingScreenState extends State<FamilySharingScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _connectedMembers = [];
  String? _generatedCode;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final auth = context.read<AuthRepository>();
    final profileRes = await auth.getProfile();
    
    String motherName = 'Mother (You)';
    String fatherName = 'Father';
    
    if (profileRes.isSuccess && profileRes.data != null) {
        final d = profileRes.data!;
        if (d['mother_name'] != null && d['mother_name'].toString().isNotEmpty) {
            motherName = d['mother_name'] + ' (You)';
        }
        if (d['father_name'] != null && d['father_name'].toString().isNotEmpty) {
            fatherName = d['father_name'];
        }
    }

    if (mounted) {
      setState(() {
        _connectedMembers = [
          {'name': motherName, 'role': 'Mother', 'added_date': DateTime.now().toIso8601String(), 'avatar': motherName[0].toUpperCase()},
          {'name': fatherName, 'role': 'Father', 'added_date': DateTime.now().toIso8601String(), 'avatar': fatherName[0].toUpperCase()},
        ];
        _isLoading = false;
      });
    }
  }

  void _generateCode() {
    setState(() {
      final random = Random();
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      _generatedCode = String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    });
  }

  void _copyCode() {
    if (_generatedCode != null) {
      Clipboard.setData(ClipboardData(text: _generatedCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invite code copied to clipboard!'),
          backgroundColor: PremiumColors(context).sageGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeMember(int index) {
    if (index == 0) return; // Can't remove self in this demo
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('Are you sure you want to remove ${_connectedMembers[index]['name']} from the family group? They will lose access to the baby\'s data.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _connectedMembers.removeAt(index));
              Navigator.pop(ctx);
            }, 
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Family Sync', style: typo.h2),
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
                // Invite Section
                PremiumCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.warmPeach.withValues(alpha: 0.15),
                        ),
                        child: Center(child: Icon(Icons.family_restroom_rounded, color: colors.warmPeach, size: 32)),
                      ),
                      const SizedBox(height: 16),
                      Text('Invite a Co-Parent or Caregiver', textAlign: TextAlign.center, style: typo.title),
                      const SizedBox(height: 8),
                      Text('Share your baby\'s database so you can both log feeds, sleep, and diapers perfectly in sync.', 
                        textAlign: TextAlign.center, style: typo.body.copyWith(color: colors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      
                      if (_generatedCode == null)
                        SizedBox(
                          width: double.infinity,
                          child: PremiumActionButton(
                            label: 'Generate Invite Code',
                            icon: Icons.vpn_key_rounded,
                            color: colors.warmPeach,
                            onTap: _generateCode,
                          ),
                        )
                      else
                        Column(
                          children: [
                            Text('Your Secure Invite Code', style: typo.caption),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _copyCode,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: colors.warmPeach, width: 2),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(_generatedCode!, style: typo.h1.copyWith(color: colors.warmPeach, letterSpacing: 8)),
                                    const SizedBox(width: 12),
                                    Icon(Icons.copy_rounded, color: colors.warmPeach, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('Code expires in 24 hours.', style: typo.caption.copyWith(color: colors.warmPeach)),
                          ],
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Connected Members
                Text('Connected Members', style: typo.h2),
                const SizedBox(height: 16),
                
                ..._connectedMembers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final member = entry.value;
                  final isMe = index == 0;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DataTile(
                      child: Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isMe ? colors.sereneBlue : colors.gentlePurple,
                            ),
                            child: Center(child: Text(member['avatar'], style: typo.h2.copyWith(color: Colors.white))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member['name'], style: typo.bodyBold.copyWith(fontSize: 16)),
                                Text(member['role'], style: typo.caption),
                              ],
                            ),
                          ),
                          if (!isMe)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red),
                              onPressed: () => _removeMember(index),
                            ),
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
}
