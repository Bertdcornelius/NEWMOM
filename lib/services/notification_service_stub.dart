// Stub implementation for web - notifications not supported
class NotificationServicePlatform {
  Future<void> init() async {
    // No-op on web
  }

  Future<void> scheduleFeedAlarm(DateTime scheduledTime) async {
    print("Notification scheduled for: $scheduledTime (Web - not supported)");
  }
  
  Future<void> cancelAll() async {
    // No-op on web
  }
}
