import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../providers/alarm_provider.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmModel alarm;

  const AlarmRingScreen({super.key, required this.alarm});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Start playing alarm sound and vibration
    _startAlarm();
  }

  Future<void> _startAlarm() async {
    try {
      // Start vibration pattern only if enabled
      if (widget.alarm.vibrate && await Vibration.hasVibrator()) {
        // Vibrate in pattern: wait 500ms, vibrate 1000ms, repeat
        Vibration.vibrate(
          pattern: [500, 1000, 500, 1000],
          repeat: 0, // Repeat from index 0
        );
        print('Vibration enabled for alarm');
      } else {
        print('Vibration disabled for alarm');
      }

      // Play alarm sound based on user selection
      try {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.setVolume(1.0);

        // Convert sound name to lowercase for file name
        final soundFileName = widget.alarm.sound.toLowerCase();
        final soundPath = 'sounds/$soundFileName.mp3';

        await _audioPlayer.play(AssetSource(soundPath));
        print('Playing alarm sound: ${widget.alarm.sound}');
      } catch (e) {
        print('Could not play alarm sound "${widget.alarm.sound}": $e');
        print(
          'Make sure the file assets/sounds/${widget.alarm.sound.toLowerCase()}.mp3 exists',
        );
      }
    } catch (e) {
      print('Error starting alarm: $e');
    }
  }

  Future<void> _stopAlarm() async {
    await _audioPlayer.stop();
    await Vibration.cancel();
  }

  void _dismissAlarm() async {
    await _stopAlarm();

    // Cancel the notification and handle one-time alarms
    await AlarmService.dismissAlarm(widget.alarm);

    // Reload alarms to update UI
    if (mounted) {
      Provider.of<AlarmProvider>(context, listen: false).loadAlarms();
      Navigator.of(context).pop();
    }
  }

  void _snoozeAlarm() async {
    await _stopAlarm();

    // Schedule snooze (5 minutes)
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));
    final snoozeAlarm = widget.alarm.copyWith(time: snoozeTime);

    await AlarmService.scheduleAlarm(snoozeAlarm);

    if (mounted) {
      Navigator.of(context).pop();

      // Show snooze confirmation
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Snoozed'),
          content: const Text('Alarm will ring again in 5 minutes'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopAlarm();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: CupertinoColors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.alarm.getFormattedTime(),
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 17,
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.bell_fill,
                      color: CupertinoColors.systemOrange,
                      size: 24,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Animated alarm icon
              Center(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.3),
                      child: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 0.5,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemOrange.withOpacity(
                                  0.2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.alarm,
                                size: 120,
                                color: CupertinoColors.systemOrange,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Alarm label
              Text(
                widget.alarm.label.isEmpty ? 'Alarm' : widget.alarm.label,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // Current time
              Text(
                _getCurrentTime(),
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 17,
                ),
              ),

              const Spacer(),

              // Action buttons
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Row(
                  children: [
                    // Snooze button
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        color: CupertinoColors.systemGrey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        onPressed: _snoozeAlarm,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.alarm_fill,
                              size: 32,
                              color: CupertinoColors.white,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Snooze',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Dismiss button
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        color: CupertinoColors.systemOrange,
                        borderRadius: BorderRadius.circular(16),
                        onPressed: _dismissAlarm,
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.check_mark_circled_solid,
                              size: 32,
                              color: CupertinoColors.white,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Dismiss',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour == 0
        ? 12
        : now.hour > 12
        ? now.hour - 12
        : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
