import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_mom_tracker/screens/auth/login_screen.dart';
import 'package:new_mom_tracker/repositories/auth_repository.dart';
import 'package:new_mom_tracker/services/local_storage_service.dart';
import 'package:new_mom_tracker/providers/theme_provider.dart';
import 'package:new_mom_tracker/core/result.dart';

class FakeAuthRepository extends Fake implements AuthRepository {
  @override
  Future<Result<Map<String, dynamic>>> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return Failure('Empty fields');
    return Success({});
  }
}

class FakeLocalStorageService extends Fake implements LocalStorageService {
  @override
  String? getString(String key) => null;
}

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeLocalStorageService fakeLocalStorageService;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeLocalStorageService = FakeLocalStorageService();
  });

  Widget createLoginScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        Provider<AuthRepository>.value(value: fakeAuthRepository),
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
    
    // There are two "Login" texts: AppBar and Button
    expect(find.text('Login'), findsWidgets);
    
    // Verify Google sign in
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('LoginScreen calls sign in with failure gracefully', (WidgetTester tester) async {
    await tester.pumpWidget(createLoginScreen());
    await tester.pumpAndSettle();

    // Tap the submit button without filling fields
    // There are multiple Login texts (AppBar, ElevatedButton) so we find by Widget type and text
    final loginButtonFinder = find.widgetWithText(ElevatedButton, 'Login');
    await tester.tap(loginButtonFinder);
    await tester.pump(); // trigger
    await tester.pumpAndSettle();

    // Our fake returns "Empty fields" failure message
    expect(find.textContaining('Error: Empty fields'), findsOneWidget);
  });
}
