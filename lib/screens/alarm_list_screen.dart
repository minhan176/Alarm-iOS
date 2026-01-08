import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm_model.dart';
import '../providers/alarm_provider.dart';
import 'edit_alarm_screen.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text(
            _isEditMode ? 'Done' : 'Edit',
            style: const TextStyle(
              color: CupertinoColors.systemOrange,
              fontSize: 17,
            ),
          ),
          onPressed: () {
            setState(() {
              _isEditMode = !_isEditMode;
            });
          },
        ),
        middle: const Text(
          'Alarm',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.add,
            color: CupertinoColors.systemOrange,
            size: 28,
          ),
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(builder: (context) => const EditAlarmScreen()),
            );
          },
        ),
      ),
      child: SafeArea(
        child: Consumer<AlarmProvider>(
          builder: (context, alarmProvider, child) {
            if (alarmProvider.alarms.isEmpty) {
              return const Center(
                child: Text(
                  'No alarms',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 17,
                  ),
                ),
              );
            }

            return ListView.builder(
              itemCount: alarmProvider.alarms.length,
              itemBuilder: (context, index) {
                final alarm = alarmProvider.alarms[index];
                return AlarmListItem(
                  alarm: alarm,
                  isEditMode: _isEditMode,
                  onTap: () {
                    if (!_isEditMode) {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => EditAlarmScreen(alarm: alarm),
                        ),
                      );
                    }
                  },
                  onToggle: () {
                    alarmProvider.toggleAlarm(alarm.id);
                  },
                  onDelete: () {
                    alarmProvider.deleteAlarm(alarm.id);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AlarmListItem extends StatelessWidget {
  final AlarmModel alarm;
  final bool isEditMode;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const AlarmListItem({
    super.key,
    required this.alarm,
    required this.isEditMode,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final repeatDescription = alarm.getRepeatDescription();
    final hasLabel = alarm.label.isNotEmpty && alarm.label != 'Alarm';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF3C3C3E), width: 0.5),
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // Delete button in edit mode
              if (isEditMode) ...[
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: const Text('Delete Alarm'),
                        content: const Text('Are you sure you want to delete this alarm?'),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('Cancel'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: const Text('Delete'),
                            onPressed: () {
                              Navigator.of(context).pop();
                              onDelete();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.systemRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.minus,
                      color: CupertinoColors.white,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          alarm.getFormattedTime(),
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
                    const SizedBox(height: 8),
                    if (hasLabel) ...[
                      Text(
                        alarm.label,
                        style: TextStyle(
                          color: alarm.isEnabled
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey2,
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (repeatDescription.isNotEmpty)
                      Text(
                        repeatDescription,
                        style: TextStyle(
                          color: alarm.isEnabled
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey2,
                          fontSize: 15,
                        ),
                      ),
                  ],
                ),
              ),
              // Hide toggle in edit mode
              if (!isEditMode)
                Transform.scale(
                  scale: 0.8,
                  child: CupertinoSwitch(
                    value: alarm.isEnabled,
                    activeColor: CupertinoColors.systemGreen,
                    onChanged: (value) {
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
