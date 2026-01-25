import 'package:flutter/material.dart';
import '../models/alarm_model.dart';

class AlarmToast {
  static void showAlarmToast(AlarmModel alarm, BuildContext context) {
    final nextAlarmTime = alarm.getNextAlarmTime();
    final now = DateTime.now();
    final difference = nextAlarmTime.difference(now);

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    String timeText;
    if (days > 0) {
      timeText = '$days ngày, $hours giờ, $minutes phút';
    } else if (hours > 0) {
      timeText = '$hours giờ, $minutes phút';
    } else {
      timeText = '$minutes phút';
    }

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 150, // Position from bottom - cao hơn BOTTOM toast thông thường
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(25), // More rounded
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Đổ chuông sau $timeText.',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}