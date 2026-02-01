import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';

class AlarmProvider with ChangeNotifier {
  List<AlarmModel> _alarms = [];
  AlarmModel? _lastSavedAlarm;
  static const String _storageKey = 'alarms';

  List<AlarmModel> get alarms => _alarms;
  AlarmModel? get lastSavedAlarm => _lastSavedAlarm;

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
        await AlarmService.updateSystemAlarmIcon();

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

  // Set last saved alarm for toast
  void setLastSavedAlarm(AlarmModel alarm) {
    _lastSavedAlarm = alarm;
    notifyListeners();
  }

  // Clear last saved alarm
  void clearLastSavedAlarm() {
    _lastSavedAlarm = null;
    notifyListeners();
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
    await AlarmService.updateSystemAlarmIcon();

    // Check if rating dialog should be shown (after 3rd alarm)
    await _checkAndShowRatingDialog();

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
      await AlarmService.updateSystemAlarmIcon();

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
    await AlarmService.updateSystemAlarmIcon();

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
      print('DEBUG: toggleAlarm calling updateSystemAlarmIcon');
      await AlarmService.updateSystemAlarmIcon();

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

  // Check and show rating dialog after 3rd alarm creation
  Future<void> _checkAndShowRatingDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user has already rated or dismissed the dialog
      final hasRated = prefs.getBool('has_rated_app') ?? false;
      final dialogDismissed = prefs.getBool('rating_dialog_dismissed') ?? false;

      if (hasRated || dialogDismissed) {
        return; // Don't show dialog
      }

      // Get current alarm creation count
      final alarmCount = prefs.getInt('alarm_creation_count') ?? 0;
      final newCount = alarmCount + 1;

      // Save updated count
      await prefs.setInt('alarm_creation_count', newCount);

      // Show dialog after 3rd alarm
      if (newCount >= 3) {
        // Set flag to show review dialog when back to list
        await prefs.setBool('show_review_dialog', true);
      }
    } catch (e) {
      // Silently handle errors to avoid disrupting alarm creation
      debugPrint('Error checking rating dialog: $e');
    }
  }
}
