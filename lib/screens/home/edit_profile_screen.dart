import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/auth_repository.dart';
import '../../widgets/premium_ui_components.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProfileScreen({super.key, required this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _babyNameController;
  late TextEditingController _fatherNameController;
  late TextEditingController _motherNameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _birthPlaceController;
  
  DateTime? _selectedDob;

  @override
  void initState() {
    super.initState();
    _babyNameController = TextEditingController(text: widget.initialData['baby_name'] ?? '');
    _fatherNameController = TextEditingController(text: widget.initialData['father_name'] ?? '');
    _motherNameController = TextEditingController(text: widget.initialData['mother_name'] ?? '');
    _heightController = TextEditingController(text: widget.initialData['baby_height']?.toString() ?? '');
    _weightController = TextEditingController(text: widget.initialData['baby_weight']?.toString() ?? '');
    _birthPlaceController = TextEditingController(text: widget.initialData['birth_place'] ?? '');
    
    if (widget.initialData['date_of_birth'] != null) {
      try {
        _selectedDob = DateTime.parse(widget.initialData['date_of_birth']);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _babyNameController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _birthPlaceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: PremiumColors(context).gentlePurple,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> updates = {
        'baby_name': _babyNameController.text.trim(),
        'father_name': _fatherNameController.text.trim(),
        'mother_name': _motherNameController.text.trim(),
        'birth_place': _birthPlaceController.text.trim(),
      };

      if (_heightController.text.isNotEmpty) {
        updates['baby_height'] = double.tryParse(_heightController.text.trim());
      }
      if (_weightController.text.isNotEmpty) {
        updates['baby_weight'] = double.tryParse(_weightController.text.trim());
      }
      if (_selectedDob != null) {
        updates['date_of_birth'] = DateFormat('yyyy-MM-dd').format(_selectedDob!);
      }

      await context.read<AuthRepository>().updateProfile(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'))
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: PremiumTypography(context).body.copyWith(color: PremiumColors(context).textSecondary),
      filled: true,
      fillColor: PremiumColors(context).surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(16),
         borderSide: BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(16),
         borderSide: BorderSide(color: PremiumColors(context).gentlePurple, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: PremiumTypography(context).h2),
        backgroundColor: PremiumColors(context).surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: PremiumColors(context).textPrimary),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text("Essential Details", style: PremiumTypography(context).h1.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text("Complete your family profile.", style: PremiumTypography(context).body),
              
              const SizedBox(height: 32),
              
              // Family Section
              Text("Family", style: PremiumTypography(context).h2.copyWith(fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _babyNameController,
                decoration: _inputDecoration("Baby's Full Name"),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _motherNameController,
                decoration: _inputDecoration("Mother's Name"),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fatherNameController,
                decoration: _inputDecoration("Father's Name"),
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 32),
              
              // Stats Section
              Text("Baby Stats", style: PremiumTypography(context).h2.copyWith(fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                   Expanded(
                     child: TextFormField(
                       controller: _weightController,
                       keyboardType: const TextInputType.numberWithOptions(decimal: true),
                       decoration: _inputDecoration("Weight (kg)"),
                     ),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: TextFormField(
                       controller: _heightController,
                       keyboardType: const TextInputType.numberWithOptions(decimal: true),
                       decoration: _inputDecoration("Height (cm)"),
                     ),
                   )
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Birth Info Section
              Text("Birth Record", style: PremiumTypography(context).h2.copyWith(fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _birthPlaceController,
                decoration: _inputDecoration("Place of Birth (Hospital/City)"),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              
              // Date Selection
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: PremiumColors(context).surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cake_rounded, color: PremiumColors(context).gentlePurple),
                      const SizedBox(width: 16),
                      Text(
                        _selectedDob == null 
                          ? "Select Date of Birth" 
                          : DateFormat('MMMM d, yyyy').format(_selectedDob!),
                        style: PremiumTypography(context).body.copyWith(
                          color: _selectedDob == null ? PremiumColors(context).textSecondary : PremiumColors(context).textPrimary,
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Save Button
              _isSaving 
                ? const Center(child: CircularProgressIndicator())
                : PremiumActionButton(
                    label: "Save Profile",
                    icon: Icons.check_circle_rounded,
                    color: PremiumColors(context).gentlePurple,
                    onTap: _saveProfile,
                  ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
