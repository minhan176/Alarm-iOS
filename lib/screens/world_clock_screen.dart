import 'package:flutter/cupertino.dart';

class WorldClockScreen extends StatelessWidget {
  const WorldClockScreen({super.key});

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
            'Edit',
            style: TextStyle(color: CupertinoColors.systemOrange, fontSize: 17),
          ),
          onPressed: null,
        ),
        middle: Text(
          'World Clock',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.add,
            color: CupertinoColors.systemOrange,
            size: 28,
          ),
          onPressed: null,
        ),
      ),
      child: Center(
        child: Text(
          'World Clock',
          style: TextStyle(color: CupertinoColors.white, fontSize: 24),
        ),
      ),
    );
  }
}
