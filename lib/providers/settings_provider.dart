import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  bool _is24HourFormat = false;
  bool _isInitialized = false;

  bool get is24HourFormat => _is24HourFormat;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _is24HourFormat = prefs.getBool('is24HourFormat') ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  void initializeWithSystemSetting(bool system24HourFormat) {
    if (!_isInitialized) {
      _is24HourFormat = system24HourFormat;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> set24HourFormat(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is24HourFormat', value);
    _is24HourFormat = value;
    notifyListeners();
  }
}