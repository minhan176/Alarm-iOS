import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_buttons.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  static const String _timerSoundKey = 'timer_sound';
  int _hours = 0;
  int _minutes = 45;
  int _seconds = 0;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  String _selectedSound = 'Radar';
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _loadTimerSound();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadTimerSound() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSound = prefs.getString(_timerSoundKey);
      if (savedSound != null) {
        setState(() {
          _selectedSound = savedSound;
        });
      }
    } catch (e) {
      // If loading fails, keep default value
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

  void _startTimer() {
    final totalSeconds = (_hours * 3600) + (_minutes * 60) + _seconds;
    if (totalSeconds == 0) return;

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
  }

  void _showTimerEndDialog() {
    // Play sound here - in a real app you would use audioplayers package
    // For now just show dialog
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Timer Ended'),
        content: Text('Sound: ${_getSoundDisplayName()}'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSoundDialog() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      CupertinoPageRoute(
        builder: (context) => SoundSelector(currentSound: _selectedSound, currentVibrate: false),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedSound = result['sound'];
      });
      _saveTimerSound(_selectedSound);
    }
  }

  String _getSoundDisplayName() {
    return _truncateSoundName(path.basename(_selectedSound));
  }

  String _truncateSoundName(String soundName, {int maxLength = 25}) {
    if (soundName.length <= maxLength) {
      return soundName;
    }
    return '${soundName.substring(0, maxLength - 3)}...';
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Text(
                'Timer',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: (_isRunning || _isPaused)
                  ? _buildRunningTimer()
                  : _buildTimerPicker(),
            ),
          ],
        ),
      ),
    );
  }

  String _getEndTime() {
    final now = DateTime.now();
    final endTime = now.add(Duration(seconds: _remainingSeconds));
    final hour = endTime.hour;
    final minute = endTime.minute;
    
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
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
                              fontSize: 17,
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
                label: 'Cancel',
              ),
              _StopwatchStyleButton(
                onPressed: _isPaused ? _resumeTimer : _pauseTimer,
                backgroundColor: const Color(0xFF0A3A1F),
                foregroundColor: CupertinoColors.systemGreen,
                label: _isPaused ? 'Resume' : 'Pause',
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
                const Text(
                  'When Timer Ends',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 17,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        _getSoundDisplayName(),
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 17,
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
                  scrollController: FixedExtentScrollController(
                    initialItem: _hours,
                  ),
                  itemExtent: 35,
                  diameterRatio: 1.2,
                  squeeze: 1.1,
                  onSelectedItemChanged: (index) {
                    setState(() => _hours = index);
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'hours',
                  style: TextStyle(
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
                  scrollController: FixedExtentScrollController(
                    initialItem: _minutes,
                  ),
                  itemExtent: 35,
                  diameterRatio: 1.2,
                  squeeze: 1.1,
                  onSelectedItemChanged: (index) {
                    setState(() => _minutes = index);
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'min',
                  style: TextStyle(
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
                  scrollController: FixedExtentScrollController(
                    initialItem: _seconds,
                  ),
                  itemExtent: 35,
                  diameterRatio: 1.2,
                  squeeze: 1.1,
                  onSelectedItemChanged: (index) {
                    setState(() => _seconds = index);
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'sec',
                  style: TextStyle(
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
                label: 'Cancel',
              ),
              // Start Button
              _StopwatchStyleButton(
                onPressed: _startTimer,
                backgroundColor: const Color(0xFF0A3A1F),
                foregroundColor: CupertinoColors.systemGreen,
                label: 'Start',
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
                const Text(
                  'When Timer Ends',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 17,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        _getSoundDisplayName(),
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 17,
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
        width: 85,
        height: 85,
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
            child: Text(
              label,
              style: TextStyle(
                color: onPressed == null
                    ? foregroundColor.withOpacity(0.3)
                    : foregroundColor,
                fontSize: 17,
                fontWeight: FontWeight.w400,
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

class SoundSelector extends StatefulWidget {
  final String currentSound;
  final bool currentVibrate;

  const SoundSelector({
    super.key,
    required this.currentSound,
    required this.currentVibrate,
  });

  @override
  State<SoundSelector> createState() => _SoundSelectorState();
}

class _SoundSelectorState extends State<SoundSelector> {
  late String _selectedSound;
  late bool _vibrate;

  final List<String> _sounds = [
    'None',
    'Radar',
    'Apex',
    'Beacon',
    'Bulletin',
    'By The Seaside',
    'Chimes',
    'Circuit',
    'Constellation',
    'Cosmic',
    'Crystals',
    'Hillside',
    'Illuminate',
    'Night Owl',
    'Opening',
    'Playtime',
    'Presto',
    'Radar (Classic)',
    'Reflection',
    'Ripples',
    'Sencha',
    'Signal',
    'Silk',
    'Slow Rise',
    'Stargaze',
    'Summit',
    'Twinkle',
    'Uplift',
    'Waves',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSound = widget.currentSound;
    _vibrate = widget.currentVibrate;
  }

  void _pickFromDevice() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg', 'aiff'],
    );
    if (result != null) {
      setState(() {
        _selectedSound = result.files.single.path!;
      });
    }
  }

  String _truncateSoundName(String soundName, {int maxLength = 25}) {
    if (soundName.length <= maxLength) {
      return soundName;
    }
    return '${soundName.substring(0, maxLength - 3)}...';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop({'sound': _selectedSound, 'vibrate': _vibrate});
        return false;
      },
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 5),
              CustomNavBar(
                backgroundColor: const Color(0xFF1C1C1E),
                leading: NavIconButton(
                  icon: CupertinoIcons.chevron_left,
                  iconColor: CupertinoColors.white,
                  onPressed: () => Navigator.of(context).pop({'sound': _selectedSound, 'vibrate': _vibrate}),
                ),
                middle: const Text(
                  'When Timer Ends',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Vibrate toggle
              Container(
                margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vibrate',
                        style: TextStyle(color: CupertinoColors.white, fontSize: 17),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: CupertinoSwitch(
                          value: _vibrate,
                          activeColor: CupertinoColors.systemGreen,
                          onChanged: (value) => setState(() => _vibrate = value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Section 2: Add from device
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                    child: Text(
                      'SONGS',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: 2, // Always show 2 items: custom song (if selected) and pick button
                      separatorBuilder: (context, index) => Divider(
                        color: const Color(0xFF3C3C3E),
                        height: 0.5,
                        indent: 48,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        // Index 0: Show selected custom song if exists, otherwise show pick button
                        if (index == 0 && !_sounds.contains(_selectedSound)) {
                          // Selected custom song
                          return CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            pressedOpacity: 1.0,
                            onPressed: () {},
                            child: SizedBox(
                              //height: 44,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Icon(
                                      CupertinoIcons.check_mark,
                                      color: CupertinoColors.systemOrange,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 200),
                                      child: Text(
                                        _truncateSoundName(path.basename(_selectedSound)),
                                        style: const TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 17,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (index == 0 || (index == 1 && !_sounds.contains(_selectedSound))) {
                          // Pick a song button
                          return CupertinoButton(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            pressedOpacity: 1.0,
                            onPressed: _pickFromDevice,
                            child: SizedBox(
                              //height: 44,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(width: 32),
                                  const Text(
                                    'Pick a song',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 17,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: CupertinoColors.systemGrey3,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink(); // Should not reach here
                      },
                    ),
                  ),
                ],
              ),
              // Section 3: List of sounds
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                      child: Text(
                        'RINGTONES',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListView.separated(
                            itemCount: _sounds.length,
                            separatorBuilder: (context, index) => Divider(
                              color: const Color(0xFF3C3C3E),
                              height: 0.5,
                              indent: index == 0 ? 0 : 48, // No indent for divider under 'None'
                              endIndent: index == 0 ? 0 : 16, // No endIndent for divider under 'None'
                            ),
                            itemBuilder: (context, index) {
                              final sound = _sounds[index];
                              final isSelected = _selectedSound == sound;
                              return CupertinoButton(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                pressedOpacity: 1.0,
                                onPressed: () {
                                  setState(() {
                                    _selectedSound = sound;
                                  });
                                },
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      child: isSelected
                                          ? const Icon(
                                              CupertinoIcons.check_mark,
                                              color: CupertinoColors.systemOrange,
                                              size: 18,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        constraints: const BoxConstraints(maxWidth: 200),
                                        child: Text(
                                          _truncateSoundName(sound),
                                          style: const TextStyle(
                                            color: CupertinoColors.white,
                                            fontSize: 17,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
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
}
