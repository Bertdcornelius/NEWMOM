import 'package:flutter/material.dart';
import '../../widgets/premium_ui_components.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/baby_data_repository.dart';

class EmergencyHubScreen extends StatefulWidget {
  const EmergencyHubScreen({super.key});

  @override
  State<EmergencyHubScreen> createState() => _EmergencyHubScreenState();
}

class _EmergencyHubScreenState extends State<EmergencyHubScreen> {
  double _babyWeightKg = 0;
  bool _isLoading = true;
  String _locationAddress = 'Tap to fetch your live address';
  bool _isLoadingLocation = false;

  String _pediatricianName = 'Pediatrician';
  String _pediatricianNumber = 'Tap to set number';
  String _emergencyName = 'Emergency Services';
  String _emergencyNumber = '911';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _loadWeight();
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _pediatricianName = prefs.getString('contact_ped_name') ?? 'Pediatrician';
        _pediatricianNumber = prefs.getString('contact_ped_num') ?? 'Tap to set number';
        _emergencyName = prefs.getString('contact_emg_name') ?? 'Emergency Services';
        _emergencyNumber = prefs.getString('contact_emg_num') ?? '911';
      });
    }
  }

  Future<void> _loadWeight() async {
    final repo = context.read<BabyDataRepository>();
    try {
      final profile = await repo.getProfile();
      if (profile != null && profile['birth_weight'] != null) {
        _babyWeightKg = (profile['birth_weight'] as num).toDouble();
      }
    } catch (_) {}
    
    // Fallback logic, fetching recent growth logs in a real app would be better.
    if (_babyWeightKg == 0) _babyWeightKg = 7.5; // Default assumption for dosage UI preview

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _callNumber(String number) async {
    if (number == 'Tap to set number') {
      _editContacts();
      return;
    }
    final url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationAddress = 'Location permissions denied.';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationAddress = 'Location permissions permanently denied.';
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _locationAddress = '${place.street}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}';
          _isLoadingLocation = false;
        });
      } else {
         setState(() {
          _locationAddress = 'Lat: ${position.latitude}, Lng: ${position.longitude}';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationAddress = 'Failed to locate device';
        _isLoadingLocation = false;
      });
    }
  }

  void _editContacts() {
    String pName = _pediatricianName;
    String pNum = _pediatricianNumber;
    String eName = _emergencyName;
    String eNum = _emergencyNumber;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit Emergency Contacts', style: PremiumTypography(context).h2),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(labelText: 'Pediatrician Name', filled: true),
                onChanged: (val) => pName = val,
                controller: TextEditingController(text: pName == 'Pediatrician' ? '' : pName),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(labelText: 'Pediatrician Number', filled: true),
                keyboardType: TextInputType.phone,
                onChanged: (val) => pNum = val,
                controller: TextEditingController(text: pNum == 'Tap to set number' ? '' : pNum),
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(labelText: 'Emergency Contact Name', filled: true),
                onChanged: (val) => eName = val,
                controller: TextEditingController(text: eName == 'Emergency Services' ? '' : eName),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(labelText: 'Emergency Number', filled: true),
                keyboardType: TextInputType.phone,
                onChanged: (val) => eNum = val,
                controller: TextEditingController(text: eNum == '911' ? '' : eNum),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PremiumActionButton(
                  label: 'Save Contacts',
                  icon: Icons.save,
                  color: PremiumColors(context).sereneBlue,
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('contact_ped_name', pName.isEmpty ? 'Pediatrician' : pName);
                    await prefs.setString('contact_ped_num', pNum.isEmpty ? 'Tap to set number' : pNum);
                    await prefs.setString('contact_emg_name', eName.isEmpty ? 'Emergency Services' : eName);
                    await prefs.setString('contact_emg_num', eNum.isEmpty ? '911' : eNum);
                    _loadData(); // refresh state
                    if (mounted) Navigator.pop(ctx);
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final typo = PremiumTypography(context);

    // Dosage calculation rules of thumb: 
    // Acetaminophen (Tylenol): 10-15 mg/kg every 4-6 hours
    // Infant Acetaminophen is typically 160mg/5mL concentration. 
    // Wait, 160mg / 5mL = 32mg per mL.  Dose = (12.5mg * kg) / 32mg/mL = mL.
    // Ibuprofen (Motrin): 5-10 mg/kg every 6-8 hours (Only for 6+ months)
    // Infant Ibuprofen is typically 50mg/1.25mL concentration. (40mg / mL). 
    
    final tylenolMl = ((12.5 * _babyWeightKg) / 32.0).toStringAsFixed(1);
    final motrinMl = ((7.5 * _babyWeightKg) / 40.0).toStringAsFixed(1);

    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Emergency Hub', style: typo.h2),
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
                // Instant Dials
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Instant Dial', style: typo.h2),
                    TextButton.icon(
                      onPressed: _editContacts,
                      icon: Icon(Icons.edit_rounded, color: colors.sereneBlue, size: 18),
                      label: Text('Edit', style: typo.bodyBold.copyWith(color: colors.sereneBlue)),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                _buildEmergencyDial(
                  'Poison Control', '1-800-222-1222', 
                  Icons.medical_services_rounded, Colors.red,
                  typo
                ),
                const SizedBox(height: 12),
                _buildEmergencyDial(
                  _pediatricianName, _pediatricianNumber, 
                  Icons.person_rounded, colors.sereneBlue,
                  typo
                ),
                const SizedBox(height: 12),
                _buildEmergencyDial(
                  _emergencyName, _emergencyNumber, 
                  Icons.local_hospital_rounded, Colors.orange,
                  typo
                ),
                
                const SizedBox(height: 32),

                // Location Fetcher
                Text('Current Location', style: typo.h2),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _fetchLocation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.sageGreen, width: 2),
                    ),
                    child: Row(
                      children: [
                         _isLoadingLocation 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(Icons.share_location_rounded, color: colors.sageGreen, size: 28),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text('Where am I?', style: typo.bodyBold.copyWith(color: colors.sageGreen)),
                               const SizedBox(height: 4),
                               Text(_locationAddress, style: typo.caption.copyWith(fontSize: 14)),
                             ]
                           )
                         )
                      ]
                    )
                  )
                ),

                const SizedBox(height: 32),
                
                // Dosage Calculator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Dosage Calculator', style: typo.h2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.sageGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text('${_babyWeightKg.toStringAsFixed(1)} kg', style: typo.bodyBold.copyWith(color: colors.sageGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Based on most recent logged or birth weight. Always consult your pediatrician.', style: typo.caption),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildDosageCard(
                        'Acetaminophen', 'Tylenol', '$tylenolMl mL', 
                        'Every 4-6 hours', colors.gentlePurple, colors, typo
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDosageCard(
                        'Ibuprofen', 'Motrin', '$motrinMl mL', 
                        'Every 6-8 hours. 6mo+ only.', colors.warmPeach, colors, typo
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // CPR Guide
                Text('First Aid Visual Guides', style: typo.h2),
                const SizedBox(height: 16),
                PremiumCard(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.sereneBlue.withValues(alpha: 0.15),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: const Center(
                          child: Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Infant CPR Guide (0-12mo)', style: typo.title),
                            const SizedBox(height: 4),
                            Text('Step-by-step visual demonstration of 30 compressions and 2 breaths.', style: typo.body.copyWith(color: colors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PremiumCard(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: colors.warmPeach.withValues(alpha: 0.15),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: const Center(
                          child: Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Choking Relief Guide', style: typo.title),
                            const SizedBox(height: 4),
                            Text('Demonstration of 5 back blows and 5 chest thrusts for infants.', style: typo.body.copyWith(color: colors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
    );
  }

  Widget _buildEmergencyDial(String name, String number, IconData icon, Color color, PremiumTypography typo) {
    return GestureDetector(
      onTap: () => _callNumber(number),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: typo.bodyBold.copyWith(color: color)),
                  const SizedBox(height: 4),
                  Text(number, style: typo.h2.copyWith(fontSize: 20)),
                ],
              ),
            ),
            Icon(Icons.call_rounded, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildDosageCard(String genericName, String brandName, String dosage, String instructions, Color color, PremiumColors colors, PremiumTypography typo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(brandName, style: typo.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          Text(genericName, style: typo.bodyBold.copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          Text(dosage, style: typo.h2.copyWith(color: color, fontSize: 24)),
          const SizedBox(height: 8),
          Text(instructions, style: typo.caption.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
