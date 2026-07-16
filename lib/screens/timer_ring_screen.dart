import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';

class TimerRingScreen extends StatefulWidget {
  final int remainingSeconds;
  final String selectedSound;
  final bool selectedVibrate;
  final VoidCallback onStop;

  const TimerRingScreen({
    super.key,
    required this.remainingSeconds,
    required this.selectedSound,
    required this.selectedVibrate,
    required this.onStop,
  });

  @override
  State<TimerRingScreen> createState() => _TimerRingScreenState();
}

class _TimerRingScreenState extends State<TimerRingScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _shakeController;
  late int _currentRemainingSeconds;
  Timer? _countdownTimer;
  Timer? _vibrateTimer;

  static const MethodChannel _alarmChannel = MethodChannel(
    'com.oaptech.clock/alarm',
  );

  @override
  void initState() {
    super.initState();
    AdService.incrementRingingScreens();
    _currentRemainingSeconds = widget.remainingSeconds;

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

    // Start playing timer sound and vibration
    _startTimerRing();

    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      print('Timer tick: $_currentRemainingSeconds');
      setState(() {
        _currentRemainingSeconds--;
      });
    });
  }

  Future<void> _startTimerRing() async {
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

      // Start vibration if enabled
      if (widget.selectedVibrate && await Vibration.hasVibrator()) {
        _startVibration();
      }

      // Play timer sound
      if (widget.selectedSound != 'None') {
        try {
          await _audioPlayer.setReleaseMode(ReleaseMode.loop);
          await _audioPlayer.setVolume(2.0);

          Source audioSource;
          if (widget.selectedSound.startsWith('content://')) {
            // It's a system ringtone URI - use native RingtoneManager
            await _alarmChannel.invokeMethod('playSystemRingtone', {
              'uri': widget.selectedSound,
            });
            print('Playing system ringtone: ${widget.selectedSound}');
          } else if (widget.selectedSound.startsWith('assets/')) {
            // It's an asset file (like our custom Alarm Phone 17 OS 26)
            final assetPath = widget.selectedSound.replaceFirst('assets/', '');
            audioSource = AssetSource(assetPath);
            await _audioPlayer.play(audioSource);
            print('Playing asset sound: ${widget.selectedSound}');
          } else if (widget.selectedSound.startsWith('/') ||
              widget.selectedSound.contains('\\')) {
            audioSource = DeviceFileSource(widget.selectedSound);
            await _audioPlayer.play(audioSource);
            print('Playing file sound: ${widget.selectedSound}');
          } else {
            // It's a built-in sound
            final soundFileName = widget.selectedSound.toLowerCase();
            final soundPath = 'sounds/$soundFileName.mp3';
            audioSource = AssetSource(soundPath);
            await _audioPlayer.play(audioSource);
            print('Playing built-in sound: ${widget.selectedSound}');
          }
        } catch (e) {
          print('Could not play timer sound "${widget.selectedSound}": $e');
        }
      } else {
        print('No sound selected for timer');
      }
    } catch (e) {
      print('Error starting timer ring: $e');
    }
  }

  void _startVibration() {
    Vibration.vibrate(duration: 500);
    _vibrateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      Vibration.vibrate(duration: 500);
    });
  }

  Future<void> _stopTimerRing() async {
    print('Stopping timer ring sound');
    await _audioPlayer.stop();
    await Vibration.cancel();
    _vibrateTimer?.cancel();
  }

  void _stopTimer() async {
    await _stopTimerRing();
    // Stop native sound if playing
    try {
      await _alarmChannel.invokeMethod('stopSystemRingtone');
    } catch (e) {
      print('Error stopping native sound: $e');
    }
    widget.onStop();
    if (mounted) {
      SystemNavigator.pop(); // Finish the activity
    }
  }

  void _repeatTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final hours = prefs.getInt('timer_hours') ?? 0;
    final minutes = prefs.getInt('timer_minutes') ?? 45;
    final seconds = prefs.getInt('timer_seconds') ?? 0;
    final totalSeconds = (hours * 3600) + (minutes * 60) + seconds;

    await _stopTimerRing();
    try {
      await _alarmChannel.invokeMethod('stopSystemRingtone');
    } catch (e) {
      print('Error stopping native sound: $e');
    }

    setState(() {
      _currentRemainingSeconds = totalSeconds;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_currentRemainingSeconds > 0) {
          _currentRemainingSeconds--;
        } else {
          _countdownTimer?.cancel();
          _showTimerEndDialog();
        }
      });
    });
  }

  void _showTimerEndDialog() {
    _alarmChannel.invokeMethod('startTimerRingActivity', {
      'remaining_seconds': 0,
      'selected_sound': widget.selectedSound,
      'selected_vibrate': widget.selectedVibrate,
    });
    SystemNavigator.pop();
  }

  @override
  void dispose() {
    _stopTimerRing();
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _shakeController.dispose();
    AdService.decrementRingingScreens();
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

            // Timer icon and label
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle:
                          math.sin(_shakeController.value * 2 * math.pi) * 0.1,
                      child: const Icon(
                        CupertinoIcons.timer,
                        color: CupertinoColors.systemGrey,
                        size: 32,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).timer,
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Countdown timer display
            SizedBox(
              width:
                  MediaQuery.of(context).size.width *
                  0.8, // Limit width to 80% of screen
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatTime(_currentRemainingSeconds),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 100,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const Spacer(),

            // Repeat button - translucent
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: SizedBox(
                width: double.infinity,
                height: 75,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  color: CupertinoColors.darkBackgroundGray.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(32),
                  onPressed: _repeatTimer,
                  child: Text(
                    AppLocalizations.of(context).repeat,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Stop button - orange
            Padding(
              padding: const EdgeInsets.only(left: 35, right: 35, bottom: 60),
              child: SizedBox(
                width: double.infinity,
                height: 75,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  color: CupertinoColors.systemOrange,
                  borderRadius: BorderRadius.circular(32),
                  onPressed: _stopTimer,
                  child: Text(
                    AppLocalizations.of(context).stop,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final isNegative = totalSeconds < 0;
    final absSeconds = totalSeconds.abs();
    final hours = absSeconds ~/ 3600;
    final minutes = (absSeconds % 3600) ~/ 60;
    final seconds = absSeconds % 60;
    final sign = isNegative ? '-' : '';
    if (hours > 0) {
      return '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$sign${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
