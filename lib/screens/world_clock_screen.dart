import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/world_clock_provider.dart';
import '../models/world_clock_model.dart';
import '../widgets/custom_buttons.dart';
import 'add_city_screen.dart';

class WorldClockScreen extends StatefulWidget {
  const WorldClockScreen({super.key});

  @override
  State<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends State<WorldClockScreen> {
  bool _isEditMode = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update UI every second to show live time
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void _addCity() async {
    final result = await Navigator.of(context).push<WorldClockModel>(
      CupertinoPageRoute(
        builder: (context) => const AddCityScreen(),
      ),
    );
    
    if (result != null) {
      if (mounted) {
        Provider.of<WorldClockProvider>(context, listen: false).addClock(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom Navigation Bar
            CustomNavBar(
              backgroundColor: CupertinoColors.black,
              leading: NavTextButton(
                text: _isEditMode ? 'Done' : 'Edit',
                onPressed: _toggleEditMode,
              ),
              trailing: NavIconButton(
                icon: CupertinoIcons.add,
                onPressed: _addCity,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Text(
                'World Clock',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Consumer<WorldClockProvider>(
                builder: (context, provider, child) {
                  if (provider.clocks.isEmpty) {
                    return const Center(
                      child: Text(
                        'No World Clocks',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 17,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.clocks.length,
                    itemBuilder: (context, index) {
                      final clock = provider.clocks[index];
                      return _WorldClockItem(
                        clock: clock,
                        isEditMode: _isEditMode,
                        onDelete: () => provider.removeClock(clock.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldClockItem extends StatelessWidget {
  final WorldClockModel clock;
  final bool isEditMode;
  final VoidCallback onDelete;

  const _WorldClockItem({
    required this.clock,
    required this.isEditMode,
    required this.onDelete,
  });

  String _getTimeDifference() {
    final now = DateTime.now();
    final localTime = now;
    final clockTime = DateTime.now().toUtc().add(
      Duration(
        milliseconds: DateTime.now()
            .toUtc()
            .add(Duration(hours: _getTimezoneOffset(clock.timezone)))
            .millisecondsSinceEpoch - 
            DateTime.now().toUtc().millisecondsSinceEpoch,
      ),
    );
    
    final difference = clockTime.hour - localTime.hour;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference > 0) {
      return '+${difference}HRS';
    } else {
      return '${difference}HRS';
    }
  }

  int _getTimezoneOffset(String timezone) {
    // Simple timezone offset mapping for common cities
    final timezones = {
      'Asia/Ho_Chi_Minh': 7,
      'America/New_York': -5,
      'America/Los_Angeles': -8,
      'Europe/London': 0,
      'Europe/Paris': 1,
      'Asia/Tokyo': 9,
      'Asia/Shanghai': 8,
      'Asia/Dubai': 4,
      'Australia/Sydney': 11,
      'Pacific/Auckland': 13,
    };
    return timezones[timezone] ?? 0;
  }

  DateTime _getCurrentTimeInTimezone() {
    final offset = _getTimezoneOffset(clock.timezone);
    return DateTime.now().toUtc().add(Duration(hours: offset));
  }

  @override
  Widget build(BuildContext context) {
    final use24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;
    final currentTime = _getCurrentTimeInTimezone();
    
    final String hourText;
    final String? periodText;
    
    if (use24HourFormat) {
      hourText = '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
      periodText = null;
    } else {
      final hour = currentTime.hour % 12 == 0 ? 12 : currentTime.hour % 12;
      hourText = '$hour:${currentTime.minute.toString().padLeft(2, '0')}';
      periodText = currentTime.hour >= 12 ? 'PM' : 'AM';
    }
    
    final timeDiff = _getTimeDifference();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.darkBackgroundGray,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          if (isEditMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: CupertinoColors.systemRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.minus,
                    color: CupertinoColors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeDiff,
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  clock.city,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              text: hourText,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 48,
                fontWeight: FontWeight.w200,
                height: 1,
              ),
              children: periodText != null ? [
                TextSpan(
                  text: periodText,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ] : [],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalogClock extends StatelessWidget {
  final DateTime time;

  const _AnalogClock({required this.time});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(
        painter: _ClockPainter(time: time),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final DateTime time;

  _ClockPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Draw clock face
    final facePaint = Paint()
      ..color = const Color(0xFF2C2C2E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, facePaint);

    // Draw clock border
    final borderPaint = Paint()
      ..color = CupertinoColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 1, borderPaint);

    // Draw hour markers
    final markerPaint = Paint()
      ..color = CupertinoColors.white
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30 - 90) * math.pi / 180;
      final x = center.dx + (radius - 8) * math.cos(angle);
      final y = center.dy + (radius - 8) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 1.5, markerPaint);
    }

    // Draw hour hand
    final hourAngle = ((time.hour % 12 + time.minute / 60) * 30 - 90) * math.pi / 180;
    final hourPaint = Paint()
      ..color = CupertinoColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius * 0.4) * math.cos(hourAngle),
        center.dy + (radius * 0.4) * math.sin(hourAngle),
      ),
      hourPaint,
    );

    // Draw minute hand
    final minuteAngle = (time.minute * 6 - 90) * math.pi / 180;
    final minutePaint = Paint()
      ..color = CupertinoColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + (radius * 0.6) * math.cos(minuteAngle),
        center.dy + (radius * 0.6) * math.sin(minuteAngle),
      ),
      minutePaint,
    );

    // Draw center dot
    canvas.drawCircle(center, 3, markerPaint);
  }

  @override
  bool shouldRepaint(_ClockPainter oldDelegate) => true;
}
