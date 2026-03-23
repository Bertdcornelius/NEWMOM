import 'package:flutter/material.dart';
import '../../widgets/premium_ui_components.dart';
import 'package:provider/provider.dart';
import '../../repositories/auth_repository.dart';
import '../../services/local_storage_service.dart';
import 'package:uuid/uuid.dart';
import 'baby_setup_screen.dart';
import '../home/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool initialIsLogin;
  const LoginScreen({super.key, this.initialIsLogin = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late bool _isLogin;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final authService = context.read<AuthRepository>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isLogin) {
      final result = await authService.signIn(email, password);
      if (result.isSuccess) {
        if (mounted) {
          await _navigateAfterAuth();
        }
      } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result.message}')));
      }
    } else {
      final result = await authService.signUp(email, password, 'User');
      if (result.isSuccess) {
        if (mounted) {
          if (authService.currentUser != null) {
            await _navigateAfterAuth();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Account created! Please check your email to verify your account."),
                action: SnackBarAction(
                  label: "Resend Email",
                  onPressed: () async {
                      final resendRes = await authService.resendConfirmationEmail(email);
                      if (resendRes.isSuccess) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Confirmation email resent!")));
                      } else {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error resending: ${resendRes.message}")));
                      }
                  },
                ),
                duration: const Duration(seconds: 10),
              ),
            );
          }
        }
      } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result.message}')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
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
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
                (route) => false,
              );
           }
        } else {
           if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const BabySetupScreen()),
                (route) => false,
              );
           }
        }
      } catch (e) {
           // Fallback to baby setup if profile fetch fails
           if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const BabySetupScreen()),
                (route) => false,
              );
           }
      }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(_isLogin ? 'Login' : 'Sign Up'),
                  ),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? 'Create an account' : 'Have an account? Login'),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                    ),
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2))),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
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
                    label: const Text('Continue with Google', style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _forgotPassword() async {
      final email = _emailController.text;
      if (email.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your email first")));
          return;
      }
      
      setState(() => _isLoading = true);
      try {
          await context.read<AuthRepository>().resetPasswordForEmail(email);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset email sent!")));
      } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
          if (mounted) setState(() => _isLoading = false);
      }
  }
}
