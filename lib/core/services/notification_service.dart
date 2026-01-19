import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/reminders/domain/entities/reminder.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleForReminder(Reminder reminder);
  Future<void> showNowForReminder(Reminder reminder, {String? body});
  Future<void> cancelForReminder(String reminderId);
}

class FlutterLocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _androidChannelId = 'reminder.reminders';
  static const _androidChannelName = 'Reminders';

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();
    final localTz = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTz));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> scheduleForReminder(Reminder reminder) async {
    if (reminder.isDone) {
      await cancelForReminder(reminder.id);
      return;
    }

    final dueAt = reminder.dueAt;
    if (dueAt == null) {
      await cancelForReminder(reminder.id);
      return;
    }

    final when = dueAt.toLocal();
    if (!when.isAfter(DateTime.now())) {
      await cancelForReminder(reminder.id);
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: 'Reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final tzWhen = tz.TZDateTime.from(when, tz.local);

    await _plugin.zonedSchedule(
      _notificationId(reminder.id),
      reminder.title.trim().isEmpty ? 'Reminder' : reminder.title,
      reminder.note.trim().isEmpty ? null : reminder.note,
      tzWhen,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Future<void> showNowForReminder(Reminder reminder, {String? body}) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        _androidChannelName,
        channelDescription: 'Reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final title = reminder.title.trim().isEmpty ? 'Reminder' : reminder.title;
    await _plugin.show(
      _notificationId(reminder.id),
      title,
      body,
      details,
    );
  }

  @override
  Future<void> cancelForReminder(String reminderId) async {
    await _plugin.cancel(_notificationId(reminderId));
  }

  int _notificationId(String reminderId) {
    return reminderId.hashCode & 0x7fffffff;
  }
}
