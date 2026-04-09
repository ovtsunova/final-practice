import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/event_model.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'event_reminders_channel';
  static const String _channelName = 'Напоминания о мероприятиях';
  static const String _channelDescription =
      'Локальные уведомления о предстоящих мероприятиях';

  Future<void> init() async {
    tz.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(
      tz.getLocation(timezoneInfo.identifier),
    );

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: settings,
    );

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final notificationsGranted =
        await androidPlugin?.requestNotificationsPermission() ?? true;

    final exactBefore =
        await androidPlugin?.canScheduleExactNotifications() ?? true;

    if (!exactBefore) {
      await androidPlugin?.requestExactAlarmsPermission();
    }

    final exactAfter =
        await androidPlugin?.canScheduleExactNotifications() ?? true;

    debugPrint('Notifications permission: $notificationsGranted');
    debugPrint('Exact alarms before request: $exactBefore');
    debugPrint('Exact alarms after request: $exactAfter');

    return notificationsGranted && exactAfter;
  }

  int _notificationIdFromEventId(String eventId) {
    return eventId.hashCode & 0x7fffffff;
  }

  Future<void> scheduleForEvent(EventModel event) async {
    await cancelForEvent(event.id);

    if (event.isCompleted) return;

    final scheduledDate = tz.TZDateTime.from(
      event.remindAt,
      tz.local,
    );

    final now = tz.TZDateTime.now(tz.local);

    debugPrint('Now: $now');
    debugPrint('Scheduled date: $scheduledDate');

    if (!scheduledDate.isAfter(now)) {
      debugPrint('Notification not scheduled: time is not in the future');
      return;
    }

    final body = event.location.isNotEmpty
        ? 'Место: ${event.location}'
        : 'Событие начинается скоро';

    await _plugin.zonedSchedule(
      id: _notificationIdFromEventId(event.id),
      title: 'Напоминание: ${event.title}',
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    final pending = await _plugin.pendingNotificationRequests();
    debugPrint('Pending notifications count: ${pending.length}');
  }

  Future<void> cancelForEvent(String eventId) async {
    await _plugin.cancel(
      id: _notificationIdFromEventId(eventId),
    );
  }

  Future<void> showTestNow() async {
    await _plugin.show(
      id: 999999,
      title: 'Тест уведомления',
      body: 'Если ты это видишь, локальные уведомления работают.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}