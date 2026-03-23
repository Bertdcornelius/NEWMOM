import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/local_storage_service.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/premium_ui_components.dart';

class EmergencyCardScreen extends StatefulWidget {
  const EmergencyCardScreen({super.key});

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  Map<String, String> _info = {
    'baby_name': '',
    'dob': '',
    'blood_type': '',
    'allergies': '',
    'pediatrician': '',
    'pediatrician_phone': '',
    'hospital': '',
    'emergency_contact': '',
    'emergency_phone': '',
    'insurance': '',
    'notes': '',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _loadData() async {
    final ls = context.read<LocalStorageService>();
    final auth = context.read<AuthRepository>();
    
    // 1. Try to load from Supabase MetaData First
    final meta = auth.currentUser?.userMetadata?['emergency_card'];
    if (meta != null && meta is String) {
        _info = Map<String, String>.from(jsonDecode(meta));
        // Cache locally
        ls.saveString('emergency_card', meta);
    } else {
        // 2. Fallback to Local Storage
        final raw = ls.getString('emergency_card');
        if (raw != null) _info = Map<String, String>.from(jsonDecode(raw));
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveData() async {
    final payload = jsonEncode(_info);
    // Save locally for instant offline access
    await context.read<LocalStorageService>().saveString('emergency_card', payload);
    
    // Sync to Supabase instantly
    try {
        final auth = context.read<AuthRepository>();
        if (auth.currentUser != null) {
            await auth.updateUser(UserAttributes(data: {'emergency_card': payload}));
        }
    } catch (_) {}
  }


  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Emergency Card', style: typo.h2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, color: colors.sageGreen),
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Main Emergency Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.warmPeach, colors.warmPeach.withValues(alpha: 0.8)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: colors.warmPeach.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EMERGENCY INFO', style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.7),
                                  letterSpacing: 1.5,
                                )),
                                Text(_info['baby_name']?.isNotEmpty == true ? _info['baby_name']! : 'Set Baby Name',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _cardRow('🎂', 'Date of Birth', _info['dob']),
                        _cardRow('🩸', 'Blood Type', _info['blood_type']),
                        _cardRow('⚠️', 'Allergies', _info['allergies']),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Contacts Section
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Medical Contacts', style: typo.title),
                        const SizedBox(height: 16),
                        _infoTile('👨‍⚕️ Pediatrician', _info['pediatrician'], _info['pediatrician_phone'], colors),
                        const Divider(height: 20),
                        _infoTile('🏥 Hospital', _info['hospital'], null, colors),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Emergency Contact', style: typo.title),
                        const SizedBox(height: 16),
                        _infoTile('📞 Contact', _info['emergency_contact'], _info['emergency_phone'], colors),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Insurance & Notes
                  PremiumCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Additional Info', style: typo.title),
                        const SizedBox(height: 12),
                        if (_info['insurance']?.isNotEmpty == true)
                          _detailRow('Insurance', _info['insurance']!, colors),
                        if (_info['notes']?.isNotEmpty == true)
                          _detailRow('Notes', _info['notes']!, colors),
                        if (_info['insurance']?.isEmpty != false && _info['notes']?.isEmpty != false)
                          Text('Tap edit to add insurance and notes', style: typo.caption),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Share Button
                  SizedBox(
                    width: double.infinity,
                    child: PremiumActionButton(
                      label: 'Share Emergency Card',
                      icon: Icons.share_rounded,
                      color: colors.warmPeach,
                      onTap: _shareCard,
                    ),
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

  Widget _cardRow(String emoji, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text('$label: ', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.7))),
          Expanded(
            child: Text(value?.isNotEmpty == true ? value! : '—',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String emoji, String? name, String? phone, PremiumColors colors) {
    return Row(
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: PremiumTypography(context).bodyBold),
            if (name?.isNotEmpty == true)
              Text(name!, style: PremiumTypography(context).body),
            if (phone?.isNotEmpty == true)
              Text(phone!, style: PremiumTypography(context).body.copyWith(color: colors.sageGreen)),
          ],
        )),
      ],
    );
  }

  Widget _detailRow(String label, String value, PremiumColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: PremiumTypography(context).bodyBold),
          Expanded(child: Text(value, style: PremiumTypography(context).body)),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final controllers = <String, TextEditingController>{};
    for (final key in _info.keys) {
      controllers[key] = TextEditingController(text: _info[key]);
    }

    final labels = {
      'baby_name': 'Baby Name', 'dob': 'Date of Birth', 'blood_type': 'Blood Type',
      'allergies': 'Allergies', 'pediatrician': 'Pediatrician Name', 'pediatrician_phone': 'Pediatrician Phone',
      'hospital': 'Hospital', 'emergency_contact': 'Emergency Contact', 'emergency_phone': 'Emergency Phone',
      'insurance': 'Insurance Info', 'notes': 'Additional Notes',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PremiumColors(context).surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: PremiumColors(context).textMuted, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Edit Emergency Card', style: PremiumTypography(context).h2),
              const SizedBox(height: 16),
              ...labels.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: controllers[e.key],
                  decoration: InputDecoration(
                    labelText: e.value,
                    filled: true,
                    fillColor: PremiumColors(context).surfaceMuted,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: PremiumActionButton(
                  label: 'Save',
                  icon: Icons.check_circle_outline_rounded,
                  color: PremiumColors(context).sageGreen,
                  onTap: () {
                    for (final key in _info.keys) {
                      _info[key] = controllers[key]?.text ?? '';
                    }
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

  void _shareCard() {
    final text = StringBuffer('🚨 EMERGENCY INFO\n');
    text.writeln('Baby: ${_info['baby_name']}');
    text.writeln('DOB: ${_info['dob']}');
    text.writeln('Blood Type: ${_info['blood_type']}');
    text.writeln('Allergies: ${_info['allergies']}');
    text.writeln('Pediatrician: ${_info['pediatrician']} (${_info['pediatrician_phone']})');
    text.writeln('Hospital: ${_info['hospital']}');
    text.writeln('Emergency: ${_info['emergency_contact']} (${_info['emergency_phone']})');
    if (_info['insurance']?.isNotEmpty == true) text.writeln('Insurance: ${_info['insurance']}');
    if (_info['notes']?.isNotEmpty == true) text.writeln('Notes: ${_info['notes']}');
    text.writeln('\n— Sent from Neo Baby Tracker');
    Share.share(text.toString(), subject: 'Emergency Info - ${_info['baby_name']}');
  }
}
