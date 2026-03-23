import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/premium_ui_components.dart';
import 'package:flutter/cupertino.dart';
import '../../providers/theme_provider.dart';
import '../../services/local_storage_service.dart';
import '../auth/welcome_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<String> _devices = [];

  String _displayBabyName = 'Baby';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = context.read<AuthRepository>();
    final localStorage = context.read<LocalStorageService>();
    final localBabyName = localStorage.getString('baby_name');

    final result = await auth.getProfile();
    final data = result.data;
    if (mounted) {
      setState(() {
        _profile = data;
        _displayBabyName = data?['baby_name'] ?? localBabyName ?? 'Baby';
        _devices = List<String>.from(data?['device_ids'] ?? []);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await context.read<LocalStorageService>().saveString('guest_mode', 'false');
    await context.read<LocalStorageService>().remove('baby_name');
    await context.read<AuthRepository>().signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final isPremium = _profile?['is_premium'] == true;

    return PremiumScaffold(
      
      appBar: AppBar(
        title: Text('Profile', style: PremiumTypography(context).h2),
        backgroundColor: PremiumColors(context).surface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _handleLogout,
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: PremiumColors(context).gentlePurple))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Premium Hero Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [PremiumColors(context).sereneBlue, PremiumColors(context).gentlePurple],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: PremiumColors(context).gentlePurple.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Image.asset('assets/logo.png', height: 40),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(_displayBabyName, style: PremiumTypography(context).h1.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(user?.isAnonymous == true ? 'Guest Account' : (user?.email?.isNotEmpty == true ? user!.email! : 'Google Account'), style: PremiumTypography(context).body.copyWith(color: Colors.white70)),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final didUpdate = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EditProfileScreen(initialData: _profile ?? {})),
                        );
                        if (didUpdate == true && mounted) {
                          _loadProfile();
                        }
                      },
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Profile'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              _sectionHeader('Membership'),
              PremiumCard(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          PremiumBubbleIcon(icon: Icons.verified_rounded, color: isPremium ? PremiumColors(context).softAmber : PremiumColors(context).textSecondary, size: 24, padding: 12),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isPremium ? "Premium Member" : "Free Plan", style: PremiumTypography(context).h2.copyWith(fontSize: 18)),
                                const SizedBox(height: 4),
                                Text(isPremium ? "Unlimited Devices & Photos" : "Max 2 Devices. No Photos.", style: PremiumTypography(context).body, maxLines: 2, overflow: TextOverflow.ellipsis),
                              ]
                            )
                          ),
                        ]
                      ),
                      if (!isPremium) ...[
                        const SizedBox(height: 16),
                        PremiumActionButton(
                          label: "View Pricing & Upgrade",
                          icon: Icons.star_rounded,
                          color: PremiumColors(context).gentlePurple,
                          onTap: _showPricing,
                        ),
                      ]
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _sectionHeader('Appearance'),
              PremiumCard(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          PremiumBubbleIcon(icon: Icons.palette_rounded, color: PremiumColors(context).gentlePurple, size: 24, padding: 12),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Display Theme", style: PremiumTypography(context).h2.copyWith(fontSize: 18)),
                                const SizedBox(height: 4),
                                Text("Customize the app appearance", style: PremiumTypography(context).body),
                              ]
                            )
                          ),
                        ]
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoSlidingSegmentedControl<ThemeMode>(
                          backgroundColor: PremiumColors(context).surfaceMuted,
                          thumbColor: PremiumColors(context).surface,
                          groupValue: context.watch<ThemeProvider>().themeMode,
                          onValueChanged: (mode) {
                            if (mode != null) context.read<ThemeProvider>().setThemeMode(mode);
                          },
                          children: {
                            ThemeMode.light: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.light_mode_rounded, size: 20, color: PremiumColors(context).textPrimary)),
                            ThemeMode.system: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.brightness_auto_rounded, size: 20, color: PremiumColors(context).textPrimary)),
                            ThemeMode.dark: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Icon(Icons.dark_mode_rounded, size: 20, color: PremiumColors(context).textPrimary)),
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _sectionHeader('Active Devices'),
              Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: DataTile(
                    backgroundColor: PremiumColors(context).surface,
                    child: Row(
                      children: [
                        PremiumBubbleIcon(icon: Icons.smartphone_rounded, color: PremiumColors(context).sereneBlue, size: 20, padding: 12),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Current Phone Session", style: PremiumTypography(context).title),
                              const SizedBox(height: 4),
                              Text("Active Now", style: PremiumTypography(context).caption.copyWith(color: PremiumColors(context).sageGreen)),
                            ]
                          )
                        )
                      ]
                    )
                  ),
                ),

                if (user?.isAnonymous == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: PremiumCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                PremiumBubbleIcon(icon: Icons.person_off_rounded, color: PremiumColors(context).softAmber, size: 20, padding: 12),
                                const SizedBox(width: 12),
                                Text("Guest Account", style: PremiumTypography(context).h2.copyWith(fontSize: 18, color: PremiumColors(context).softAmber)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text("You are using a Guest account. Data will be lost if you delete the app. Link email to save data.", style: PremiumTypography(context).body),
                            const SizedBox(height: 16),
                            PremiumActionButton(
                              label: "Link Email to Save Data",
                              icon: Icons.link_rounded,
                              color: PremiumColors(context).softAmber,
                              onTap: _showLinkEmailDialog,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

              const SizedBox(height: 48),
              if (user?.isAnonymous == false)
                ElevatedButton.icon(
                  onPressed: _handleLogout, 
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50], // Soft red
                    foregroundColor: Colors.red,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                )
              else 
                TextButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.person_off_rounded, color: Colors.red),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    label: const Text("Exit Guest Mode (Data will be lost)", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
               
            ],
        ),
    );
  }

  void _showLinkEmailDialog() {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              backgroundColor: PremiumColors(context).surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text("Link Account", style: PremiumTypography(context).h2),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
                      const SizedBox(height: 8),
                      TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Create Password"), obscureText: true),
                  ],
              ),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                  ElevatedButton(
                      onPressed: () async {
                          if (emailController.text.isEmpty || passwordController.text.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid email or password (min 6 chars)")));
                              return;
                          }
                          try {
                             Navigator.pop(context); // Close dialog first
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Linking account...")));
                             
                             await context.read<AuthRepository>().updateUser(
                                 UserAttributes(email: emailController.text, password: passwordController.text)
                             );
                             
                             if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Linked! Check email to confirm.")));
                                  _loadProfile(); // Refresh UI
                             }
                          } catch (e) {
                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                          }
                      },
                      child: Text("Link"),
                  ),
              ],
          ),
      );
  }

  void _showPricing() {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
              decoration: BoxDecoration(
                color: PremiumColors(context).background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32))
              ),
              padding: const EdgeInsets.all(32.0),
              child: SafeArea(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 6,
                            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(3)),
                            margin: const EdgeInsets.only(bottom: 24),
                          )
                        ),
                        Text("Upgrade to Premium", style: PremiumTypography(context).h1.copyWith(fontSize: 28)),
                        const SizedBox(height: 24),
                        _pricingRow("Ad-Free Experience (No Banners)", true),
                        _pricingRow("Unlock All Premium Features", true),
                        _pricingRow("Multi-Device Login (>2 devices)", true),
                        _pricingRow("Photo Attachments for Meds", true),
                        _pricingRow("Priority Support", true),
                        const Divider(height: 48, color: Colors.black12),
                        Center(child: Text("\$4.99 / Month", style: PremiumTypography(context).h1.copyWith(color: PremiumColors(context).warmPeach, fontSize: 32))),
                        const SizedBox(height: 8),
                        Center(child: Text("Cancel anytime.", style: PremiumTypography(context).caption)),
                        const SizedBox(height: 32),
                        PremiumActionButton(
                            label: "Subscribe Now",
                            icon: Icons.star_rounded,
                            color: PremiumColors(context).warmPeach,
                            onTap: () async {
                                    final user = Supabase.instance.client.auth.currentUser;
                                    
                                    // Auth Wall: Must link account first
                                    if (user?.isAnonymous == true) {
                                        if (context.mounted) Navigator.pop(context); // Close pricing sheet
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text("Please link your email first to subscribe!"))
                                          );
                                        }
                                        _showLinkEmailDialog();
                                        return;
                                    }
            
                                    // Proceed with subscription (Mock)
                                    if (context.mounted) Navigator.pop(context);
                                    if (context.mounted) {
                                      await context.read<AuthRepository>().updateProfile({'is_premium': true});
                                    }
                                    await _loadProfile();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Welcome to Premium!")));
                                    }
                            },
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Purchases Restored! (Mock)")));
                            }, 
                            child: Text("Restore Purchases", style: PremiumTypography(context).body.copyWith(color: PremiumColors(context).textSecondary, decoration: TextDecoration.underline))
                          )
                        )
                    ],
                ),
              ),
          ),
      );
  }

  Widget _pricingRow(String text, bool included) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
              children: [
                  Icon(included ? Icons.check_circle_rounded : Icons.cancel_rounded, color: included ? Colors.green : Colors.red),
                  const SizedBox(width: 12),
                  Expanded(child: Text(text, style: PremiumTypography(context).title)),
              ],
          ),
      );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4),
      child: Text(title, style: PremiumTypography(context).h2.copyWith(fontSize: 18)),
    );
  }
}
