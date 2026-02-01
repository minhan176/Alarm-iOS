import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  bool _is24HourFormat = false;
  bool _isInitialized = false;

  bool get is24HourFormat => _is24HourFormat;

  SettingsProvider({bool? initial24HourFormat}) {
    if (initial24HourFormat != null) {
      _is24HourFormat = initial24HourFormat;
      _isInitialized = true;
    } else {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    // No longer loading from prefs, always use system setting
  }

  void set24HourFormat(bool value) {
    _is24HourFormat = value;
    notifyListeners();
  }
}