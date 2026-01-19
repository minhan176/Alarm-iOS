import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'models/alarm_model.dart';
import 'providers/alarm_provider.dart';
import 'providers/world_clock_provider.dart';
import 'screens/alarm_list_screen.dart';
import 'screens/world_clock_screen.dart';
import 'screens/stopwatch_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/alarm_ring_screen.dart';
import 'screens/permission_setup_screen.dart';
import 'services/alarm_service.dart';
import 'widgets/liquid_glass_bottom_bar.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global variable to store pending alarm
AlarmModel? _pendingAlarm;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check for pending alarm from SharedPreferences (when app was killed)
  final prefs = await SharedPreferences.getInstance();
  final pendingAlarmJson = prefs.getString('pending_alarm');
  if (pendingAlarmJson != null) {
    try {
      final alarm = AlarmModel.fromJson(json.decode(pendingAlarmJson));
      _pendingAlarm = alarm;
      // Clear the pending alarm from storage
      await prefs.remove('pending_alarm');
    } catch (e) {
      print('Error parsing pending alarm: $e');
    }
  }

  // Initialize alarm service
  await AlarmService.initialize();

  // Set up alarm callback
  AlarmService.onAlarmRing = (alarm) {
    _pendingAlarm = alarm;
    // Try to navigate immediately if app is active
    if (navigatorKey.currentState != null) {
      _showAlarmScreen(alarm);
    }
    // The notification will also be shown and can be tapped
  };

  runApp(const MainApp());
}

void _showAlarmScreen(AlarmModel alarm) {
  navigatorKey.currentState?.push(
    CupertinoPageRoute(
      builder: (context) => AlarmRingScreen(alarm: alarm),
      fullscreenDialog: true,
    ),
  );
  _pendingAlarm = null;
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _permissionsSetupCompleted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissionsSetup();
  }

  Future<void> _checkPermissionsSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final setupCompleted = prefs.getBool('permissions_setup_completed') ?? false;

    setState(() {
      _permissionsSetupCompleted = setupCompleted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoApp(
        debugShowCheckedModeBanner: false,
        home: CupertinoPageScaffold(
          backgroundColor: CupertinoColors.black,
          child: Center(
            child: CupertinoActivityIndicator(),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AlarmProvider()),
        ChangeNotifierProvider(create: (context) => WorldClockProvider()),
      ],
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
        home: _permissionsSetupCompleted
            ? AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: CupertinoScaffold(
                  topRadius: const Radius.circular(12),
                  transitionBackgroundColor: CupertinoColors.black,
                  body: const MainTabScreen(),
                ),
              )
            : const PermissionSetupScreen(),
        routes: {
          '/home': (context) => AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: CupertinoScaffold(
                  topRadius: const Radius.circular(12),
                  transitionBackgroundColor: CupertinoColors.black,
                  body: const MainTabScreen(),
                ),
              ),
        },
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

class _MainTabScreenState extends State<MainTabScreen> with WidgetsBindingObserver {
  int _currentIndex = 1; // Start with Alarm tab

  final List<Widget> _screens = const [
    WorldClockScreen(),
    AlarmListScreen(),
    StopwatchScreen(),
    TimerScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check for pending alarm when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingAlarm();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _checkPendingAlarm();
    }
  }

  void _checkPendingAlarm() {
    if (_pendingAlarm != null) {
      _showAlarmScreen(_pendingAlarm!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Stack(
      children: [
        // Main content with SafeArea
        SafeArea(
          bottom: true,
          child: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ),
        // Liquid Glass Bottom Bar
        Align(
          alignment: Alignment.bottomCenter,
          child: LiquidGlassBottomBar(
            fake: true,
            barHeight: 64,
            bottomPadding: MediaQuery.of(context).padding.bottom + 16,
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
                glassColor: const Color(0xFF3C3C3E).withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      );
    }
}
