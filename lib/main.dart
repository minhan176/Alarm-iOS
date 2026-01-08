import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/alarm_provider.dart';
import 'screens/alarm_list_screen.dart';
import 'screens/world_clock_screen.dart';
import 'screens/stopwatch_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/alarm_ring_screen.dart';
import 'services/alarm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize alarm service
  await AlarmService.initialize();

  // Set up alarm callback
  AlarmService.onAlarmRing = (alarm) {
    // Navigate to alarm ring screen
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => AlarmRingScreen(alarm: alarm),
        fullscreenDialog: true,
      ),
    );
  };

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AlarmProvider(),
      child: CupertinoApp(
        navigatorKey: navigatorKey,
        title: 'Alarm',
        theme: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.systemOrange,
          scaffoldBackgroundColor: CupertinoColors.black,
          barBackgroundColor: Color(0xFF1C1C1E),
          textTheme: CupertinoTextThemeData(
            primaryColor: CupertinoColors.white,
          ),
        ),
        home: const MainTabScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 1; // Start with Alarm tab

  final List<Widget> _screens = const [
    WorldClockScreen(),
    AlarmListScreen(),
    StopwatchScreen(),
    TimerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: const Color(0xFF1C1C1E),
        activeColor: CupertinoColors.systemOrange,
        inactiveColor: CupertinoColors.systemGrey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.globe),
            label: 'World Clock',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.alarm),
            label: 'Alarm',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.stopwatch),
            label: 'Stopwatch',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.timer),
            label: 'Timer',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return _screens[index];
          },
        );
      },
    );
  }
}
