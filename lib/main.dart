import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/local_storage_service.dart';
import 'screens/auth/baby_setup_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/auth/welcome_screen.dart';
import 'providers/theme_provider.dart';
import 'services/logger_service.dart';
import 'services/offline_sync_service.dart';
import 'services/baby_data_repository.dart';
import 'viewmodels/feeding_viewmodel.dart';
import 'viewmodels/sleep_viewmodel.dart';

import 'services/local_database_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/sleep_repository.dart';
import 'repositories/feeding_repository.dart';
import 'repositories/milestone_repository.dart';
import 'repositories/care_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LoggerService.initErrorHandler();

  await dotenv.load(fileName: ".env");
  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  


  final sharedPreferences = await SharedPreferences.getInstance();
  final notificationService = NotificationService();
  await notificationService.init();
  final localDatabaseService = LocalDatabaseService();

  await SentryFlutter.init(
    (options) {
      options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      MultiProvider(
        providers: [
          Provider<LocalStorageService>(
            create: (_) => LocalStorageService(sharedPreferences),
          ),
          Provider<LocalDatabaseService>.value(
            value: localDatabaseService,
          ),
          Provider<NotificationService>(
            create: (_) => notificationService,
          ),
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(),
          ),
          ChangeNotifierProvider<OfflineSyncService>(
            create: (context) => OfflineSyncService(
              context.read<LocalStorageService>(),
            ),
          ),
          // --- New Robust Repositories ---
          Provider<AuthRepository>(create: (_) => AuthRepository()),
          ProxyProvider<OfflineSyncService, SleepRepository>(
             update: (context, syncService, prev) => prev ?? SleepRepository(localDatabaseService, offlineSync: syncService),
          ),
          ProxyProvider<OfflineSyncService, FeedingRepository>(
             update: (context, syncService, prev) => prev ?? FeedingRepository(localDatabaseService, offlineSync: syncService),
          ),
          Provider<MilestoneRepository>(create: (_) => MilestoneRepository(localDatabaseService)),
          ProxyProvider<OfflineSyncService, CareRepository>(
             update: (context, syncService, prev) => prev ?? CareRepository(localDatabaseService, offlineSync: syncService),
          ),
          // --------------------------------
          // Phase 2: Core Provider Services


          // Phase 3: High-Level ViewModels & Interactors
          ChangeNotifierProxyProvider4<AuthRepository, FeedingRepository, SleepRepository, CareRepository, BabyDataRepository>(
            create: (context) => BabyDataRepository(
                context.read<AuthRepository>(), context.read<FeedingRepository>(), context.read<SleepRepository>(), context.read<CareRepository>()),
            update: (context, auth, feeding, sleep, care, previous) =>
                previous ?? BabyDataRepository(auth, feeding, sleep, care),
          ),
          ChangeNotifierProxyProvider3<AuthRepository, FeedingRepository, NotificationService, FeedingViewModel>(
            create: (context) => FeedingViewModel(
              context.read<AuthRepository>(),
              context.read<FeedingRepository>(),
              context.read<NotificationService>(),
            ),
            update: (context, auth, feeding, notification, previous) => previous ?? FeedingViewModel(auth, feeding, notification),
          ),
          ChangeNotifierProxyProvider2<AuthRepository, SleepRepository, SleepViewModel>(
            create: (context) => SleepViewModel(context.read<AuthRepository>(), context.read<SleepRepository>()),
            update: (context, auth, sleep, previous) => previous ?? SleepViewModel(auth, sleep),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Neo',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('es', ''), // Spanish
        Locale('fr', ''), // French
      ],
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
  final bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Small delay for Splash effect
      await Future.delayed(const Duration(seconds: 1));

      final session = Supabase.instance.client.auth.currentSession;
      final hasLocalBabyName = context.read<LocalStorageService>().getString('baby_name') != null;

      if (session == null) {
          if (mounted) {
                 Navigator.of(context).pushReplacement(
                     MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                 );
          }
      } else {
          if (!hasLocalBabyName) {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (_) => const BabySetupScreen()),
                );
              }
          } else {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                   MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              }
          }
      }
    } catch (e) {
      debugPrint('AuthGate error: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
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
