import 'package:flutter/material.dart';
import '../../widgets/premium_ui_components.dart';
import 'package:provider/provider.dart';
import '../../repositories/auth_repository.dart';
import '../../services/local_storage_service.dart';
import 'login_screen.dart';
import 'baby_setup_screen.dart';
import '../home/dashboard_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    
    final result = await context.read<AuthRepository>().signInAnonymously();
    if (result.isSuccess) {
      await context.read<LocalStorageService>().saveString('guest_mode', 'true');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const BabySetupScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guest Mode Failed: ${result.message}\nMake sure "Enable Anonymous Sign-ins" is ON in Supabase Auth Settings.'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _continueAsGuestConfirm() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Continue as Guest'),
        content: const Text('Your data will not be saved permanently. Creating an account is recommended to keep your baby\'s data safe across devices. Continue anyway?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B9080), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _continueAsGuest();
            },
            child: const Text('Yes, Continue'),
          ),
        ],
      )
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final result = await context.read<AuthRepository>().signInWithGoogle();
    
    if (result.isSuccess) {
      if (mounted) {
         await _navigateAfterAuth();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In Error: ${result.message}')));
      }
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _navigateAfterAuth() async {
      try {
        final authRepo = context.read<AuthRepository>();
        final metaName = authRepo.currentUser?.userMetadata?['baby_name'];
        final profile = await authRepo.getProfile();
        
        final babyName = (metaName != null && metaName.toString().trim().isNotEmpty)
             ? metaName 
             : (profile.isSuccess && profile.data != null ? profile.data!['baby_name'] : null);
        if (babyName != null && babyName.toString().trim().isNotEmpty) {
           await context.read<LocalStorageService>().saveString('baby_name', babyName.toString());
           if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
           }
        } else {
           if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BabySetupScreen()),
              );
           }
        }
      } catch (e) {
           if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const BabySetupScreen()),
              );
           }
      }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
               Color(0xFFF9FBFB), // Off-white
               Color(0xFFE0F2F1), // Very light teal/mint
               Color(0xFFD3EADD), // Soft Sage
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Premium Logo Container
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B9080).withValues(alpha: 0.25),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 10,
                        offset: const Offset(-5, -5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // App Title
                Text(
                  'Neo',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F4858), // Dark Blue-Grey
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The Modern Baby & Mom Tracker',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF2F4858).withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const Spacer(flex: 2),
                
                if (_isLoading)
                  const CircularProgressIndicator(color: Color(0xFF6B9080))
                else ...[
                  // Primary Button - Sign Up
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen(initialIsLogin: false)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 8,
                        shadowColor: const Color(0xFF6B9080).withValues(alpha: 0.3),
                        backgroundColor: const Color(0xFF6B9080), // Sage
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Get Started', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Google Sign In
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      label: const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2F4858),
                        side: const BorderSide(color: Color(0xFF6B9080)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Button
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen(initialIsLogin: true)),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF557C70),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('No, I already have an account'),
                  ),

                  // Guest Button
                  TextButton(
                    onPressed: _continueAsGuestConfirm,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Continue as guest'),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
