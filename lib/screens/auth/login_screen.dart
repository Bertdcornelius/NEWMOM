import 'package:flutter/material.dart';
import '../../widgets/premium_ui_components.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';
import '../../services/local_storage_service.dart';
import 'package:uuid/uuid.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final authService = context.read<SupabaseService>();
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      if (_isLogin) {
        await authService.signIn(email, password);

        // Device Limit Check
        if (mounted) {
            final prefs = context.read<LocalStorageService>();
            String? deviceId = prefs.getString('device_id');
            if (deviceId == null) {
                deviceId = const Uuid().v4();
                await prefs.saveString('device_id', deviceId);
            }

            final allowed = await authService.registerDevice(deviceId);
            if (!allowed) {
                await authService.signOut();
                if (mounted) {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                            title: Text('Device Limit Reached'),
                            content: Text('Maximum of 2 devices allowed. Please upgrade to Premium.'),
                            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                        ),
                    );
                }
                return;
            }
        }
      } else {
        await authService.signUp(email, password);
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Check your email for confirmation link')),
            );
        }
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString();
        // Check for common "Email not confirmed" error strings from Supabase
        if (message.contains("Email not confirmed") || message.contains("400") || message.toLowerCase().contains("confirm")) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Login Failed: $e'),
                action: SnackBarAction(
                  label: "Resend Email",
                  onPressed: () async {
                      try {
                          await authService.resendConfirmationEmail(email);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Confirmation email resent!")));
                      } catch (err) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error resending: $err")));
                      }
                  },
                ),
                duration: const Duration(seconds: 10),
              ),
            );
        } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Padding(
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
                  child: Text('Forgot Password?'),
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
          ],
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
          await context.read<SupabaseService>().resetPasswordForEmail(email);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password reset email sent!")));
      } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
          if (mounted) setState(() => _isLoading = false);
      }
  }
}
