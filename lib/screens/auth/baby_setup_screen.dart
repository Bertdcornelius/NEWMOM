import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../repositories/auth_repository.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/premium_ui_components.dart';
import '../home/dashboard_screen.dart';

class BabySetupScreen extends StatefulWidget {
  const BabySetupScreen({super.key});

  @override
  State<BabySetupScreen> createState() => _BabySetupScreenState();
}

class _BabySetupScreenState extends State<BabySetupScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your baby')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Save locally
      await context.read<LocalStorageService>().saveString('baby_name', name);
      
      // Update remote profile
      final authRepo = context.read<AuthRepository>();
      await authRepo.updateProfile({'baby_name': name});
      
      try {
        await authRepo.updateUser(UserAttributes(data: {'baby_name': name}));
      } catch (_) {}
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving baby name: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              PremiumBubbleIcon(
                icon: Icons.child_care_rounded,
                color: PremiumColors(context).warmPeach,
                size: 64,
                padding: 24,
              ),
              const SizedBox(height: 32),
              Text(
                "Welcome to Neo!",
                textAlign: TextAlign.center,
                style: PremiumTypography(context).h1.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 12),
              Text(
                "To get started, what is your baby's name?",
                textAlign: TextAlign.center,
                style: PremiumTypography(context).body.copyWith(
                  color: PremiumColors(context).textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _nameController,
                style: TextStyle(color: PremiumColors(context).textPrimary, fontSize: 18),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "E.g. Emma",
                  hintStyle: TextStyle(color: PremiumColors(context).textMuted),
                  filled: true,
                  fillColor: PremiumColors(context).surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                PremiumActionButton(
                  label: "Continue",
                  icon: Icons.arrow_forward_rounded,
                  color: PremiumColors(context).sereneBlue,
                  onTap: _submit,
                ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
