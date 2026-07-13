import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/alarm_model.dart';
import '../l10n/app_localizations.dart';

class AlarmToast {
  static void showAlarmToast(AlarmModel? alarm, BuildContext context, {String? customMessage, double bottom = 150}) {
    String displayMessage;
    if (customMessage != null) {
      displayMessage = customMessage;
    } else {
      if (alarm == null) return;
      final nextAlarmTime = alarm.getNextAlarmTime();
      final now = DateTime.now();
      final difference = nextAlarmTime.difference(now);

      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final minutes = difference.inMinutes % 60;

      final l10n = AppLocalizations.of(context);
      String timeText;
      if (days > 0) {
        timeText = '${l10n.daysText(days)}, ${l10n.hoursText(hours)}, ${l10n.minutesText(minutes)}';
      } else if (hours > 0) {
        timeText = '${l10n.hoursText(hours)}, ${l10n.minutesText(minutes)}';
      } else if (minutes > 0) {
        timeText = l10n.minutesText(minutes);
      } else {
        timeText = l10n.oneMinute;
      }

      displayMessage = l10n.ringingIn(timeText);
    }

    Widget messageWidget;
    if (displayMessage.startsWith('Tip:')) {
      messageWidget = RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(
          children: [
            WidgetSpan(
              child: Icon(
                CupertinoIcons.lightbulb_fill,
                color: CupertinoColors.systemYellow,
                size: 16,
              ),
              alignment: PlaceholderAlignment.middle,
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: displayMessage,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else {
      messageWidget = Text(
        displayMessage,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      );
    }

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: bottom, // Position from bottom - adjustable for different contexts
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 350),
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
              child: messageWidget,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove after 5 seconds
    if (displayMessage.startsWith('Tip:')) {
      Future.delayed(const Duration(seconds: 5), () {
        overlayEntry.remove();
      });
    } else {
      Future.delayed(const Duration(seconds: 3), () {
        overlayEntry.remove();
      });
    }
  }
}