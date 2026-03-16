import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:new_mom_tracker/screens/home/feeding_screen.dart';
import 'package:new_mom_tracker/services/baby_data_repository.dart';
import 'package:new_mom_tracker/services/notification_service.dart';
import 'package:new_mom_tracker/viewmodels/feeding_viewmodel.dart';
import 'package:new_mom_tracker/providers/theme_provider.dart';

// Fake implementations for Providers
class FakeBabyDataRepository extends Fake with ChangeNotifier implements BabyDataRepository {
  Future<void> logFeed(String type, Map<String, dynamic> details, DateTime time) async {}
}

class FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<List<dynamic>> getActiveReminders() async => [];
}

void main() {
  late FakeBabyDataRepository fakeBabyDataRepository;
  late FakeNotificationService fakeNotificationService;
  late FeedingViewModel feedingViewModel;

  setUp(() {
    fakeBabyDataRepository = FakeBabyDataRepository();
    fakeNotificationService = FakeNotificationService();
    feedingViewModel = FeedingViewModel(fakeBabyDataRepository);
  });

  Widget createFeedingScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        Provider<NotificationService>.value(value: fakeNotificationService),
        ChangeNotifierProvider<BabyDataRepository>.value(value: fakeBabyDataRepository),
        ChangeNotifierProvider<FeedingViewModel>.value(value: feedingViewModel),
      ],
      child: const MaterialApp(
        home: FeedingScreen(),
      ),
    );
  }

  testWidgets('FeedingScreen shows essential UI elements', (WidgetTester tester) async {
    await tester.pumpWidget(createFeedingScreen());
    await tester.pumpAndSettle();

    // Verify main feeding type tabs exist
    expect(find.text('Breast'), findsOneWidget);
    expect(find.text('Bottle'), findsOneWidget);
    expect(find.text('Solids'), findsOneWidget);

    // Verify Date & Time selector is present
    expect(find.text('Date & Time'), findsOneWidget);

    // Verify Save button is present
    expect(find.text('Save Log'), findsOneWidget);
  });
}
