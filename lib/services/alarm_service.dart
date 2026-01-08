import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../models/alarm_model.dart';

// Top-level callback function for alarm manager (must be outside class)
@pragma('vm:entry-point')
void alarmCallback(int id, Map<String, dynamic> params) async {
  print('Alarm triggered: $id');

  // Parse alarm data
  final alarm = AlarmModel.fromJson(params);

  // Check if alarm should ring today (for repeating alarms)
  if (alarm.repeatDays.isNotEmpty) {
    final now = DateTime.now();
    final weekday = now.weekday; // Monday = 1, Sunday = 7
    if (!alarm.repeatDays.contains(weekday)) {
      print('Alarm skipped for today');
      return;
    }
  } else {
    // For one-time alarms, cancel after triggering
    print('One-time alarm triggered, will be disabled after dismiss');
  }

  // Show notification with full screen intent
  await AlarmService.showAlarmNotification(alarm);

  // Trigger alarm callback if available
  if (AlarmService.onAlarmRing != null) {
    AlarmService.onAlarmRing!(alarm);
  }
}

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static Function(AlarmModel)? onAlarmRing;

  // Initialize the alarm service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize android alarm manager
    await AndroidAlarmManager.initialize();

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _isInitialized = true;
  }

  // Request notification permissions
  static Future<void> _requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) async {
    print('Notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        // Load alarm from shared preferences
        final prefs = await SharedPreferences.getInstance();
        final alarmsJson = prefs.getString('alarms');

        if (alarmsJson != null) {
          final List<dynamic> decoded = json.decode(alarmsJson);
          final alarms = decoded
              .map((item) => AlarmModel.fromJson(item))
              .toList();
          final alarm = alarms.firstWhere(
            (a) => a.id == response.payload,
            orElse: () => alarms.first,
          );

          // Trigger alarm through callback
          if (onAlarmRing != null) {
            onAlarmRing!(alarm);
          }
        }
      } catch (e) {
        print('Error loading alarm: $e');
      }
    }
  }

  // Schedule an alarm
  static Future<void> scheduleAlarm(AlarmModel alarm) async {
    if (!alarm.isEnabled) return;

    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      alarm.time.hour,
      alarm.time.minute,
    );

    // If the time has passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final alarmId = alarm.id.hashCode;

    if (alarm.repeatDays.isEmpty) {
      // One-time alarm
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        alarmId,
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
        params: alarm.toJson(),
      );
    } else {
      // Repeating alarm - schedule daily and check repeat days in callback
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        alarmId,
        alarmCallback,
        startAt: scheduledTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
        params: alarm.toJson(),
      );
    }

    print('Alarm scheduled: ${alarm.label} at ${alarm.getFormattedTime()}');
  }

  // Cancel an alarm
  static Future<void> cancelAlarm(String alarmId) async {
    final id = alarmId.hashCode;
    await AndroidAlarmManager.cancel(id);
    await _notificationsPlugin.cancel(id);
    print('Alarm cancelled: $alarmId');
  }

  // Dismiss alarm (called when user dismisses the alarm ring screen)
  static Future<void> dismissAlarm(AlarmModel alarm) async {
    final id = alarm.id.hashCode;

    // Cancel the notification
    await _notificationsPlugin.cancel(id);

    // If it's a one-time alarm, cancel the alarm schedule and disable it
    if (alarm.repeatDays.isEmpty) {
      await AndroidAlarmManager.cancel(id);

      // Update alarm to disabled in storage
      try {
        final prefs = await SharedPreferences.getInstance();
        final alarmsJson = prefs.getString('alarms');

        if (alarmsJson != null) {
          final List<dynamic> decoded = json.decode(alarmsJson);
          final alarms = decoded
              .map((item) => AlarmModel.fromJson(item))
              .toList();

          // Find and update the alarm
          final index = alarms.indexWhere((a) => a.id == alarm.id);
          if (index != -1) {
            alarms[index] = alarms[index].copyWith(isEnabled: false);

            // Save back to storage
            final String encoded = json.encode(
              alarms.map((a) => a.toJson()).toList(),
            );
            await prefs.setString('alarms', encoded);
          }
        }
      } catch (e) {
        print('Error disabling one-time alarm: $e');
      }

      print('One-time alarm dismissed and disabled: ${alarm.id}');
    } else {
      // For repeating alarms, just cancel the notification
      // The alarm will ring again on the next scheduled day
      print('Repeating alarm dismissed: ${alarm.id}');
    }
  }

  // Show alarm notification
  static Future<void> showAlarmNotification(AlarmModel alarm) async {
    final androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Notifications for alarms',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      channelShowBadge: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction('snooze', 'Snooze', showsUserInterface: true),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      alarm.id.hashCode,
      alarm.label.isEmpty ? 'Alarm' : alarm.label,
      alarm.getFormattedTime(),
      notificationDetails,
      payload: alarm.id,
    );
  }

  // Test notification (for debugging)
  static Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'alarm_channel',
      'Alarm Notifications',
      channelDescription: 'Notifications for alarms',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      999,
      'Test Alarm',
      'This is a test alarm notification',
      notificationDetails,
    );
  }

  // Reschedule all alarms (useful after reboot)
  static Future<void> rescheduleAllAlarms(List<AlarmModel> alarms) async {
    for (final alarm in alarms) {
      if (alarm.isEnabled) {
        await scheduleAlarm(alarm);
      }
    }
  }
}
