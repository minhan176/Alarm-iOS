import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'dart:math' as math;
import 'providers/alarm_provider.dart';
import 'screens/alarm_list_screen.dart';
import 'screens/world_clock_screen.dart';
import 'screens/stopwatch_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/alarm_ring_screen.dart';
import 'services/alarm_service.dart';
import 'widgets/liquid_glass_bottom_bar.dart';

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
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Stack(
      children: [
        // Main content
        IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        // Liquid Glass Bottom Bar
        SafeArea(
          bottom: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: LiquidGlassBottomBar(
              fake: true,
              tabs: const [
                LiquidGlassBottomBarTab(
                  label: 'World Clock',
                  icon: CupertinoIcons.globe,
                ),
                LiquidGlassBottomBarTab(
                  label: 'Alarm',
                  icon: CupertinoIcons.alarm,
                ),
                LiquidGlassBottomBarTab(
                  label: 'Stopwatch',
                  icon: CupertinoIcons.stopwatch,
                ),
                LiquidGlassBottomBarTab(
                  label: 'Timer',
                  icon: CupertinoIcons.timer,
                ),
              ],
              selectedIndex: _currentIndex,
              onTabSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              glassSettings: LiquidGlassSettings(
                refractiveIndex: 1.21,
                thickness: 30,
                blur: 8,
                saturation: 1.5,
                lightIntensity: isDark ? .7 : 1,
                ambientStrength: isDark ? .2 : .5,
                lightAngle: math.pi / 4,
                glassColor: const Color(0xFF1C1C1E).withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
