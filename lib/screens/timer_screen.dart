import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'sound_selector.dart';
import '../l10n/app_localizations.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  static const String _timerSoundKey = 'timer_sound';
  static const String _timerSoundDisplayNameKey = 'timer_sound_display_name';
  static const String _timerHoursKey = 'timer_hours';
  static const String _timerMinutesKey = 'timer_minutes';
  static const String _timerSecondsKey = 'timer_seconds';
  static const String _timerVibrateKey = 'timer_vibrate';
  int _hours = 0;
  int _minutes = 45;
  int _seconds = 0;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  String _selectedSound = 'assets/sounds/alarm.mp3';
  String _selectedSoundDisplayName = 'Alarm Phone 17 OS 26';
  bool _selectedVibrate = false;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _secondController;

  @override
  void initState() {
    super.initState();
    _hourController = FixedExtentScrollController();
    _minuteController = FixedExtentScrollController();
    _secondController = FixedExtentScrollController();
    _loadTimerSound();
    _loadTimerDuration().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hourController.hasClients) _hourController.jumpToItem(_hours);
        if (_minuteController.hasClients) _minuteController.jumpToItem(_minutes);
        if (_secondController.hasClients) _secondController.jumpToItem(_seconds);
      });
      
    });
    _loadTimerVibrate();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTimerDuration().then((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_hourController.hasClients) _hourController.jumpToItem(_hours);
          if (_minuteController.hasClients) _minuteController.jumpToItem(_minutes);
          if (_secondController.hasClients) _secondController.jumpToItem(_seconds);
        });
        
      });
    }
  }

  Future<void> _loadTimerDuration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _hours = prefs.getInt(_timerHoursKey) ?? 0;
        _minutes = prefs.getInt(_timerMinutesKey) ?? 45;
        _seconds = prefs.getInt(_timerSecondsKey) ?? 0;
      });
      print('Loaded timer duration: $_hours h, $_minutes m, $_seconds s');
    } catch (e) {
      print('Error loading timer duration: $e');
      // If loading fails, keep default value
    }
  }

  Future<void> _loadTimerSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSound = prefs.getString(_timerSoundKey);
      final savedSoundDisplayName = prefs.getString(_timerSoundDisplayNameKey);
      if (savedSound != null) {
        setState(() {
          _selectedSound = savedSound;
          _selectedSoundDisplayName = savedSoundDisplayName ?? _truncateSoundName(path.basename(savedSound));
        });
      } else {
        // Set default sound if none saved
        setState(() {
          _selectedSound = 'assets/sounds/alarm.mp3';
          _selectedSoundDisplayName = 'Alarm Phone 17 OS 26';
        });
      }
    } catch (e) {
      // If loading fails, keep default value
      setState(() {
        _selectedSound = 'assets/sounds/alarm.mp3';
        _selectedSoundDisplayName = 'Alarm Phone 17 OS 26';
      });
    }
  }

  Future<void> _saveTimerDuration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_timerHoursKey, _hours);
      await prefs.setInt(_timerMinutesKey, _minutes);
      await prefs.setInt(_timerSecondsKey, _seconds);
      print('Saved timer duration: $_hours h, $_minutes m, $_seconds s');
    } catch (e) {
      print('Error saving timer duration: $e');
      // If saving fails, ignore
    }
  }

  Future<void> _saveTimerSound(String sound) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_timerSoundKey, sound);
    } catch (e) {
      // If saving fails, ignore
    }
  }

  Future<void> _saveTimerSoundDisplayName(String displayName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_timerSoundDisplayNameKey, displayName);
    } catch (e) {
      // If saving fails, ignore
    }
  }

  Future<void> _loadTimerVibrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _selectedVibrate = prefs.getBool(_timerVibrateKey) ?? false;
      });
      print('Loaded timer vibrate: $_selectedVibrate');
    } catch (e) {
      print('Error loading timer vibrate: $e');
      // If loading fails, keep default value
    }
  }

  Future<void> _saveTimerVibrate(bool vibrate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_timerVibrateKey, vibrate);
      print('Saved timer vibrate: $vibrate');
    } catch (e) {
      print('Error saving timer vibrate: $e');
      // If saving fails, ignore
    }
  }

  Future<void> _startTimer() async {
    final totalSeconds = (_hours * 3600) + (_minutes * 60) + _seconds;
    if (totalSeconds == 0) return;

    await _saveTimerDuration();

    setState(() {
      _remainingSeconds = totalSeconds;
      _totalSeconds = totalSeconds;
      _isRunning = true;
      _isPaused = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _showTimerEndDialog();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  void _resumeTimer() {
    setState(() {
      _isPaused = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _showTimerEndDialog();
        }
      });
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = 0;
      _totalSeconds = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hourController.jumpToItem(_hours);
      _minuteController.jumpToItem(_minutes);
      _secondController.jumpToItem(_seconds);
    });
  }

  void _showTimerEndDialog() {
    // Start timer ring activity like alarm
    const platform = MethodChannel('com.oaptech.clock/alarm');
    platform.invokeMethod('startTimerRingActivity', {
      'remaining_seconds': 0,
      'selected_sound': _selectedSound,
      'selected_vibrate': _selectedVibrate,
    });
  }

  void _showSoundDialog() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      CupertinoPageRoute(
        builder: (context) => SoundSelector(currentSound: _selectedSound, currentVibrate: _selectedVibrate),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedSound = result['sound'];
        _selectedSoundDisplayName = result['soundDisplayName'];
        _selectedVibrate = result['vibrate'];
      });
      _saveTimerSound(_selectedSound);
      _saveTimerSoundDisplayName(_selectedSoundDisplayName);
      _saveTimerVibrate(_selectedVibrate);
    }
  }

  String _getSoundDisplayName() {
    return _selectedSoundDisplayName;
  }

  String _truncateSoundName(String soundName, {int maxLength = 25}) {
    if (soundName.length <= maxLength) {
      return soundName;
    }
    return '${soundName.substring(0, maxLength - 3)}...';
  }

  
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Text(
                AppLocalizations.of(context).timer,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            (_isRunning || _isPaused)
                ? _buildRunningTimer()
                : _buildTimerPicker(),
          ],
        ),
      ),
    );
  }

  String _getEndTime() {
    final now = DateTime.now();
    final endTime = now.add(Duration(seconds: _remainingSeconds));
    final is24h = Provider.of<SettingsProvider>(context, listen: false).is24HourFormat;
    final hour = endTime.hour;
    final minute = endTime.minute;
    
    if (is24h) {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } else {
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final period = hour >= 12 ? 'PM' : 'AM';
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }
  }

  String _getCountdownDisplay() {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;
    
    // If total time is less than 60 minutes, show only MM:SS
    if (_totalSeconds < 3600) {
      final totalMinutes = _remainingSeconds ~/ 60;
      return '${totalMinutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    
    // Otherwise show HH:MM:SS
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildRunningTimer() {
    final progress = _totalSeconds > 0 ? _remainingSeconds / _totalSeconds : 0.0;
    
    return Column(
      children: [
        const SizedBox(height: 60),
        // Circular progress timer - same size as picker
        SizedBox(
          height: 200,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _CircularProgressPainter(
                      progress: 1.0,
                      color: const Color(0xFF2C2C2E),
                      strokeWidth: 6,
                    ),
                  ),
                  // Progress circle
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _CircularProgressPainter(
                      progress: progress,
                      color: CupertinoColors.systemOrange,
                      strokeWidth: 6,
                    ),
                  ),
                  // Center content with time and end time
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Countdown time text
                      Text(
                        _getCountdownDisplay(),
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w200,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // End time with bell icon
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.bell_fill,
                            color: CupertinoColors.systemGrey,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getEndTime(),
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 60),
        // Control buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StopwatchStyleButton(
                onPressed: _cancelTimer,
                backgroundColor: const Color(0xFF2C2C2E),
                foregroundColor: CupertinoColors.white,
                label: AppLocalizations.of(context).cancel,
              ),
              _StopwatchStyleButton(
                onPressed: _isPaused ? _resumeTimer : _pauseTimer,
                backgroundColor: const Color(0xFF0A3A1F),
                foregroundColor: CupertinoColors.systemGreen,
                label: _isPaused ? AppLocalizations.of(context).resume : AppLocalizations.of(context).pause,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        // When Timer Ends section
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showSoundDialog,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                  fit: BoxFit.scaleDown, child: Text(
                    AppLocalizations.of(context).whenTimerEnds,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                    ),
                  )),
                ),
                Row(
                  children: [
                    SizedBox(width: 5,),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        _getSoundDisplayName(),
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.forward,
                      color: CupertinoColors.systemGrey.withOpacity(0.5),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTimerPicker() {
    return Column(
      children: [
        const SizedBox(height: 60),
        // Picker wheels - smaller
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Highlight bar for selected item
              Positioned.fill(
                child: Center(
                  child: Container(
                    height: 35,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              // Pickers
              Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hours
              SizedBox(
                width: 70,
                child: CupertinoPicker(
                  backgroundColor: CupertinoColors.transparent,
                  selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                    background: CupertinoColors.transparent,
                  ),
                  scrollController: _hourController,
                  itemExtent: 35,
                  diameterRatio: 1.2,
                  squeeze: 1.1,
                  onSelectedItemChanged: (index) {
                    setState(() => _hours = index);
                    _saveTimerDuration();
                  },
                  children: List.generate(
                    24,
                    (index) => Center(
                      child: Text(
                        index.toString(),
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  AppLocalizations.of(context).hoursLabel,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 15,
                  ),
                ),
              ),
              // Minutes
              SizedBox(
                width: 70,
                child: CupertinoPicker(
                  backgroundColor: CupertinoColors.transparent,
                  selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                    background: CupertinoColors.transparent,
                  ),
                  scrollController: _minuteController,
                  itemExtent: 35,
                  diameterRatio: 1.2,
                  squeeze: 1.1,
                  onSelectedItemChanged: (index) {
                    setState(() => _minutes = index);
                    _saveTimerDuration();
                  },
                  children: List.generate(
                    60,
                    (index) => Center(
                      child: Text(
                        index.toString(),
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  AppLocalizations.of(context).minLabel,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 15,
                  ),
                ),
              ),
              // Seconds
              SizedBox(
                width: 70,
                child: CupertinoPicker(
                  backgroundColor: CupertinoColors.transparent,
                  selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                    background: CupertinoColors.transparent,
                  ),
                  scrollController: _secondController,
                  itemExtent: 35,
                  diameterRatio: 1.2,
                  squeeze: 1.1,
                  onSelectedItemChanged: (index) {
                    setState(() => _seconds = index);
                    _saveTimerDuration();
                  },
                  children: List.generate(
                    60,
                    (index) => Center(
                      child: Text(
                        index.toString(),
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  AppLocalizations.of(context).secLabel,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
            ],
          ),
        ),
        const SizedBox(height: 60),
        // Control Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cancel Button - disabled when not running
              _StopwatchStyleButton(
                onPressed: null,
                backgroundColor: const Color(0xFF2C2C2E),
                foregroundColor: CupertinoColors.white,
                label: AppLocalizations.of(context).cancel,
              ),
              // Start Button
              _StopwatchStyleButton(
                onPressed: _startTimer,
                backgroundColor: const Color(0xFF0A3A1F),
                foregroundColor: CupertinoColors.systemGreen,
                label: AppLocalizations.of(context).start,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        // When Timer Ends section
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showSoundDialog,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: FittedBox(
                  fit: BoxFit.scaleDown, child: Text(
                    AppLocalizations.of(context).whenTimerEnds,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                    ),
                  )),
                ),
                Row(
                  children: [
                    SizedBox(width: 5,),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        _getSoundDisplayName(),
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.forward,
                      color: CupertinoColors.systemGrey.withOpacity(0.5),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _StopwatchStyleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String label;

  const _StopwatchStyleButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: backgroundColor,
            width: 2,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: onPressed == null
                        ? foregroundColor.withOpacity(0.3)
                        : foregroundColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

