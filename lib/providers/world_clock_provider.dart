import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
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
      // Create default clocks: New York, Tokyo, and device timezone if available
      _clocks = await _createDefaultClocks();
      await _saveClocks();
    }
    notifyListeners();
  }

  Future<List<WorldClockModel>> _createDefaultClocks() async {
    List<WorldClockModel> defaultClocks = [];

    // Add device region clock first if available in the cities list
    try {
      final deviceRegion = _getDeviceRegion();
      final deviceCityData = _getCityDataByRegion(deviceRegion);
      
      // Skip if device region is JP (Tokyo) or US (New York) since they're already included
      if (deviceCityData != null && deviceRegion != 'JP' && deviceRegion != 'US') {
        defaultClocks.add(WorldClockModel(
          id: 'device_${DateTime.now().millisecondsSinceEpoch}',
          city: deviceCityData['city']!,
          timezone: deviceCityData['timezone']!,
          country: deviceCityData['country']!,
        ));
      }
    } catch (e) {
      // If region detection fails, don't add the third clock
    }

    // Always add New York
    defaultClocks.add(WorldClockModel(
      id: 'new_york_${DateTime.now().millisecondsSinceEpoch + 1}',
      city: 'New York',
      timezone: 'America/New_York',
      country: 'United States',
    ));

    // Always add Tokyo
    defaultClocks.add(WorldClockModel(
      id: 'tokyo_${DateTime.now().millisecondsSinceEpoch + 2}',
      city: 'Tokyo',
      timezone: 'Asia/Tokyo',
      country: 'Japan',
    ));

    return defaultClocks;
  }

  String _getDeviceRegion() {
    try {
      String locale = Platform.localeName;
      List<String> parts = locale.split('_');
      if (parts.length > 1) {
        return parts[1].toUpperCase();
      }
    } catch (e) {
      // ignore
    }
    return 'VN'; // default fallback
  }

  Map<String, String>? _getCityDataByRegion(String region) {
    // Map of region to city data from the available cities list
    final Map<String, Map<String, String>> regionToCity = {
      'NL': {'city': 'Amsterdam', 'timezone': 'Europe/Amsterdam', 'country': 'Netherlands'},
      'GR': {'city': 'Athens', 'timezone': 'Europe/Athens', 'country': 'Greece'},
      'NZ': {'city': 'Auckland', 'timezone': 'Pacific/Auckland', 'country': 'New Zealand'},
      'TH': {'city': 'Bangkok', 'timezone': 'Asia/Bangkok', 'country': 'Thailand'},
      'ES': {'city': 'Barcelona', 'timezone': 'Europe/Madrid', 'country': 'Spain'},
      'CN': {'city': 'Beijing', 'timezone': 'Asia/Shanghai', 'country': 'China'},
      'DE': {'city': 'Berlin', 'timezone': 'Europe/Berlin', 'country': 'Germany'},
      'CO': {'city': 'Bogotá', 'timezone': 'America/Bogota', 'country': 'Colombia'},
      'US': {'city': 'New York', 'timezone': 'America/New_York', 'country': 'United States'},
      'DK': {'city': 'Copenhagen', 'timezone': 'Europe/Copenhagen', 'country': 'Denmark'},
      'IN': {'city': 'Delhi', 'timezone': 'Asia/Kolkata', 'country': 'India'},
      'AE': {'city': 'Dubai', 'timezone': 'Asia/Dubai', 'country': 'United Arab Emirates'},
      'IE': {'city': 'Dublin', 'timezone': 'Europe/Dublin', 'country': 'Ireland'},
      'VN': {'city': 'Hanoi', 'timezone': 'Asia/Ho_Chi_Minh', 'country': 'Vietnam'},
      'HK': {'city': 'Hong Kong', 'timezone': 'Asia/Hong_Kong', 'country': 'Hong Kong'},
      'TR': {'city': 'Istanbul', 'timezone': 'Europe/Istanbul', 'country': 'Turkey'},
      'ID': {'city': 'Jakarta', 'timezone': 'Asia/Jakarta', 'country': 'Indonesia'},
      'ZA': {'city': 'Johannesburg', 'timezone': 'Africa/Johannesburg', 'country': 'South Africa'},
      'MY': {'city': 'Kuala Lumpur', 'timezone': 'Asia/Kuala_Lumpur', 'country': 'Malaysia'},
      'NG': {'city': 'Lagos', 'timezone': 'Africa/Lagos', 'country': 'Nigeria'},
      'PT': {'city': 'Lisbon', 'timezone': 'Europe/Lisbon', 'country': 'Portugal'},
      'GB': {'city': 'London', 'timezone': 'Europe/London', 'country': 'United Kingdom'},
      'PH': {'city': 'Manila', 'timezone': 'Asia/Manila', 'country': 'Philippines'},
      'AU': {'city': 'Melbourne', 'timezone': 'Australia/Melbourne', 'country': 'Australia'},
      'MX': {'city': 'Mexico City', 'timezone': 'America/Mexico_City', 'country': 'Mexico'},
      'IT': {'city': 'Milan', 'timezone': 'Europe/Rome', 'country': 'Italy'},
      'RU': {'city': 'Moscow', 'timezone': 'Europe/Moscow', 'country': 'Russia'},
      'NO': {'city': 'Oslo', 'timezone': 'Europe/Oslo', 'country': 'Norway'},
      'FR': {'city': 'Paris', 'timezone': 'Europe/Paris', 'country': 'France'},
      'CZ': {'city': 'Prague', 'timezone': 'Europe/Prague', 'country': 'Czech Republic'},
      'BR': {'city': 'Rio de Janeiro', 'timezone': 'America/Sao_Paulo', 'country': 'Brazil'},
      'KR': {'city': 'Seoul', 'timezone': 'Asia/Seoul', 'country': 'South Korea'},
      'SG': {'city': 'Singapore', 'timezone': 'Asia/Singapore', 'country': 'Singapore'},
      'SE': {'city': 'Stockholm', 'timezone': 'Europe/Stockholm', 'country': 'Sweden'},
      'TW': {'city': 'Taipei', 'timezone': 'Asia/Taipei', 'country': 'Taiwan'},
      'JP': {'city': 'Tokyo', 'timezone': 'Asia/Tokyo', 'country': 'Japan'},
      'CA': {'city': 'Toronto', 'timezone': 'America/Toronto', 'country': 'Canada'},
      'AT': {'city': 'Vienna', 'timezone': 'Europe/Vienna', 'country': 'Austria'},
      'PL': {'city': 'Warsaw', 'timezone': 'Europe/Warsaw', 'country': 'Poland'},
      'CH': {'city': 'Zurich', 'timezone': 'Europe/Zurich', 'country': 'Switzerland'},
    };

    return regionToCity[region];
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

  // Method to reset to default clocks (for testing purposes)
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await _loadClocks();
  }
}
