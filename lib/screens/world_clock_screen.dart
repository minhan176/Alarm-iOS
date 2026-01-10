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
        automaticallyImplyLeading: false,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            'Edit',
            style: TextStyle(color: CupertinoColors.systemOrange, fontSize: 17),
          ),
          onPressed: null,
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
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              child: Center(
                child: Text(
                  'World Clock',
                  style: TextStyle(color: CupertinoColors.white, fontSize: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
