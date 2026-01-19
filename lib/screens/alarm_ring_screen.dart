import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../providers/alarm_provider.dart';
import '../widgets/custom_buttons.dart';

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
      // Set audio context to use alarm stream instead of media stream
      final AudioContext audioContext = AudioContext(
        android: AudioContextAndroid(
          usageType: AndroidUsageType.alarm,
          audioFocus: AndroidAudioFocus.gainTransientExclusive,
          audioMode: AndroidAudioMode.normal,
          contentType: AndroidContentType.music,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
      );
      await _audioPlayer.setAudioContext(audioContext);

      // Start vibration pattern only if enabled
      if (widget.alarm.vibrate && await Vibration.hasVibrator()) {
        // Vibrate in pattern: wait 1000ms, vibrate 500ms, repeat (less intense)
        Vibration.vibrate(
          pattern: [1000, 500, 1000, 500],
          repeat: 0, // Repeat from index 0
        );
        print('Vibration enabled for alarm');
      } else {
        print('Vibration disabled for alarm');
      }

      // Play alarm sound based on user selection
      if (widget.alarm.sound != 'None') {
        try {
          await _audioPlayer.setReleaseMode(ReleaseMode.loop);
          await _audioPlayer.setVolume(1.0);

          Source audioSource;
          if (widget.alarm.sound.startsWith('/') || widget.alarm.sound.contains('\\')) {
            // It's a file path from device
            audioSource = DeviceFileSource(widget.alarm.sound);
          } else {
            // It's a built-in sound
            final soundFileName = widget.alarm.sound.toLowerCase();
            final soundPath = 'sounds/$soundFileName.mp3';
            audioSource = AssetSource(soundPath);
          }

          await _audioPlayer.play(audioSource);
          print('Playing alarm sound: ${widget.alarm.sound}');
        } catch (e) {
          print('Could not play alarm sound "${widget.alarm.sound}": $e');
          if (!widget.alarm.sound.startsWith('/') && !widget.alarm.sound.contains('\\')) {
            print(
              'Make sure the file assets/sounds/${widget.alarm.sound.toLowerCase()}.mp3 exists',
            );
          }
        }
      } else {
        print('No sound selected for alarm');
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
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.black,
        child: SafeArea(
          child: Stack(
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1C1C1E),
                      Color(0xFF000000),
                    ],
                  ),
                ),
              ),

              Column(
                children: [
                  // Header with time and date
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getCurrentTime(),
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              _getCurrentDate(),
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            CupertinoIcons.bell_fill,
                            color: CupertinoColors.systemOrange,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Alarm label
                  if (widget.alarm.label.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        widget.alarm.label,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Animated alarm icon
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_pulseController.value * 0.2),
                          child: AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationController.value * 0.3,
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        CupertinoColors.systemOrange.withOpacity(0.3),
                                        CupertinoColors.systemOrange.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.alarm_fill,
                                    color: CupertinoColors.systemOrange,
                                    size: 80,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: Row(
                      children: [
                        // Snooze button
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            color: CupertinoColors.systemGrey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            onPressed: _snoozeAlarm,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.alarm,
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
                            borderRadius: BorderRadius.circular(20),
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
    return '$hour:$minute';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}
