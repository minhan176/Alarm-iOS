import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm_model.dart';
import '../providers/alarm_provider.dart';
import 'edit_alarm_screen.dart';

class AlarmListScreen extends StatelessWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text(
            'Edit',
            style: TextStyle(color: CupertinoColors.systemOrange, fontSize: 17),
          ),
          onPressed: () {
            // TODO: Implement edit mode
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
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => EditAlarmScreen(alarm: alarm),
                      ),
                    );
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
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const AlarmListItem({
    super.key,
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final repeatDescription = alarm.getRepeatDescription();
    final hasLabel = alarm.label.isNotEmpty && alarm.label != 'Alarm';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
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
