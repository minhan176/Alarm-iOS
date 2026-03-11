import 'package:flutter/cupertino.dart';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  Timer? _timer;
  int _milliseconds = 0;
  bool _isRunning = false;
  List<int> _laps = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStop() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        setState(() {
          _milliseconds += 10;
        });
      });
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _lapReset() {
    if (_isRunning) {
      // Lap
      setState(() {
        _laps.insert(0, _milliseconds);
      });
    } else {
      // Reset
      setState(() {
        _milliseconds = 0;
        _laps.clear();
      });
    }
  }

  String _formatTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate() % 100;
    int seconds = (milliseconds / 1000).truncate() % 60;
    int minutes = (milliseconds / 60000).truncate() % 60;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${hundreds.toString().padLeft(2, '0')}';
  }

  String _formatLapDifference(int currentLap, int previousLap) {
    int diff = currentLap - previousLap;
    return _formatTime(diff);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: SafeArea(
        child: Column(
          children: [
            // AdMob Banner Ad
            const AdaptiveBannerAdWidget(),
            const SizedBox(height: 40),
            // Digital Timer Display
            Text(
              _formatTime(_milliseconds),
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 80,
                fontWeight: FontWeight.w200,
                fontFeatures: [
                  FontFeature.tabularFigures(),
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
                  // Lap/Reset Button
                  _CircularButton(
                    onPressed: _milliseconds > 0 ? _lapReset : null,
                    backgroundColor: const Color(0xFF2C2C2E),
                    foregroundColor: CupertinoColors.white,
                    label: _isRunning ? AppLocalizations.of(context).lap : AppLocalizations.of(context).reset,
                  ),
                  // Start/Stop Button
                  _CircularButton(
                    onPressed: _startStop,
                    backgroundColor: _isRunning
                        ? const Color(0xFF340C00)
                        : const Color(0xFF003B0D),
                    foregroundColor: _isRunning
                        ? const Color(0xFFFF453A)
                        : const Color(0xFF32D74B),
                    label: _isRunning ? AppLocalizations.of(context).stop : AppLocalizations.of(context).start,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Separator line
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 0.5,
              color: const Color(0xFF3C3C3E),
            ),
           // const SizedBox(height: 6),
            // Laps List
            if (_laps.isNotEmpty) ...[
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    itemCount: _laps.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _laps.length) {
                        // Add extra space at the bottom to avoid tab bar overlap
                        return const SizedBox(height: 100);
                      }
                      final lapTime = _laps[index];
                      final previousLapTime = index < _laps.length - 1
                          ? _laps[index + 1]
                          : 0;
                      final lapNumber = _laps.length - index;
                      
                      return Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFF3C3C3E),
                              width: 0.5,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context).lapNumber(lapNumber),
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 17,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _formatLapDifference(lapTime, previousLapTime),
                                  style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 17,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Text(
                                  _formatTime(lapTime),
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 17,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CircularButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final String label;

  const _CircularButton({
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
                fit: BoxFit.scaleDown, child: Text(
                              label,
                              style: TextStyle(
                                color: onPressed == null
              ? foregroundColor.withOpacity(0.3)
              : foregroundColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),),
            )
          ),
        ),
      ),
    );
  }
}
