import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';

class AlarmProvider with ChangeNotifier {
  List<AlarmModel> _alarms = [];
  static const String _storageKey = 'alarms';

  List<AlarmModel> get alarms => _alarms;

  AlarmProvider() {
    loadAlarms();
  }

  // Load alarms from storage
  Future<void> loadAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? alarmsJson = prefs.getString(_storageKey);

      if (alarmsJson != null) {
        final List<dynamic> decoded = json.decode(alarmsJson);
        _alarms = decoded.map((item) => AlarmModel.fromJson(item)).toList();
        _sortAlarms();

        // Reschedule all enabled alarms
        await AlarmService.rescheduleAllAlarms(
          _alarms.where((alarm) => alarm.isEnabled).toList(),
        );

        // Update system alarm icon
        final nextAlarm = getNextAlarm();
        if (nextAlarm != null) {
          await AlarmService.showSystemAlarmIcon(nextAlarm);
        } else {
          await AlarmService.hideSystemAlarmIcon();
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading alarms: $e');
    }
  }

  // Save alarms to storage
  Future<void> _saveAlarms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(
        _alarms.map((alarm) => alarm.toJson()).toList(),
      );
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving alarms: $e');
    }
  }

  // Sort alarms by time
  void _sortAlarms() {
    _alarms.sort((a, b) {
      final aTime = a.time.hour * 60 + a.time.minute;
      final bTime = b.time.hour * 60 + b.time.minute;
      return aTime.compareTo(bTime);
    });
  }

  // Add new alarm
  Future<void> addAlarm(AlarmModel alarm) async {
    _alarms.add(alarm);
    _sortAlarms();
    await _saveAlarms();

    // Schedule the alarm if enabled
    if (alarm.isEnabled) {
      await AlarmService.scheduleAlarm(alarm);
    }

    // Update system alarm icon
    final nextAlarm = getNextAlarm();
    if (nextAlarm != null) {
      await AlarmService.showSystemAlarmIcon(nextAlarm);
    } else {
      await AlarmService.hideSystemAlarmIcon();
    }

    notifyListeners();
  }

  // Update existing alarm
  Future<void> updateAlarm(String id, AlarmModel updatedAlarm) async {
    final index = _alarms.indexWhere((alarm) => alarm.id == id);
    if (index != -1) {
      // Cancel old alarm
      await AlarmService.cancelAlarm(id);

      _alarms[index] = updatedAlarm;
      _sortAlarms();
      await _saveAlarms();

      // Schedule new alarm if enabled
      if (updatedAlarm.isEnabled) {
        await AlarmService.scheduleAlarm(updatedAlarm);
      }

      // Update system alarm icon
      final nextAlarm = getNextAlarm();
      if (nextAlarm != null) {
        await AlarmService.showSystemAlarmIcon(nextAlarm);
      } else {
        await AlarmService.hideSystemAlarmIcon();
      }

      notifyListeners();
    }
  }

  // Delete alarm
  Future<void> deleteAlarm(String id) async {
    // Cancel scheduled alarm
    await AlarmService.cancelAlarm(id);

    _alarms.removeWhere((alarm) => alarm.id == id);
    await _saveAlarms();

    // Update system alarm icon
    final nextAlarm = getNextAlarm();
    if (nextAlarm != null) {
      await AlarmService.showSystemAlarmIcon(nextAlarm);
    } else {
      await AlarmService.hideSystemAlarmIcon();
    }

    notifyListeners();
  }

  // Toggle alarm enabled/disabled
  Future<void> toggleAlarm(String id) async {
    final index = _alarms.indexWhere((alarm) => alarm.id == id);
    if (index != -1) {
      final newEnabled = !_alarms[index].isEnabled;
      _alarms[index] = _alarms[index].copyWith(isEnabled: newEnabled);
      await _saveAlarms();

      // Schedule or cancel alarm based on enabled state
      if (newEnabled) {
        await AlarmService.scheduleAlarm(_alarms[index]);
      } else {
        await AlarmService.cancelAlarm(id);
      }

      // Update system alarm icon
      final nextAlarm = getNextAlarm();
      if (nextAlarm != null) {
        await AlarmService.showSystemAlarmIcon(nextAlarm);
      } else {
        await AlarmService.hideSystemAlarmIcon();
      }

      notifyListeners();
    }
  }

  // Get alarm by ID
  AlarmModel? getAlarmById(String id) {
    try {
      return _alarms.firstWhere((alarm) => alarm.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get next scheduled alarm
  AlarmModel? getNextAlarm() {
    final enabledAlarms = _alarms.where((alarm) => alarm.isEnabled).toList();
    if (enabledAlarms.isEmpty) return null;

    AlarmModel? nextAlarm;
    DateTime? nextTime;

    for (var alarm in enabledAlarms) {
      final alarmTime = alarm.getNextAlarmTime();
      if (nextTime == null || alarmTime.isBefore(nextTime)) {
        nextTime = alarmTime;
        nextAlarm = alarm;
      }
    }

    return nextAlarm;
  }
}
