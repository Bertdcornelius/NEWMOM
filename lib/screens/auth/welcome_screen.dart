import 'package:flutter/material.dart';
import '../../widgets/premium_ui_components.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import 'login_screen.dart';
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
    try {
      await context.read<SupabaseService>().signInAnonymously();
      await context.read<LocalStorageService>().saveString('guest_mode', 'true');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Guest Mode Failed: ${e.toString()}\nMake sure "Enable Anonymous Sign-ins" is ON in Supabase Auth Settings.'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B9080).withOpacity(0.25),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 10,
                        offset: const Offset(-5, -5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0), // Padding to ensure logo isn't cut if it's square
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain, // Ensure full logo is visible inside the padding
                      ),
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
                    color: const Color(0xFF2F4858).withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const Spacer(flex: 2),
                
                if (_isLoading)
                  const CircularProgressIndicator(color: Color(0xFF6B9080))
                else ...[
                  // Primary Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _continueAsGuest,
                      style: ElevatedButton.styleFrom(
                        elevation: 8,
                        shadowColor: const Color(0xFF6B9080).withOpacity(0.3),
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
                  const SizedBox(height: 20),
                  
                  // Secondary Button
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF557C70),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    child: Text('I already have an account'),
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
