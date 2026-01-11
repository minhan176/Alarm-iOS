import 'dart:convert';
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
      // Add default Hanoi timezone
      _clocks = [
        WorldClockModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          city: 'Hanoi',
          timezone: 'Asia/Ho_Chi_Minh',
          country: 'Vietnam',
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
