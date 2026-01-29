import 'package:flutter/services.dart';

class BatteryOptimizationService {
  static const MethodChannel _channel = MethodChannel('com.example.alarm/battery');

  /// Kiểm tra xem app có đang bỏ qua tối ưu hóa pin không
  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
    } catch (e) {
      print('Error checking battery optimization: $e');
      return false;
    }
  }

  /// Kiểm tra xem app có thể chạy dưới nền không
  static Future<bool> canRunInBackground() async {
    try {
      final result = await _channel.invokeMethod<bool>('canRunInBackground');
      return result ?? false;
    } catch (e) {
      print('Error checking background execution: $e');
      return false;
    }
  }

  /// Mở trang cài đặt tối ưu hóa pin
  static Future<String> openBatterySettings() async {
    try {
      final result = await _channel.invokeMethod<String>('openBatterySettings');
      return result ?? 'Unknown result';
    } catch (e) {
      print('Error opening battery settings: $e');
      return 'Error: $e';
    }
  }
}