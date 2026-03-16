import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/supabase_service.dart';
import 'services/local_storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/dashboard_screen.dart';

import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/notification_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // TODO: Replace with your Supabase URL and Anon Key
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  


  final sharedPreferences = await SharedPreferences.getInstance();
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalStorageService>(
          create: (_) => LocalStorageService(sharedPreferences),
        ),
        Provider<NotificationService>(
          create: (_) => notificationService,
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<SupabaseService>(
          create: (context) => SupabaseService(
            context.read<LocalStorageService>(),
          ),
        ),

      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Neo: New Mom Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B9080), brightness: Brightness.light), // Sage Green Seed
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFDFDFD),
        textTheme: GoogleFonts.nunitoTextTheme(ThemeData.light().textTheme),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B9080), brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212), // Deep charcoal backdrop
        textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
      // Small delay for Splash effect
      await Future.delayed(const Duration(seconds: 1));

      final session = Supabase.instance.client.auth.currentSession;
      final isGuest = context.read<LocalStorageService>().getString('guest_mode') == 'true';
      final hasLocalBabyName = context.read<LocalStorageService>().getString('baby_name') != null;

      if (session == null && !isGuest && !hasLocalBabyName) {
          // Show Welcome Screen (Guest vs Login)
           if (mounted) {
                 Navigator.of(context).pushReplacement(
                     MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                 );
           }
      } else {
          // Already logged in
          if (mounted) {
            Navigator.of(context).pushReplacement(
               MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          }
      }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
