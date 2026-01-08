import 'package:flutter/cupertino.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            'Cancel',
            style: TextStyle(color: CupertinoColors.systemOrange, fontSize: 17),
          ),
          onPressed: null,
        ),
        middle: Text(
          'Timer',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            'Start',
            style: TextStyle(color: CupertinoColors.systemOrange, fontSize: 17),
          ),
          onPressed: null,
        ),
      ),
      child: Center(
        child: Text(
          'Timer',
          style: TextStyle(color: CupertinoColors.white, fontSize: 24),
        ),
      ),
    );
  }
}
