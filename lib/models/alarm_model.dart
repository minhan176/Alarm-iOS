import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class AlarmModel {
  final String id;
  final DateTime time;
  final String label;
  final bool isEnabled;
  final List<int> repeatDays; // 1=Monday, 2=Tuesday, ..., 7=Sunday
  final String sound;
  final String? soundDisplayName;
  final bool snooze;
  final bool vibrate;
  final Duration snoozeDuration;

  AlarmModel({
    required this.id,
    required this.time,
    this.label = '',
    this.isEnabled = true,
    this.repeatDays = const [],
    this.sound = 'assets/sounds/alarm.wav',
    this.soundDisplayName,
    this.snooze = true,
    this.vibrate = true,
    this.snoozeDuration = const Duration(minutes: 5),
  });

  // Copy with method
  AlarmModel copyWith({
    String? id,
    DateTime? time,
    String? label,
    bool? isEnabled,
    List<int>? repeatDays,
    String? sound,
    String? soundDisplayName,
    bool? snooze,
    bool? vibrate,
    Duration? snoozeDuration,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      time: time ?? this.time,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      sound: sound ?? this.sound,
      soundDisplayName: soundDisplayName ?? this.soundDisplayName,
      snooze: snooze ?? this.snooze,
      vibrate: vibrate ?? this.vibrate,
      snoozeDuration: snoozeDuration ?? this.snoozeDuration,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time.toIso8601String(),
      'label': label,
      'isEnabled': isEnabled,
      'repeatDays': repeatDays,
      'sound': sound,
      'soundDisplayName': soundDisplayName,
      'snooze': snooze,
      'vibrate': vibrate,
      'snoozeDuration': snoozeDuration.inMinutes,
    };
  }

  // Create from JSON
  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'],
      time: DateTime.parse(json['time']),
      label: json['label'] ?? '',
      isEnabled: json['isEnabled'] ?? true,
      repeatDays: List<int>.from(json['repeatDays'] ?? []),
      sound: json['sound'] ?? 'assets/sounds/alarm.wav',
      soundDisplayName: json['soundDisplayName'],
      snooze: json['snooze'] ?? true,
      vibrate: json['vibrate'] ?? true,
      snoozeDuration: Duration(minutes: json['snoozeDuration'] ?? 5),
    );
  }

  // Get formatted time string based on device setting
  String getFormattedTime({bool use24HourFormat = false}) {
    if (use24HourFormat) {
      // 24-hour format
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      // 12-hour format with AM/PM
      final hour = time.hour == 0
          ? 12
          : time.hour > 12
          ? time.hour - 12
          : time.hour;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
  }

  // Get repeat description
  String getRepeatDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (repeatDays.isEmpty) {
      return '';
    }

    if (repeatDays.length == 7) {
      return l10n.everyDay;
    }

    if (repeatDays.length == 5 &&
        repeatDays.contains(1) &&
        repeatDays.contains(2) &&
        repeatDays.contains(3) &&
        repeatDays.contains(4) &&
        repeatDays.contains(5)) {
      return l10n.weekdays;
    }

    if (repeatDays.length == 2 &&
        repeatDays.contains(6) &&
        repeatDays.contains(7)) {
      return l10n.weekends;
    }

    final dayGetters = [l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat, l10n.sun];
    return repeatDays.map((day) => dayGetters[day - 1]).join(' ');
  }

  // Calculate next alarm time
  DateTime getNextAlarmTime() {
    final now = DateTime.now();
    DateTime nextAlarm = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (repeatDays.isEmpty) {
      // One-time alarm
      if (nextAlarm.isBefore(now)) {
        nextAlarm = nextAlarm.add(const Duration(days: 1));
      }
    } else {
      // Repeating alarm
      while (!repeatDays.contains(nextAlarm.weekday) ||
          nextAlarm.isBefore(now)) {
        nextAlarm = nextAlarm.add(const Duration(days: 1));
      }
    }

    return nextAlarm;
  }
}
