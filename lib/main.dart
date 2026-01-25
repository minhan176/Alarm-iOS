import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
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
import 'services/alarm_service.dart';
import 'widgets/liquid_glass_bottom_bar.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global variable to store pending alarm
AlarmModel? _pendingAlarm;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  bool _overlayGranted = false;
  bool _dialogShown = false;
  bool _shouldDismissDialog = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkOverlayPermission();
    
    // Set up method channel to listen for navigation calls from Android
    const platform = MethodChannel('com.example.alarm/navigation');
    platform.setMethodCallHandler((call) async {
      print('DEBUG: Flutter received method call: ${call.method}');
      switch (call.method) {
        case 'navigateToRingScreen':
          final alarmJson = call.arguments as String?;
          print('DEBUG: navigateToRingScreen called with: $alarmJson');
          if (alarmJson != null) {
            try {
              final alarm = AlarmModel.fromJson(json.decode(alarmJson));
              print('DEBUG: Parsed alarm: ${alarm.label}');
              _showAlarmScreen(alarm);
            } catch (e) {
              print('Error parsing alarm from Android: $e');
            }
          }
          break;
        default:
          throw PlatformException(
            code: 'Unimplemented',
            details: 'Method ${call.method} not implemented',
          );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _dialogShown) {
      _checkPermissionAgain();
    }
  }

  Future<void> _checkOverlayPermission() async {
    final status = await Permission.systemAlertWindow.status;
    setState(() {
      _overlayGranted = status.isGranted;
      _permissionChecked = true;
    });
  }

  Future<void> _saveOverlayDialogState(bool shown) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('overlay_dialog_shown', shown);
  }

  Future<void> _checkPermissionAgain() async {
    final status = await Permission.systemAlertWindow.status;
    setState(() {
      _overlayGranted = status.isGranted;
      _permissionChecked = true;
      if (status.isGranted) {
        _shouldDismissDialog = true;
      }
    });
  }

  void _showOverlayDialog(BuildContext context) {
    _dialogShown = true;
    showCupertinoDialog(
      context: navigatorKey.currentContext ?? context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Cho phép "Hiển thị trên các ứng dụng khác"'),
        content: Text('Chúng tôi khuyến khích bạn cấp quyền này để giảm nguy cơ báo thức không hoạt động.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () async {
              const AndroidIntent intent = AndroidIntent(
                action: 'android.settings.action.MANAGE_OVERLAY_PERMISSION',
                data: 'package:com.example.alarm',
              );
              await intent.launch();
            },
            child: Text('Settings'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionChecked && !_overlayGranted && !_dialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOverlayDialog(context);
      });
    }
    if (_shouldDismissDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(navigatorKey.currentContext ?? context).pop();
        setState(() {
          _dialogShown = false;
          _shouldDismissDialog = false;
        });
      });
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
        home: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: CupertinoScaffold(
            topRadius: const Radius.circular(12),
            transitionBackgroundColor: CupertinoColors.black,
            body: const MainTabScreen(),
          ),
        ),
        routes: {
          '/home': (context) => AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: CupertinoScaffold(
                  topRadius: const Radius.circular(12),
                  transitionBackgroundColor: CupertinoColors.black,
                  body: const MainTabScreen(),
                ),
              ),
          '/alarm_ring': (context) => const AlarmRingScreenWidget(),
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
            barHeight: 57,
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
                glassColor: const Color(0xFF3C3C3E).withValues(alpha: 1),
              ),
            ),
          ),
        ],
      );
    }
}

// Widget for alarm ring screen that loads data from method channel
class AlarmRingScreenWidget extends StatefulWidget {
  const AlarmRingScreenWidget({super.key});

  @override
  State<AlarmRingScreenWidget> createState() => _AlarmRingScreenWidgetState();
}

class _AlarmRingScreenWidgetState extends State<AlarmRingScreenWidget> {
  AlarmModel? _alarm;
  bool _isLoading = true;

  static const platform = MethodChannel('com.example.alarm/ring');

  @override
  void initState() {
    super.initState();
    _loadAlarmData();
  }

  Future<void> _loadAlarmData() async {
    try {
      print('DEBUG: AlarmRingScreenWidget loading alarm data');
      final String? alarmJson = await platform.invokeMethod('getAlarmData');
      if (alarmJson != null) {
        print('DEBUG: Received alarm JSON: $alarmJson');
        final alarm = AlarmModel.fromJson(json.decode(alarmJson));
        print('DEBUG: Parsed alarm: ${alarm.label}');
        setState(() {
          _alarm = alarm;
          _isLoading = false;
        });
      } else {
        print('DEBUG: No alarm data received');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error loading alarm data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _dismissAlarm() async {
    try {
      await platform.invokeMethod('dismissAlarm');
    } catch (e) {
      print('DEBUG: Error dismissing alarm: $e');
    }
  }

  void _snoozeAlarm() async {
    try {
      await platform.invokeMethod('snoozeAlarm');
    } catch (e) {
      print('DEBUG: Error snoozing alarm: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const CupertinoPageScaffold(
        backgroundColor: CupertinoColors.black,
        child: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    if (_alarm == null) {
      return const CupertinoPageScaffold(
        backgroundColor: CupertinoColors.black,
        child: Center(
          child: Text(
            'No Alarm Data',
            style: TextStyle(color: CupertinoColors.white),
          ),
        ),
      );
    }

    return AlarmRingScreen(
      alarm: _alarm!,
      onDismiss: _dismissAlarm,
      onSnooze: _snoozeAlarm,
    );
  }
}
