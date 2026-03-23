import 'package:flutter_test/flutter_test.dart';
import 'package:new_mom_tracker/viewmodels/feeding_viewmodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:new_mom_tracker/repositories/auth_repository.dart';
import 'package:new_mom_tracker/repositories/feeding_repository.dart';
import 'package:new_mom_tracker/services/notification_service.dart';

// Fake Services for unit testing offline logic
class FakeAuthRepository extends Fake implements AuthRepository {
  @override
  User? get currentUser => null; 
}

class FakeFeedingRepository extends Fake implements FeedingRepository {}

class FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<void> init() async {}
  
  @override
  Future<List<dynamic>> getActiveReminders() async {
    return [];
  }
}

void main() {
  group('FeedingViewModel Tests', () {
    late FeedingViewModel viewModel;
    late FakeAuthRepository fakeAuth;
    late FakeFeedingRepository fakeFeeding;
    late FakeNotificationService fakeNotif;

    setUp(() {
      fakeAuth = FakeAuthRepository();
      fakeFeeding = FakeFeedingRepository();
      fakeNotif = FakeNotificationService();
      viewModel = FeedingViewModel(fakeAuth, fakeFeeding, fakeNotif);
    });

    test('Initial state is correct', () {
      expect(viewModel.selectedSide, 'L');
      expect(viewModel.amountMl, 120);
      expect(viewModel.isTimerRunning, false);
      expect(viewModel.durationMinutes, 15);
      expect(viewModel.remindMe, false);
    });

    test('Can change breast feeding side', () {
      viewModel.setSide('R');
      expect(viewModel.selectedSide, 'R');
    });

    test('Can change bottle amount', () {
      viewModel.setAmount(200);
      expect(viewModel.amountMl, 200);
    });

    test('Can set custom duration while timer is not running', () {
      viewModel.setDuration(30);
      expect(viewModel.durationMinutes, 30);
    });

    test('Can toggle timer state', () {
      expect(viewModel.isTimerRunning, false);
      
      viewModel.toggleTimer();
      expect(viewModel.isTimerRunning, true);
      
      viewModel.toggleTimer();
      expect(viewModel.isTimerRunning, false);
    });

    test('Can configure reminders', () {
      viewModel.setRemindMe(true);
      expect(viewModel.remindMe, true);

      viewModel.setReminderInterval(4);
      expect(viewModel.reminderInterval, 4);
    });
  });
}
