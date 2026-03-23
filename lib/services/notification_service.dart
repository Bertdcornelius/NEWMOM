
// Conditional import - only use notifications on non-web platforms
import 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_impl.dart';

class NotificationService {
  final NotificationServicePlatform _platform = NotificationServicePlatform();

  Future<void> init() async {
    await _platform.init();
  }

  /// Schedule a reminder with a unique [id], at [scheduledTime],
  /// with a [title] and [body] description.
  Future<void> scheduleReminder(int id, DateTime scheduledTime, String title, String body) async {
    await _platform.scheduleReminder(id, scheduledTime, title, body);
  }

  /// Legacy method — schedules a feed alarm
  Future<void> scheduleFeedAlarm(DateTime scheduledTime) async {
    await _platform.scheduleFeedAlarm(scheduledTime);
  }

  /// Cancel a specific reminder by its [id]
  Future<void> cancelReminder(int id) async {
    await _platform.cancelReminder(id);
  }

  /// Cancel all scheduled reminders
  Future<void> cancelAll() async {
    await _platform.cancelAll();
  }

  /// Get count and details of active reminders
  Future<List<dynamic>> getActiveReminders() async {
    return await _platform.getActiveReminders();
  }
}
