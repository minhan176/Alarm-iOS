import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

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

  @override
  void initState() {
    super.initState();
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
          await _audioPlayer.setVolume(1.0);

          Source audioSource;
          if (widget.selectedSound.startsWith('/') || widget.selectedSound.contains('\\')) {
            audioSource = DeviceFileSource(widget.selectedSound);
          } else {
            final soundFileName = widget.selectedSound.toLowerCase();
            final soundPath = 'sounds/$soundFileName.mp3';
            audioSource = AssetSource(soundPath);
          }

          await _audioPlayer.play(audioSource);
          print('Playing timer sound: ${widget.selectedSound}');
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
    await _audioPlayer.stop();
    await Vibration.cancel();
    _vibrateTimer?.cancel();
  }

  void _stopTimer() async {
    await _stopTimerRing();
    widget.onStop();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _stopTimerRing();
    _countdownTimer?.cancel();
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

            // Timer icon and label
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: math.sin(_shakeController.value * 2 * math.pi) * 0.1,
                      child: const Icon(
                        CupertinoIcons.timer,
                        color: CupertinoColors.systemGrey,
                        size: 32,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'Timer',
                  style: TextStyle(
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
              width: MediaQuery.of(context).size.width * 0.8, // Limit width to 80% of screen
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatTime(_currentRemainingSeconds),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 100,
                    fontWeight: FontWeight.w200,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const Spacer(),

            // Stop button - orange
            Padding(
              padding: const EdgeInsets.only(left: 35, right: 35, top: 40, bottom: 60),
              child: Container(
                width: double.infinity,
                height: 75,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  color: CupertinoColors.systemOrange,
                  borderRadius: BorderRadius.circular(32),
                  onPressed: _stopTimer,
                  child: const Text(
                    'Stop',
                    style: TextStyle(
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