import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/world_clock_model.dart';

class WorldClockProvider extends ChangeNotifier {
  List<WorldClockModel> _clocks = [];
  static const String _storageKey = 'world_clocks';

  List<WorldClockModel> get clocks => _clocks;

  WorldClockProvider() {
    _loadClocks();
  }

  Future<void> _loadClocks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? clocksJson = prefs.getString(_storageKey);
    
    if (clocksJson != null) {
      final List<dynamic> decoded = json.decode(clocksJson);
      _clocks = decoded.map((item) => WorldClockModel.fromJson(item)).toList();
    } else {
      // Define default clocks based on country
      Map<String, Map<String, String>> defaultClocks = {
        'VN': {'city': 'Hanoi', 'timezone': 'Asia/Ho_Chi_Minh', 'country': 'Vietnam'},
        'US': {'city': 'New York', 'timezone': 'America/New_York', 'country': 'United States'},
        'GB': {'city': 'London', 'timezone': 'Europe/London', 'country': 'United Kingdom'},
        'JP': {'city': 'Tokyo', 'timezone': 'Asia/Tokyo', 'country': 'Japan'},
        'KR': {'city': 'Seoul', 'timezone': 'Asia/Seoul', 'country': 'South Korea'},
        'CN': {'city': 'Beijing', 'timezone': 'Asia/Shanghai', 'country': 'China'},
        'IN': {'city': 'New Delhi', 'timezone': 'Asia/Kolkata', 'country': 'India'},
        'DE': {'city': 'Berlin', 'timezone': 'Europe/Berlin', 'country': 'Germany'},
        'FR': {'city': 'Paris', 'timezone': 'Europe/Paris', 'country': 'France'},
        'AU': {'city': 'Sydney', 'timezone': 'Australia/Sydney', 'country': 'Australia'},
      };

      String countryCode = 'VN'; // default
      try {
        String locale = Platform.localeName;
        List<String> parts = locale.split('_');
        if (parts.length > 1) {
          countryCode = parts[1];
        }
      } catch (e) {
        // ignore
      }

      Map<String, String>? clockData = defaultClocks[countryCode];
      if (clockData == null) {
        clockData = defaultClocks['VN']!;
      }

      _clocks = [
        WorldClockModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          city: clockData['city']!,
          timezone: clockData['timezone']!,
          country: clockData['country']!,
        ),
      ];
      await _saveClocks();
    }
    notifyListeners();
  }

  Future<void> _saveClocks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_clocks.map((clock) => clock.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  void addClock(WorldClockModel clock) {
    _clocks.add(clock);
    _saveClocks();
    notifyListeners();
  }

  void removeClock(String id) {
    _clocks.removeWhere((clock) => clock.id == id);
    _saveClocks();
    notifyListeners();
  }

  void reorderClocks(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final clock = _clocks.removeAt(oldIndex);
    _clocks.insert(newIndex, clock);
    _saveClocks();
    notifyListeners();
  }
}
