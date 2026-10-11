import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/plan.dart';
import '../../data/models/reminder.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'risky_place',
          actions: [
            DarwinNotificationAction.plain('SHOW_MESSAGE', 'Vis beskjed'),
            DarwinNotificationAction.plain(
              'OPEN_MRM',
              'Åpne MRM',
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain('IGNORE', 'Ignorer'),
          ],
        ),
      ],
    );

    final settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  Future<void> requestPermissions() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  void _onNotificationResponse(NotificationResponse response) {
    //fjernet utviklingslogging
  }

  Future<void> cancelReminder(Reminder reminder) async {
    await _plugin.cancel(id: reminder.id.hashCode);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> scheduleReminder({
    required Plan plan,
    required Reminder reminder,
  }) async {
    DateTime? notificationTime;

    if (reminder.type == 'custom') {
      notificationTime = reminder.scheduledAt;
    } else {
      if (reminder.offsetMinutes == null) {
        return;
      }

      if (plan.plannedTime == null) {
        return;
      }

      final parts = plan.plannedTime!.split(':');

      if (parts.length != 2) {
        return;
      }

      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour == null || minute == null) {
        return;
      }

      final eventDateTime = DateTime(
        plan.plannedDate.year,
        plan.plannedDate.month,
        plan.plannedDate.day,
        hour,
        minute,
      );

      notificationTime = eventDateTime.subtract(
        Duration(minutes: reminder.offsetMinutes!),
      );
    }

    if (notificationTime == null) {
      return;
    }

    final scheduledDate = tz.TZDateTime.from(notificationTime, tz.local);

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'plan_reminders',
        'Planpåminnelser',
        channelDescription:
            'Påminnelser for planlagte aktiviteter og situasjoner',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.zonedSchedule(
      id: reminder.id.hashCode,
      title: plan.situationText,
      body: reminder.message ?? 'Påminnelse om planlagt tidspunkt',
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showRiskyPlaceNotification({
    required String placeName,
    required String instruction,
  }) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'risky_place_alerts',
        'Varsler om risikofylte steder',
        channelDescription:
            'Varsler når brukeren befinner seg ved et risikofylt sted',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'risky_place',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: 'risky-place-$placeName'.hashCode,
      title: 'Risikofylt sted',
      body: '$placeName\n$instruction',
      notificationDetails: notificationDetails,
    );
  }
}
