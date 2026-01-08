import 'dart:async';
import '../models/alarm_model.dart';

class AlarmRingService {
  static final AlarmRingService _instance = AlarmRingService._internal();
  factory AlarmRingService() => _instance;
  AlarmRingService._internal();

  final _alarmStreamController = StreamController<AlarmModel>.broadcast();
  Stream<AlarmModel> get alarmStream => _alarmStreamController.stream;

  void triggerAlarm(AlarmModel alarm) {
    _alarmStreamController.add(alarm);
  }

  void dispose() {
    _alarmStreamController.close();
  }
}
