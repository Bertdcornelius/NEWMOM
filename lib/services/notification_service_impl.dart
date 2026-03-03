import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Real implementation for mobile platforms
class NotificationServicePlatform {
  final fln.FlutterLocalNotificationsPlugin _notificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  static const String _channelId = 'neo_mom_reminders';
  static const String _channelName = 'Feed & Care Reminders';
  static const String _channelDesc = 'Notifications for feeding schedules and baby care reminders';

  Future<void> init() async {
    tz.initializeTimeZones();

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    const fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const fln.InitializationSettings initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
    );

    // Create the high-priority Android notification channel
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const fln.AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: fln.Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      // Request notification permission on Android 13+
      await androidPlugin.requestNotificationsPermission();
    }
  }

  /// Schedule a reminder with a unique [id], at [scheduledTime],
  /// with a [title] and [body] description.
  Future<void> scheduleReminder(int id, DateTime scheduledTime, String title, String body) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: fln.Importance.max,
          priority: fln.Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const fln.DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  /// Legacy method — schedules feed alarm with a generated ID
  Future<void> scheduleFeedAlarm(DateTime scheduledTime) async {
    final id = scheduledTime.millisecondsSinceEpoch % 100000;
    await scheduleReminder(id, scheduledTime, '🍼 Feeding Time!', 'Time to feed your baby');
  }

  /// Cancel a specific reminder by its [id]
  Future<void> cancelReminder(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all scheduled reminders
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Get all pending/active notification requests
  Future<List<fln.PendingNotificationRequest>> getActiveReminders() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
