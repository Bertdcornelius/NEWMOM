// Stub implementation for web - notifications not supported
class NotificationServicePlatform {
  Future<void> init() async {
    // No-op on web
  }

  Future<void> scheduleReminder(int id, DateTime scheduledTime, String title, String body) async {
    print("Reminder scheduled: id=$id, time=$scheduledTime, title=$title (Web - not supported)");
  }

  Future<void> scheduleFeedAlarm(DateTime scheduledTime) async {
    print("Notification scheduled for: $scheduledTime (Web - not supported)");
  }

  Future<void> cancelReminder(int id) async {
    // No-op on web
  }

  Future<void> cancelAll() async {
    // No-op on web
  }

  Future<List<dynamic>> getActiveReminders() async {
    return [];
  }
}
