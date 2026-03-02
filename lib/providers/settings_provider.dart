import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  bool _is24HourFormat = false;
  bool _isInitialized = false;
  bool _userHasChangedFormat = false;

  bool get is24HourFormat => _is24HourFormat;

  SettingsProvider({bool? initial24HourFormat}) {
    if (initial24HourFormat != null) {
      _loadSettings().then((_) {
        // If no saved setting, use system default
        if (!_isInitialized) {
          _is24HourFormat = initial24HourFormat;
          _isInitialized = true;
        }
      });
    } else {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedFormat = prefs.getBool('is24HourFormat');
      if (savedFormat != null) {
        _is24HourFormat = savedFormat;
        _userHasChangedFormat = true;
        _isInitialized = true;
      }
    } catch (e) {
      // If loading fails, keep default value
    }
  }

  void set24HourFormat(bool value) {
    _is24HourFormat = value;
    _userHasChangedFormat = true;
    _save24HourFormat(value);
    notifyListeners();
  }

  Future<void> _save24HourFormat(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is24HourFormat', value);
    } catch (e) {
      // If saving fails, ignore
    }
  }

  void updateFromSystem(bool system24HourFormat) {
    if (!_userHasChangedFormat) {
      _is24HourFormat = system24HourFormat;
      notifyListeners();
    }
  }
}