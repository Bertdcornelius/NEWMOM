import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import - only use notifications on non-web platforms
import 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_impl.dart';

class NotificationService {
  final NotificationServicePlatform _platform = NotificationServicePlatform();

  Future<void> init() async {
    await _platform.init();
  }

  Future<void> scheduleFeedAlarm(DateTime scheduledTime) async {
    await _platform.scheduleFeedAlarm(scheduledTime);
  }
  
  Future<void> cancelAll() async {
    await _platform.cancelAll();
  }
}
