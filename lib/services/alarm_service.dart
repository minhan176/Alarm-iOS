import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import '../models/alarm_model.dart';
import '../screens/alarm_ring_screen.dart';
import '../main.dart'; // Import for navigatorKey

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

  // Initialize notifications plugin for isolate
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Show notification (this will trigger the ring screen via full screen intent)
  final androidDetails = AndroidNotificationDetails(
    'alarm_channel',
    'Alarm Notifications',
    channelDescription: 'Notifications for alarms',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: alarm.vibrate,
    vibrationPattern: alarm.vibrate
        ? Int64List.fromList([0, 1000, 500, 1000])
        : null,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    ongoing: true,
    autoCancel: false,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    channelShowBadge: true,
    showWhen: false,
    timeoutAfter: null,
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

  await notificationsPlugin.show(
    alarm.id.hashCode,
    alarm.label.isEmpty ? 'Alarm' : alarm.label,
    alarm.getFormattedTime(),
    notificationDetails,
    payload: alarm.id,
  );
  
  print('Alarm notification shown for: ${alarm.label}');
}

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const MethodChannel _alarmChannel = MethodChannel('com.example.alarm/alarm');
  static const MethodChannel _navigationChannel = MethodChannel('com.example.alarm/navigation');

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
      onDidReceiveBackgroundNotificationResponse: _onNotificationAction,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    // Request permissions for Android 13+
    await _requestPermissions();

    // Set up navigation method channel handler
    _navigationChannel.setMethodCallHandler(_handleNavigationMethodCall);

    _isInitialized = true;
  }

  // Handle navigation method calls from Android
  static Future<void> _handleNavigationMethodCall(MethodCall call) async {
    if (call.method == 'navigateToRingScreen') {
      final alarmJson = call.arguments as String?;
      if (alarmJson != null) {
        try {
          final alarm = AlarmModel.fromJson(json.decode(alarmJson));
          _showAlarmScreen(alarm);
        } catch (e) {
          print('Error parsing alarm from navigation: $e');
        }
      }
    }
  }

  // Create notification channel
  static Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'alarm_channel',
      'Alarm Notifications',
      description: 'Notifications for alarms',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
      ledColor: const Color(0xFFFF9500), // Orange color
    );

    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(androidChannel);
    }
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

          // Show alarm screen
          _showAlarmScreen(alarm);
        }
      } catch (e) {
        print('Error loading alarm: $e');
      }
    }
  }

  // Handle notification action (background)
  static void _onNotificationAction(NotificationResponse response) {
    print('Notification action: ${response.actionId} for ${response.payload}');

    if (response.payload != null) {
      if (response.actionId == 'dismiss') {
        // Handle dismiss action
        _dismissAlarmFromNotification(response.payload!);
      } else if (response.actionId == 'snooze') {
        // Handle snooze action
        _snoozeAlarmFromNotification(response.payload!);
      } else if (response.actionId == null || response.actionId!.isEmpty) {
        // Notification was displayed (full screen intent), open ring screen directly
        _openRingScreenFromNotification(response.payload!);
      }
    }
  }

  // Open ring screen from notification (when full screen intent triggers)
  static void _openRingScreenFromNotification(String alarmId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getString('alarms');

      if (alarmsJson != null) {
        final List<dynamic> decoded = json.decode(alarmsJson);
        final alarms = decoded
            .map((item) => AlarmModel.fromJson(item))
            .toList();

        final alarm = alarms.firstWhere((a) => a.id == alarmId);

        // Open ring screen directly
        _showAlarmScreen(alarm);
      }
    } catch (e) {
      print('Error opening ring screen from notification: $e');
    }
  }

  // Dismiss alarm from notification action
  static void _dismissAlarmFromNotification(String alarmId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getString('alarms');

      if (alarmsJson != null) {
        final List<dynamic> decoded = json.decode(alarmsJson);
        final alarms = decoded
            .map((item) => AlarmModel.fromJson(item))
            .toList();

        final alarm = alarms.firstWhere((a) => a.id == alarmId);

        // Cancel the alarm
        await AndroidAlarmManager.cancel(alarm.id.hashCode);

        // For one-time alarms, disable them
        if (alarm.repeatDays.isEmpty) {
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
              final index = alarms.indexWhere((a) => a.id == alarmId);
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
        }

        // Update system alarm icon after dismissing
        await updateSystemAlarmIcon();

        print('Alarm dismissed from notification: $alarmId');
      }
    } catch (e) {
      print('Error dismissing alarm from notification: $e');
    }
  }

  // Centralized method to update system alarm icon based on current alarm state
  static Future<void> updateSystemAlarmIcon() async {
    try {
      print('DEBUG: updateSystemAlarmIcon called');
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getString('alarms');

      if (alarmsJson != null) {
        final List<dynamic> decoded = json.decode(alarmsJson);
        final alarms = decoded
            .map((item) => AlarmModel.fromJson(item))
            .toList();

        final enabledAlarms = alarms.where((alarm) => alarm.isEnabled).toList();
        print('DEBUG: updateSystemAlarmIcon - enabled alarms count: ${enabledAlarms.length}');

        if (enabledAlarms.isNotEmpty) {
          // Find next alarm
          AlarmModel? nextAlarm;
          DateTime? nextTime;

          for (var alarm in enabledAlarms) {
            final alarmTime = alarm.getNextAlarmTime();
            if (nextTime == null || alarmTime.isBefore(nextTime)) {
              nextTime = alarmTime;
              nextAlarm = alarm;
            }
          }

          if (nextAlarm != null) {
            print('DEBUG: updateSystemAlarmIcon - showing icon for: ${nextAlarm.label}');
            await showSystemAlarmIcon(nextAlarm);
          } else {
            print('DEBUG: updateSystemAlarmIcon - no next alarm found, hiding icon');
            await hideSystemAlarmIcon();
          }
        } else {
          // No enabled alarms, hide icon
          print('DEBUG: updateSystemAlarmIcon - no enabled alarms, hiding icon');
          await hideSystemAlarmIcon();
        }
      } else {
        print('DEBUG: updateSystemAlarmIcon - no alarms data, hiding icon');
        await hideSystemAlarmIcon();
      }
    } catch (e) {
      print('Error updating system alarm icon: $e');
    }
  }

  // Snooze alarm from notification action
  static void _snoozeAlarmFromNotification(String alarmId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alarmsJson = prefs.getString('alarms');

      if (alarmsJson != null) {
        final List<dynamic> decoded = json.decode(alarmsJson);
        final alarms = decoded
            .map((item) => AlarmModel.fromJson(item))
            .toList();

        final alarm = alarms.firstWhere((a) => a.id == alarmId);

        // Cancel current alarm
        await AndroidAlarmManager.cancel(alarm.id.hashCode);

        // Schedule snooze based on alarm's snooze duration
        final snoozeTime = DateTime.now().add(alarm.snoozeDuration);
        await AndroidAlarmManager.oneShotAt(
          snoozeTime,
          alarm.id.hashCode,
          alarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          allowWhileIdle: true,
          params: alarm.toJson(),
        );

        // Update system alarm icon after snoozing (alarm is still enabled)
        await updateSystemAlarmIcon();

        print('Alarm snoozed for ${alarm.snoozeDuration.inMinutes} minutes: $alarmId');
      }
    } catch (e) {
      print('Error snoozing alarm from notification: $e');
    }
  }

  // Show alarm screen (can be called from notification tap or callback)
  static void _showAlarmScreen(AlarmModel alarm) {
    // Use the navigator key from main.dart
    navigatorKey.currentState?.push(
      CupertinoPageRoute(
        builder: (context) => AlarmRingScreen(alarm: alarm),
        fullscreenDialog: true,
      ),
    );
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

    // For repeating alarms, find the next valid day
    if (alarm.repeatDays.isNotEmpty) {
      int daysToAdd = 0;
      int maxDays = 7; // Check up to 7 days ahead

      while (daysToAdd < maxDays) {
        final checkTime = scheduledTime.add(Duration(days: daysToAdd));
        final weekday = checkTime.weekday; // Monday = 1, Sunday = 7

        if (alarm.repeatDays.contains(weekday)) {
          scheduledTime = checkTime;
          break;
        }
        daysToAdd++;
      }

      print(
        'Next repeat alarm scheduled for: $scheduledTime (${_getDayName(scheduledTime.weekday)})',
      );
    }

    final alarmId = alarm.id.hashCode;

    // Use AndroidAlarmManager for both one-time and repeating alarms
    // This ensures consistent behavior and works when app is killed
    if (alarm.repeatDays.isEmpty) {
      // One-time alarm - use AlarmPlugin for direct activity start
      await _alarmChannel.invokeMethod('scheduleAlarm', {
        'alarm': json.encode(alarm.toJson()),
        'alarmTime': scheduledTime.millisecondsSinceEpoch,
        'alarmId': alarm.id,
      });
      print('One-time alarm scheduled for: $scheduledTime');
    } else {
      // Repeating alarm - still use AndroidAlarmManager for complex repeat logic
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
      print('Repeating alarm scheduled, checking daily from: $scheduledTime');
    }

    print('Alarm scheduled: ${alarm.label} at ${alarm.getFormattedTime()}');
  }

  static String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  // Cancel an alarm
  static Future<void> cancelAlarm(String alarmId) async {
    final id = alarmId.hashCode;
    await AndroidAlarmManager.cancel(id);
    await _notificationsPlugin.cancel(id);
    
    // Also cancel through AlarmPlugin for one-time alarms
    try {
      await _alarmChannel.invokeMethod('cancelAlarm', {'alarmId': alarmId});
    } catch (e) {
      // Ignore if method not available
    }
    
    print('Alarm cancelled: $alarmId');
  }

  // Dismiss alarm (called when user dismisses the alarm ring screen)
  static Future<void> dismissAlarm(AlarmModel alarm) async {
    final id = alarm.id.hashCode;

    // Cancel the notification
    await _notificationsPlugin.cancel(id);

    // Always disable the alarm after dismissing
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

          // Notify listeners to update UI
          // Note: This assumes there's a way to access the provider, but since this is a static method,
          // we'll rely on the screen calling loadAlarms() instead
        }
      }
    } catch (e) {
      print('Error disabling alarm: $e');
    }

    print('Alarm dismissed and disabled: ${alarm.id}');
  }

  // Show alarm notification
  static Future<void> showAlarmNotification(AlarmModel alarm) async {
    final androidDetails = AndroidNotificationDetails(
      'alarm_channel', // Use the channel we created
      'Alarm Notifications',
      channelDescription: 'Notifications for alarms',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: alarm.vibrate,
      vibrationPattern: alarm.vibrate
          ? Int64List.fromList([0, 1000, 500, 1000])
          : null,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ongoing: true,
      autoCancel: false,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      channelShowBadge: true,
      showWhen: false,
      timeoutAfter: null,
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

  // Show system alarm icon on status bar
  static Future<void> showSystemAlarmIcon(AlarmModel alarm) async {
    try {
      final scheduledTime = _getNextAlarmTime(alarm);
      if (scheduledTime != null) {
        print('DEBUG: showSystemAlarmIcon called for alarm: ${alarm.label}');
        await _alarmChannel.invokeMethod('showAlarmIcon', {
          'alarmId': alarm.id.hashCode,
          'timestamp': scheduledTime.millisecondsSinceEpoch,
          'label': alarm.label.isEmpty ? 'Alarm' : alarm.label,
        });
        print('DEBUG: showSystemAlarmIcon completed');
      } else {
        print('DEBUG: showSystemAlarmIcon - no scheduled time for alarm: ${alarm.label}');
      }
    } catch (e) {
      print('Error showing system alarm icon: $e');
    }
  }

  // Hide system alarm icon from status bar
  static Future<void> hideSystemAlarmIcon() async {
    try {
      print('DEBUG: hideSystemAlarmIcon called - attempting to hide alarm icon');
      await _alarmChannel.invokeMethod('hideAlarmIcon');
      print('DEBUG: hideSystemAlarmIcon completed');
    } catch (e) {
      print('Error hiding system alarm icon: $e');
    }
  }

  // Get next alarm time for system icon
  static DateTime? _getNextAlarmTime(AlarmModel alarm) {
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

    // For repeating alarms, find the next valid day
    if (alarm.repeatDays.isNotEmpty) {
      int daysToAdd = 0;
      while (daysToAdd < 7) {
        final checkTime = scheduledTime.add(Duration(days: daysToAdd));
        final weekday = checkTime.weekday;
        if (alarm.repeatDays.contains(weekday)) {
          scheduledTime = checkTime;
          break;
        }
        daysToAdd++;
      }
    }

    return scheduledTime;
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
