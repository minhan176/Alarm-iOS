import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';
import '../providers/alarm_provider.dart';
import '../widgets/custom_buttons.dart';
import 'edit_alarm_screen.dart';
import '../utils/alarm_toast.dart';
import 'settings_screen.dart';
import '../widgets/rating_dialog.dart';
import '../providers/settings_provider.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AlarmProvider>(context);
    if (provider.lastSavedAlarm != null) {
      final alarm = provider.lastSavedAlarm!;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Check if first alarm advice should be shown
        final prefs = await SharedPreferences.getInstance();
        final hasShownFirstAlarmToast = prefs.getBool('first_alarm_toast_shown') ?? false;
        if (!hasShownFirstAlarmToast) {
          AlarmToast.showAlarmToast(alarm, context, customMessage: 'Tip: Khuyến khích không nên tắt app trong đa nhiệm để đảm bảo báo thức hoạt động tốt hơn.');
          await prefs.setBool('first_alarm_toast_shown', true);
        } else {
          AlarmToast.showAlarmToast(alarm, context);
        }
        provider.clearLastSavedAlarm();
      });
    }
  }

  String? _getNextAlarmTimeText(List<AlarmModel> alarms) {
    final enabledAlarms = alarms.where((alarm) => alarm.isEnabled).toList();
    if (enabledAlarms.isEmpty) return null;

    // Find the earliest alarm
    AlarmModel? nextAlarm;
    DateTime? nextAlarmTime;

    for (final alarm in enabledAlarms) {
      final alarmTime = alarm.getNextAlarmTime();
      if (nextAlarmTime == null || alarmTime.isBefore(nextAlarmTime)) {
        nextAlarmTime = alarmTime;
        nextAlarm = alarm;
      }
    }

    if (nextAlarmTime == null) return null;

    final now = DateTime.now();
    final difference = nextAlarmTime.difference(now);

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    final parts = <String>[];
    
    if (days > 0) {
      // Show days, hours, minutes
      parts.add('$days ngày');
      if (hours > 0) parts.add('$hours giờ');
      if (minutes > 0) parts.add('$minutes phút');
    } else if (hours > 0) {
      // Show hours, minutes only
      parts.add('$hours giờ');
      if (minutes > 0) parts.add('$minutes phút');
    } else {
      // Show minutes only
      if (minutes > 0) {
        parts.add('$minutes phút');
      } else {
        parts.add('1 phút');
      }
    }

    return 'Còn lại ${parts.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Consumer<AlarmProvider>(
        builder: (context, alarmProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Navigation Bar
              CustomNavBar(
                backgroundColor: CupertinoColors.black,
                leading: NavTextButton(
                  text: _isEditMode ? 'Done' : 'Edit',
                  onPressed: () {
                    setState(() {
                      _isEditMode = !_isEditMode;
                    });
                  },
                ),
                trailing: NavIconButton(
                  icon: CupertinoIcons.add,
                  onPressed: () {
                     showCupertinoSheet<void>(
                      context: context,
                      useNestedNavigation: true,
                      builder: (BuildContext context) => const EditAlarmScreen(),
                );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'Alarms',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isEditMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                          child: const Icon(
                            CupertinoIcons.settings,
                          color: CupertinoColors.systemOrange,
                          size: 24,
                          ),
                        ),
                      )
                    else if (_getNextAlarmTimeText(alarmProvider.alarms) != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          _getNextAlarmTimeText(alarmProvider.alarms)!,
                          style: const TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: alarmProvider.alarms.isEmpty
                    ? const Center(
                        child: Text(
                          'No Alarm',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 24,
                          ),
                        ),
                      )
                    : ListView.builder(
            itemCount: alarmProvider.alarms.length + 1,
            itemBuilder: (context, index) {
              if (index == alarmProvider.alarms.length) {
                // Add extra space at the bottom to avoid tab bar overlap
                return const SizedBox(height: 100);
              }
              final alarm = alarmProvider.alarms[index];
              return AlarmListItem(
                alarm: alarm,
                isEditMode: _isEditMode,
                use24HourFormat: Provider.of<SettingsProvider>(context).is24HourFormat,
                onTap: () {
                  if (!_isEditMode) {
                    showCupertinoSheet<void>(
                      context: context,
                      useNestedNavigation: true,
                      builder: (BuildContext context) => EditAlarmScreen(alarm: alarm),
                    );
                  }
                },
                onToggle: () async {
                  await alarmProvider.toggleAlarm(alarm.id);
                  // Show toast when alarm is toggled
                  AlarmToast.showAlarmToast(alarm, context);
                },
                onDelete: () {
                  alarmProvider.deleteAlarm(alarm.id);
                },
              );
            },
          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AlarmListItem extends StatelessWidget {
  final AlarmModel alarm;
  final bool isEditMode;
  final bool use24HourFormat;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const AlarmListItem({
    super.key,
    required this.alarm,
    required this.isEditMode,
    required this.use24HourFormat,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final repeatDescription = alarm.getRepeatDescription();
    final hasLabel = alarm.label.isNotEmpty && alarm.label != 'Alarm';
    // final use24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;

    // Create combined label for repeat alarms
    final displayLabel = repeatDescription.isNotEmpty
        ? '${alarm.label}, $repeatDescription'
        : alarm.label;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF3C3C3E), width: 0.5),
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        pressedOpacity: 1.0,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              if (isEditMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: CupertinoColors.systemRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.minus,
                        color: CupertinoColors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          alarm.getFormattedTime(use24HourFormat: use24HourFormat),
                          style: TextStyle(
                            color: alarm.isEnabled
                                ? CupertinoColors.white
                                : CupertinoColors.systemGrey,
                            fontSize: 56,
                            fontWeight: FontWeight.w200,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    //const SizedBox(height: 0),
                    if (displayLabel.isNotEmpty) ...[
                      Text(
                        displayLabel,
                        style: TextStyle(
                          color: alarm.isEnabled
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey2,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      //const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
              // Toggle switch - disabled in edit mode
              Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: alarm.isEnabled,
                  activeColor: CupertinoColors.systemGreen,
                  onChanged: isEditMode ? null : (value) {
                    onToggle();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
