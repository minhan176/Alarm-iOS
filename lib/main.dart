import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'models/alarm_model.dart';
import 'providers/alarm_provider.dart';
import 'providers/world_clock_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/alarm_list_screen.dart';
import 'screens/world_clock_screen.dart';
import 'screens/stopwatch_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/alarm_ring_screen.dart';
import 'screens/timer_ring_screen.dart';
import 'services/alarm_service.dart';
import 'services/battery_optimization_service.dart';
import 'widgets/liquid_glass_bottom_bar.dart';
import 'l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global variable to store pending alarm
AlarmModel? _pendingAlarm;

// Flag to skip permission check when opened from ring screen
bool _skipPermissionCheck = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());

  // Log graphics renderer information for debugging
  try {
    final renderer = WidgetsBinding.instance.platformDispatcher;
    print('Flutter renderer info: ${renderer.toString()}');
  } catch (e) {
    print('Could not get renderer info: $e');
  }

  // Set up global error handling for graphics issues
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('EGL') ||
        details.exception.toString().contains('OpenGL') ||
        details.exception.toString().contains('graphics') ||
        details.exception.toString().contains('render') ||
        details.exception.toString().contains('impeller') ||
        details.exception.toString().contains('Context::ClearCurrent')) {
      // Log graphics errors but don't crash the app
      print('Graphics/Impeller error caught: ${details.exception}');
      print('Stack trace: ${details.stack}');
      return;
    }
    FlutterError.presentError(details);
  };

  // Lock orientation to portrait only
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Get system time format
  final mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
  final system24HourFormat = mediaQuery.alwaysUse24HourFormat;

  // Check if app is opened from ring screen intent
  final initialRoute = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  _skipPermissionCheck = initialRoute == '/alarm_ring' || initialRoute == '/timer_ring';

  // Set up alarm callback
  AlarmService.onAlarmRing = (alarm) {
    _pendingAlarm = alarm;
    // Try to navigate immediately if app is active
    if (navigatorKey.currentState != null) {
      _showAlarmScreen(alarm);
    }
    // The notification will also be shown and can be tapped
  };

  runApp(MainApp(system24HourFormat: system24HourFormat));

  // Initialize services after the first Flutter frame can start rendering.
  unawaited(_initializeServices());
}

Future<void> _initializeServices() async {
  await AlarmService.initialize();
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
  final bool system24HourFormat;

  const MainApp({super.key, required this.system24HourFormat});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WidgetsBindingObserver {
  bool _overlayGranted = false;
  bool _dialogShown = false;
  bool _shouldDismissDialog = false;
  bool _permissionChecked = false;

  // Battery optimization variables
  bool _batteryDialogShown = false;
  bool _shouldDismissBatteryDialog = false;
  bool _batteryDialogDisplayedOnce = false;
  bool _skipBatteryAfterOverlayGrant = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Skip permission checks if app is opened from ring screen
    if (!_skipPermissionCheck) {
      _checkOverlayPermission();
      _loadBatteryDialogState();
    }
    
    // Set up method channel to listen for navigation calls from Android
    const platform = MethodChannel('com.oaptech.clock/navigation');
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
    if (state == AppLifecycleState.resumed) {
      // Update time format from system if user hasn't changed it
      final mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
      final currentSystem24HourFormat = mediaQuery.alwaysUse24HourFormat;
      Provider.of<SettingsProvider>(navigatorKey.currentContext!, listen: false)
          .updateFromSystem(currentSystem24HourFormat);
    }
  }

  Future<void> _checkOverlayPermission() async {
    final status = await Permission.systemAlertWindow.status;
    setState(() {
      _overlayGranted = status.isGranted;
      _permissionChecked = true;
    });
  }

  Future<void> _loadBatteryDialogState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _batteryDialogDisplayedOnce = prefs.getBool('battery_dialog_shown') ?? false;
    });
  }

  Future<void> _saveBatteryDialogState(bool shown) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('battery_dialog_shown', shown);
  }

  Future<void> _checkPermissionAgain() async {
    final status = await Permission.systemAlertWindow.status;
    final wasGranted = _overlayGranted;
    setState(() {
      _overlayGranted = status.isGranted;
      _permissionChecked = true;
      if (status.isGranted) {
        _shouldDismissDialog = true;
        if (!wasGranted) {
          _skipBatteryAfterOverlayGrant = true;
        }
      }
    });
  }

  void _showBatteryOptimizationDialog(BuildContext context) {
    print('DEBUG: Showing battery optimization dialog');
    _batteryDialogShown = true;
    _batteryDialogDisplayedOnce = true;
    _saveBatteryDialogState(true);
    showCupertinoDialog(
      context: navigatorKey.currentContext ?? context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context).allowBackgroundRunning),
        content: Text(AppLocalizations.of(context).batteryDialogContent),
        actions: [
          CupertinoDialogAction(
            onPressed: () async {
              await BatteryOptimizationService.openBatterySettings();
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context).openAppSettings),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  void _showOverlayDialog(BuildContext context) {
    _dialogShown = true;
    showCupertinoDialog(
      context: navigatorKey.currentContext ?? context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Text(AppLocalizations.of(context).allowDisplayOverOtherApps),
        content: Text(AppLocalizations.of(context).overlayDialogContent),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context).close),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              const AndroidIntent intent = AndroidIntent(
                action: 'android.settings.action.MANAGE_OVERLAY_PERMISSION',
                data: 'package:com.oaptech.clock',
              );
              await intent.launch();
            },
            child: Text(AppLocalizations.of(context).openSettings),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Skip permission dialogs if app is opened from ring screen
    if (!_skipPermissionCheck) {
      // Battery optimization dialog logic - only show after overlay is granted and only once
      if (_permissionChecked && _overlayGranted && !_batteryDialogDisplayedOnce && !_batteryDialogShown && !_skipBatteryAfterOverlayGrant) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showBatteryOptimizationDialog(context);
        });
      }
      if (_shouldDismissBatteryDialog) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(navigatorKey.currentContext ?? context).pop();
          setState(() {
            _batteryDialogShown = false;
            _shouldDismissBatteryDialog = false;
          });
        });
      }
      
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
    }

    

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AlarmProvider()),
        ChangeNotifierProvider(create: (context) => WorldClockProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider(initial24HourFormat: widget.system24HourFormat)),
      ],
      child: CupertinoApp(
        navigatorKey: navigatorKey,
        title: 'Alarm',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        ),
        theme: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: CupertinoColors.systemOrange,
          scaffoldBackgroundColor: CupertinoColors.black,
          barBackgroundColor: Color(0xFF1C1C1E),
          textTheme: CupertinoTextThemeData(
            primaryColor: CupertinoColors.white,
            textStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            navTitleTextStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            navLargeTitleTextStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
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
          '/timer_ring': (context) => const TimerRingScreenWidget(),
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
      // Update time format from system if user hasn't changed it
      final mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
      final currentSystem24HourFormat = mediaQuery.alwaysUse24HourFormat;
      Provider.of<SettingsProvider>(context, listen: false)
          .updateFromSystem(currentSystem24HourFormat);
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
            fake: false,
            barHeight: 57,
            bottomPadding: MediaQuery.of(context).padding.bottom + 16,
            tabs: [
                LiquidGlassBottomBarTab(
                  label: AppLocalizations.of(context).tabWorldClock,
                  icon: CupertinoIcons.globe,
                ),
                LiquidGlassBottomBarTab(
                  label: AppLocalizations.of(context).tabAlarm,
                  icon: CupertinoIcons.alarm,
                ),
                LiquidGlassBottomBarTab(
                  label: AppLocalizations.of(context).tabStopwatch,
                  icon: CupertinoIcons.stopwatch,
                ),
                LiquidGlassBottomBarTab(
                  label: AppLocalizations.of(context).tabTimer,
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

  static const platform = MethodChannel('com.oaptech.clock/ring');

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
      return CupertinoPageScaffold(
        backgroundColor: CupertinoColors.black,
        child: Center(
          child: Text(
            AppLocalizations.of(context).noAlarmData,
            style: const TextStyle(color: CupertinoColors.white),
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

class TimerRingScreenWidget extends StatefulWidget {
  const TimerRingScreenWidget({super.key});

  @override
  State<TimerRingScreenWidget> createState() => _TimerRingScreenWidgetState();
}

class _TimerRingScreenWidgetState extends State<TimerRingScreenWidget> {
  int _remainingSeconds = 0;
  String _selectedSound = 'Radar';
  bool _selectedVibrate = false;
  bool _isLoading = true;

  static const platform = MethodChannel('com.oaptech.clock/timer_ring');

  @override
  void initState() {
    super.initState();
    _loadTimerData();
  }

  Future<void> _loadTimerData() async {
    try {
      print('DEBUG: TimerRingScreenWidget loading timer data');
      final Map<dynamic, dynamic>? timerData = await platform.invokeMethod('getTimerData');
      if (timerData != null) {
        print('DEBUG: Received timer data: $timerData');
        final remainingSeconds = timerData['remainingSeconds'] as int? ?? 0;
        final selectedSound = timerData['selectedSound'] as String? ?? 'Radar';
        final selectedVibrate = timerData['selectedVibrate'] as bool? ?? false;
        print('DEBUG: Parsed timer: remainingSeconds=$remainingSeconds, sound=$selectedSound, vibrate=$selectedVibrate');
        setState(() {
          _remainingSeconds = remainingSeconds;
          _selectedSound = selectedSound;
          _selectedVibrate = selectedVibrate;
          _isLoading = false;
        });
      } else {
        print('DEBUG: No timer data received');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG: Error loading timer data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _stopTimer() async {
    try {
      await platform.invokeMethod('stopTimer');
    } catch (e) {
      print('DEBUG: Error stopping timer: $e');
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

    return TimerRingScreen(
      remainingSeconds: _remainingSeconds,
      selectedSound: _selectedSound,
      selectedVibrate: _selectedVibrate,
      onStop: _stopTimer,
    );
  }
}
