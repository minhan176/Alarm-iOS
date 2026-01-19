import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionSetupScreen extends StatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen> {
  int _currentStep = 0;
  bool _notificationsGranted = false;
  bool _exactAlarmsGranted = false;
  bool _batteryOptimizationDisabled = false;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Thông báo',
      'description': 'Cho phép app gửi thông báo báo thức',
      'icon': CupertinoIcons.bell_fill,
      'permission': Permission.notification,
    },
    {
      'title': 'Báo thức chính xác',
      'description': 'Cho phép app đặt báo thức vào thời điểm chính xác',
      'icon': CupertinoIcons.alarm_fill,
      'permission': Permission.scheduleExactAlarm,
    },
    {
      'title': 'Tối ưu hóa pin',
      'description': 'Tắt tối ưu hóa pin để app hoạt động ổn định',
      'icon': CupertinoIcons.battery_100,
      'isBatteryOptimization': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final setupCompleted = prefs.getBool('permissions_setup_completed') ?? false;

    if (setupCompleted) {
      // Skip setup if already completed
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
      return;
    }

    // Check current permission status
    final notificationStatus = await Permission.notification.status;
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;

    setState(() {
      _notificationsGranted = notificationStatus.isGranted;
      _exactAlarmsGranted = exactAlarmStatus.isGranted;
    });
  }

  Future<void> _requestPermission(int stepIndex) async {
    final step = _steps[stepIndex];

    if (step['isBatteryOptimization'] == true) {
      // Handle battery optimization separately
      final result = await _requestIgnoreBatteryOptimization();
      setState(() {
        _batteryOptimizationDisabled = result;
      });
    } else {
      final permission = step['permission'] as Permission;
      final status = await permission.request();

      setState(() {
        if (permission == Permission.notification) {
          _notificationsGranted = status.isGranted;
        } else if (permission == Permission.scheduleExactAlarm) {
          _exactAlarmsGranted = status.isGranted;
        }
      });
    }

    // Move to next step or complete
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      await _completeSetup();
    }
  }

  Future<bool> _requestIgnoreBatteryOptimization() async {
    // This requires a platform channel call to Android
    // For now, we'll show instructions to user
    return await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Tắt tối ưu hóa pin'),
        content: const Text(
          'Để báo thức hoạt động ổn định, vui lòng:\n\n'
          '1. Chọn "Tất cả ứng dụng"\n'
          '2. Tìm "alarm"\n'
          '3. Chọn "Không tối ưu hóa"\n'
          '4. Chọn "Cho phép"'
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Mở cài đặt'),
            onPressed: () async {
              Navigator.of(context).pop(true);
              await openAppSettings();
            },
          ),
          CupertinoDialogAction(
            child: const Text('Đã hoàn thành'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _completeSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_setup_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _skipSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_setup_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentStep];

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              const SizedBox(height: 40),
              Icon(
                currentStep['icon'] as IconData,
                size: 80,
                color: CupertinoColors.systemOrange,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Thiết lập quyền',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Step indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= _currentStep
                          ? CupertinoColors.systemOrange
                          : CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Current step content
              Text(
                currentStep['title'] as String,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                currentStep['description'] as String,
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 17,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Permission status
              if (_currentStep == 0 && _notificationsGranted)
                _buildStatusIndicator('Đã cấp quyền', true)
              else if (_currentStep == 1 && _exactAlarmsGranted)
                _buildStatusIndicator('Đã cấp quyền', true)
              else if (_currentStep == 2 && _batteryOptimizationDisabled)
                _buildStatusIndicator('Đã tắt tối ưu hóa', true)
              else
                _buildStatusIndicator('Chưa cấp quyền', false),

              const Spacer(),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: CupertinoColors.systemGrey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _skipSetup,
                      child: const Text(
                        'Bỏ qua',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: CupertinoColors.systemOrange,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () => _requestPermission(_currentStep),
                      child: Text(
                        _currentStep == _steps.length - 1 ? 'Hoàn thành' : 'Tiếp theo',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String text, bool isGranted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isGranted
            ? CupertinoColors.systemGreen.withOpacity(0.2)
            : CupertinoColors.systemRed.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGranted ? CupertinoIcons.check_mark : CupertinoIcons.xmark,
            color: isGranted ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isGranted ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}