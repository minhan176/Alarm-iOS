class AlarmModel {
  final String id;
  final DateTime time;
  final String label;
  final bool isEnabled;
  final List<int> repeatDays; // 1=Monday, 2=Tuesday, ..., 7=Sunday
  final String sound;
  final bool snooze;
  final bool vibrate;

  AlarmModel({
    required this.id,
    required this.time,
    this.label = 'Alarm',
    this.isEnabled = true,
    this.repeatDays = const [],
    this.sound = 'Radar',
    this.snooze = true,
    this.vibrate = true,
  });

  // Copy with method
  AlarmModel copyWith({
    String? id,
    DateTime? time,
    String? label,
    bool? isEnabled,
    List<int>? repeatDays,
    String? sound,
    bool? snooze,
    bool? vibrate,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      time: time ?? this.time,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
      sound: sound ?? this.sound,
      snooze: snooze ?? this.snooze,
      vibrate: vibrate ?? this.vibrate,
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
      'snooze': snooze,
      'vibrate': vibrate,
    };
  }

  // Create from JSON
  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'],
      time: DateTime.parse(json['time']),
      label: json['label'] ?? 'Alarm',
      isEnabled: json['isEnabled'] ?? true,
      repeatDays: List<int>.from(json['repeatDays'] ?? []),
      sound: json['sound'] ?? 'Radar',
      snooze: json['snooze'] ?? true,
      vibrate: json['vibrate'] ?? true,
    );
  }

  // Get formatted time string
  String getFormattedTime() {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
        ? time.hour - 12
        : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Get repeat description
  String getRepeatDescription() {
    if (repeatDays.isEmpty) {
      return '';
    }

    if (repeatDays.length == 7) {
      return 'Every day';
    }

    if (repeatDays.length == 5 &&
        repeatDays.contains(1) &&
        repeatDays.contains(2) &&
        repeatDays.contains(3) &&
        repeatDays.contains(4) &&
        repeatDays.contains(5)) {
      return 'Weekdays';
    }

    if (repeatDays.length == 2 &&
        repeatDays.contains(6) &&
        repeatDays.contains(7)) {
      return 'Weekends';
    }

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return repeatDays.map((day) => dayNames[day - 1]).join(', ');
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
