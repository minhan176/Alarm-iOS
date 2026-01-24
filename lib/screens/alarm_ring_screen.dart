import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../providers/alarm_provider.dart';
import '../widgets/custom_buttons.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmModel alarm;
  final VoidCallback? onDismiss;

  const AlarmRingScreen({super.key, required this.alarm, this.onDismiss});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _shakeController;

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

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

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

    // Call onDismiss callback if provided (for AlarmRingActivity)
    widget.onDismiss?.call();

    // Update alarm to disabled in provider immediately
    if (mounted) {
      final alarmProvider = Provider.of<AlarmProvider>(context, listen: false);
      final updatedAlarm = widget.alarm.copyWith(isEnabled: false);
      await alarmProvider.updateAlarm(widget.alarm.id, updatedAlarm);
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
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.black,
        child: Column(
          children: [
            const Spacer(),
        
            // Alarm icon and label above clock
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: math.sin(_shakeController.value * 2 * math.pi) * 0.1,
                      child: const Icon(
                        CupertinoIcons.alarm_fill,
                        color: CupertinoColors.systemGrey,
                        size: 32,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  widget.alarm.label.isNotEmpty ? widget.alarm.label : 'Alarm',
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
        
            const SizedBox(height: 40),
        
            // Large digital clock
            Text(
              _getCurrentTime(),
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 120,
                fontWeight: FontWeight.w200,
                height: 1,
              ),
            ),
        
            const Spacer(),
        
            // Action buttons - vertical stack
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 40),
              child: Column(
                children: [
                  // Snooze button - orange (only if snooze is enabled)
                  if (widget.alarm.snooze)
                    Container(
                      width: double.infinity,
                      height: 75,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        color: CupertinoColors.systemOrange,
                        borderRadius: BorderRadius.circular(32),
                        onPressed: _snoozeAlarm,
                        child: Text(
                          'Snooze',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
        
                  // Slide to stop button
                  Container(
                    width: double.infinity,
                    height: 75,
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: SlideToStopButton(onSlideComplete: _dismissAlarm),
                  ),
                ],
              ),
            ),
          ],
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

class SlideToStopButton extends StatefulWidget {
  final VoidCallback onSlideComplete;

  const SlideToStopButton({super.key, required this.onSlideComplete});

  @override
  State<SlideToStopButton> createState() => _SlideToStopButtonState();
}

class _SlideToStopButtonState extends State<SlideToStopButton>
    with TickerProviderStateMixin {
  double _dragPosition = 5.0;
  bool _isCompleted = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  LiquidGlassSettings _getGlassSettings(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    
    return LiquidGlassSettings(
      refractiveIndex: 1.21,
      thickness: 30,
      blur: 8,
      saturation: 1.5,
      lightIntensity: isDark ? .7 : 1,
      ambientStrength: isDark ? .2 : .5,
      lightAngle: math.pi / 4,
      glassColor: CupertinoTheme.of(context).barBackgroundColor.withValues(alpha: 0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final buttonSize = 60.0;
        final slideThreshold = containerWidth - buttonSize - 20; // Leave some margin

        return LiquidGlassLayer(
          fake: true,
          settings: _getGlassSettings(context),
          child: LiquidGlassBlendGroup(
            blend: 10,
            child: Stack(
              children: [
                // Background text
                Center(
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          final double shimmerWidth = bounds.width * 0.5; // Width of the shimmer effect
                          final double start = (bounds.width - shimmerWidth) * _shimmerController.value;
                          final double end = start + shimmerWidth;
                          
                          return LinearGradient(
                            colors: [
                              CupertinoColors.white.withOpacity(0.3),
                              CupertinoColors.white.withOpacity(0.9),
                              CupertinoColors.white.withOpacity(0.3),
                            ],
                            stops: [
                              (start / bounds.width).clamp(0.0, 1.0),
                              ((start + shimmerWidth / 2) / bounds.width).clamp(0.0, 1.0),
                              (end / bounds.width).clamp(0.0, 1.0),
                            ],
                          ).createShader(bounds);
                        },
                        child: Text(
                          'slide to stop',
                          style: TextStyle(
                            color: CupertinoColors.white.withOpacity(0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Sliding button
                Positioned(
                  left: _dragPosition,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      if (_isCompleted) return;

                      setState(() {
                        _dragPosition += details.delta.dx;
                        _dragPosition = _dragPosition.clamp(0.0, slideThreshold);
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      if (_isCompleted) return;

                      if (_dragPosition >= slideThreshold) {
                        // Completed slide
                        setState(() {
                          _isCompleted = true;
                        });
                        widget.onSlideComplete();
                      } else {
                        // Reset position
                        setState(() {
                          _dragPosition = 0.0;
                        });
                      }
                    },
                    child: LiquidStretch(
                      child: LiquidGlass.grouped(
                        shape: const LiquidRoundedSuperellipse(borderRadius: 9000),
                        child: GlassGlow(
                          child: Container(
                            width: buttonSize,
                            height: buttonSize,
                            decoration: BoxDecoration(
                              //color: CupertinoColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.stop_fill,
                              color: CupertinoColors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
