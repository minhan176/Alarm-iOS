import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/alarm_model.dart';
import '../screens/alarm_ring_screen.dart';

// Entry point for AlarmRingActivity
void main() => runApp(const AlarmRingApp());

class AlarmRingApp extends StatefulWidget {
  const AlarmRingApp({super.key});

  @override
  State<AlarmRingApp> createState() => _AlarmRingAppState();
}

class _AlarmRingAppState extends State<AlarmRingApp> {
  AlarmModel? _alarm;
  bool _isLoading = true;

  static const platform = MethodChannel('com.example.alarm/ring');

  @override
  void initState() {
    super.initState();
    _loadAlarmData();
  }

  Future<void> _loadAlarmData() async {
    try {
      print('DEBUG: Flutter AlarmRingApp loading alarm data');
      final String? alarmJson = await platform.invokeMethod('getAlarmData');
      if (alarmJson != null) {
        print('DEBUG: Received alarm JSON: $alarmJson');
        final alarm = AlarmModel.fromJson(json.decode(alarmJson));
        print('DEBUG: Parsed alarm: ${alarm.label}');
        setState(() {
          _alarm = alarm;
          _isLoading = false;
        });
      } else {
        print('DEBUG: No alarm data received');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error loading alarm data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _dismissAlarm() async {
    try {
      await platform.invokeMethod('dismissAlarm');
    } catch (e) {
      print('DEBUG: Error dismissing alarm: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoApp(
        debugShowCheckedModeBanner: false,
        home: CupertinoPageScaffold(
          backgroundColor: CupertinoColors.black,
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      );
    }

    if (_alarm == null) {
      return const CupertinoApp(
        debugShowCheckedModeBanner: false,
        home: CupertinoPageScaffold(
          backgroundColor: CupertinoColors.black,
          child: Center(
            child: Text(
              'No Alarm Data',
              style: TextStyle(color: CupertinoColors.white),
            ),
          ),
        ),
      );
    }

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemOrange,
        scaffoldBackgroundColor: CupertinoColors.black,
      ),
      home: AlarmRingScreen(
        alarm: _alarm!,
        onDismiss: _dismissAlarm,
      ),
    );
  }
}