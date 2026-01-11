import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  int _hours = 0;
  int _minutes = 1;
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
        content: Text('Sound: $_selectedSound'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSoundDialog() {
    final sounds = [
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

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: const Color(0xFF1C1C1E),
        child: Column(
          children: [
            Container(
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF3C3C3E), width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Sound',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedSound = sounds[index];
                  });
                },
                scrollController: FixedExtentScrollController(
                  initialItem: sounds.indexOf(_selectedSound),
                ),
                children: sounds.map((sound) {
                  return Center(
                    child: Text(
                      sound,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 17,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
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
                  // Time text
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w200,
                      height: 1,
                    ),
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
                    Text(
                      _selectedSound,
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 17,
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
                      color: const Color(0xFF2C2C2E),
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
                    Text(
                      _selectedSound,
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 17,
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
