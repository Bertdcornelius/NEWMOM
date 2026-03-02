import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../services/monetization_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/premium_ui_components.dart';
import 'package:flutter/cupertino.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<String> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final service = context.read<SupabaseService>();
    final data = await service.getProfile();
    if (mounted) {
      setState(() {
        _profile = data;
        _devices = List<String>.from(data?['device_ids'] ?? []);
        _isLoading = false;
      });
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
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: PremiumColors(context).gentlePurple))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // App Logo
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: PremiumColors(context).surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 12))
                    ]
                  ),
                  child: Image.asset('assets/logo.png', height: 80)
                )
              ),
              const SizedBox(height: 16),
              Center(child: Text(_profile?['baby_name'] ?? 'Baby', style: PremiumTypography(context).h2)),
              Center(child: Text(user?.email ?? '', style: PremiumTypography(context).body)),
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
              if (_devices.isEmpty)
                Padding(padding: const EdgeInsets.all(16), child: Text("No devices logged.", style: PremiumTypography(context).body))
              else
                ..._devices.map((d) => Padding(
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
                              Text("Device ID: ${d.substring(0, d.length > 8 ? 8 : d.length)}...", style: PremiumTypography(context).title),
                              const SizedBox(height: 4),
                              Text("Active", style: PremiumTypography(context).caption),
                            ]
                          )
                        )
                      ]
                    )
                  ),
                )),

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
                  onPressed: () => context.read<SupabaseService>().signOut(), 
                  icon: Icon(Icons.logout),
                  label: Text('Log Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50)
                  ),
                )
              else 
                TextButton(
                    onPressed: () => context.read<SupabaseService>().signOut(),
                    child: Text("Exit Guest Mode (Data will be lost)", style: TextStyle(color: Colors.red)),
                ),
               
                const SizedBox(height: 24),
                _sectionHeader("Developer Options"),
                SwitchListTile(
                    title: Text("Debug Mode (Simulate Day 31+)"),
                    subtitle: Text("Forces app to behave as if trial expired"),
                    value: context.watch<MonetizationService>().isDebugMode,
                    onChanged: (val) => context.read<MonetizationService>().toggleDebugMode(val),
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
                             
                             await context.read<SupabaseService>().updateUser(
                                 emailController.text,
                                 passwordController.text
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
                                      await context.read<SupabaseService>().updateProfile({'is_premium': true});
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
