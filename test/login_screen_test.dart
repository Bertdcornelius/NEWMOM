import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_mom_tracker/screens/auth/login_screen.dart';
import 'package:new_mom_tracker/services/auth_repository.dart';
import 'package:new_mom_tracker/services/baby_data_repository.dart';
import 'package:new_mom_tracker/services/local_storage_service.dart';
import 'package:new_mom_tracker/providers/theme_provider.dart';

// Create fake classes to avoid Mockito null-safety code generation requirements
class FakeAuthRepository extends Fake with ChangeNotifier implements AuthRepository {
  @override
  Future<void> signIn(String email, String password) async {}
  @override
  Future<void> signUp(String email, String password) async {}
}

class FakeBabyDataRepository extends Fake with ChangeNotifier implements BabyDataRepository {
  @override
  Future<bool> registerDevice(String deviceId) async => true;
}

class FakeLocalStorageService extends Fake implements LocalStorageService {
  @override
  String? getString(String key) {
    if (key == 'device_id') return 'dummy-device-id';
    return null;
  }
}

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeBabyDataRepository fakeBabyDataRepository;
  late FakeLocalStorageService fakeLocalStorageService;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeBabyDataRepository = FakeBabyDataRepository();
    fakeLocalStorageService = FakeLocalStorageService();
  });

  Widget createLoginScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AuthRepository>.value(value: fakeAuthRepository),
        ChangeNotifierProvider<BabyDataRepository>.value(value: fakeBabyDataRepository),
        Provider<LocalStorageService>.value(value: fakeLocalStorageService),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen shows correct UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Verify UI holds email and password text fields
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Welcome\nBack'), findsOneWidget);
  });

  testWidgets('LoginScreen validation shows error when empty', (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Tap the submit button without filling fields
    await tester.tap(find.text('Sign In').first);
    await tester.pump(); // trigger snackbar

    expect(find.text('Please fill in all fields'), findsOneWidget);
  });
}
