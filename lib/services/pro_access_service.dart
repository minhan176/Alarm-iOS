import 'package:shared_preferences/shared_preferences.dart';

class ProAccessService {
  static const String _proUnlockedKey = 'pro_unlocked';

  static Future<bool> isUnlocked() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_proUnlockedKey) ?? false;
  }

  static Future<void> setUnlocked(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proUnlockedKey, value);
  }
}