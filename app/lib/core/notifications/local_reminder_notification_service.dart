import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class LocalReminderNotificationService {
  static const _channelId = 'household_reminders';
  static const _channelName = 'Lembretes da casa';
  static const _channelDescription =
      'Lembretes pessoais agendados nas Rotinas da Casa.';

  final FlutterLocalNotificationsPlugin plugin;
  bool _initialized = false;

  LocalReminderNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    tzdata.initializeTimeZones();
    try {
      final currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));
    } catch (error) {
      debugPrint('Could not resolve local timezone: $error');
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
    );
  }

  Future<void> schedule({
    required String reminderId,
    required String taskId,
    required String taskTitle,
    required DateTime remindAt,
  }) async {
    await initialize();
    if (kIsWeb) {
      throw UnsupportedError(
        'Lembretes locais ainda não estão disponíveis na versão web.',
      );
    }

    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios = plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final scheduledDate = tz.TZDateTime.from(remindAt, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!scheduledDate.isAfter(now)) {
      throw ArgumentError('O horário do lembrete precisa estar no futuro.');
    }

    await plugin.zonedSchedule(
      id: reminderId.hashCode & 0x7fffffff,
      title: 'DuoSpend • Lembrete',
      body: taskTitle,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'household_task:$taskId',
    );
  }
}
