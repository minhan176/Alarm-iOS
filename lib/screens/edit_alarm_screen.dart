import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alarm_model.dart';
import '../providers/alarm_provider.dart';
import '../widgets/custom_buttons.dart';

class EditAlarmScreen extends StatefulWidget {
  final AlarmModel? alarm;

  const EditAlarmScreen({super.key, this.alarm});

  @override
  State<EditAlarmScreen> createState() => _EditAlarmScreenState();
}

class _EditAlarmScreenState extends State<EditAlarmScreen> {
  late DateTime _selectedTime;
  late String _label;
  late List<int> _repeatDays;
  late String _sound;
  late bool _snooze;
  late bool _vibrate;
  late TextEditingController _labelController;
  late Duration _snoozeDuration;
  late bool _showDurationOptions;

  @override
  void initState() {
    super.initState();
    if (widget.alarm != null) {
      _selectedTime = widget.alarm!.time;
      _label = widget.alarm!.label;
      _repeatDays = List.from(widget.alarm!.repeatDays);
      _sound = widget.alarm!.sound;
      _snooze = widget.alarm!.snooze;
      _vibrate = widget.alarm!.vibrate;
    } else {
      final now = DateTime.now();
      _selectedTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      _label = '';
      _repeatDays = [];
      _sound = 'Radar';
      _snooze = true;
      _vibrate = true;
    }
    _labelController = TextEditingController(text: _label);
    _snoozeDuration = widget.alarm?.snoozeDuration ?? const Duration(minutes: 5);
    _showDurationOptions = false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _saveAlarm() {
    final provider = Provider.of<AlarmProvider>(context, listen: false);
    final alarm = AlarmModel(
      id: widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      time: _selectedTime,
      label: _label.isEmpty ? 'Alarm' : _label,
      isEnabled: widget.alarm?.isEnabled ?? true,
      repeatDays: _repeatDays,
      sound: _sound,
      snooze: _snooze,
      vibrate: _vibrate,
      snoozeDuration: _snoozeDuration,
    );

    if (widget.alarm != null) {
      provider.updateAlarm(widget.alarm!.id, alarm);
    } else {
      provider.addAlarm(alarm);
    }

    Navigator.of(context, rootNavigator: true).pop();
  }

  void _deleteAlarm() {
    if (widget.alarm != null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Delete Alarm'),
          content: const Text('Are you sure you want to delete this alarm?'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Delete'),
              onPressed: () {
                Provider.of<AlarmProvider>(
                  context,
                  listen: false,
                ).deleteAlarm(widget.alarm!.id);
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context, rootNavigator: true).pop(); // Close edit screen
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final use24HourFormat = MediaQuery.of(context).alwaysUse24HourFormat;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      child: SafeArea(
        child: Column(
          children: [
            // Custom Navigation Bar
            SizedBox(height: 5,),
            CustomNavBar(
              backgroundColor: const Color(0xFF1C1C1E),
              leading: NavIconButton(
                icon: CupertinoIcons.xmark,
                iconColor: CupertinoColors.white,
                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              ),
              middle: Text(
                widget.alarm != null ? 'Edit Alarm' : 'Add Alarm',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: NavIconButton(
                icon: CupertinoIcons.checkmark,
                iconColor: CupertinoColors.white,
                backgroundColor: CupertinoColors.systemOrange,
                onPressed: _saveAlarm,
              ),
            ),
            // Time Picker
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: _selectedTime,
                use24hFormat: use24HourFormat,
                onDateTimeChanged: (DateTime newTime) {
                  setState(() {
                    _selectedTime = newTime;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            // Settings List
            Expanded(
              child: ListView(
                children: [
                  _buildSettingGroup([
                    _buildSettingItem(
                      'Repeat',
                      _getRepeatText(),
                      () => _showRepeatDialog(),
                      valueColor: CupertinoColors.white,
                    ),
                    _buildLabelItem(),
                    _buildSettingItem(
                      'Sound',
                      _sound,
                      () => _showSoundDialog(),
                      valueColor: CupertinoColors.white,
                    ),
                    _buildSwitchItem(
                      'Snooze',
                      _snooze,
                      (value) => setState(() => _snooze = value),
                    ),
                    _buildSettingItem(
                      'Snooze Duration',
                      '${_snoozeDuration.inMinutes} minutes',
                      () => setState(() => _showDurationOptions = !_showDurationOptions),
                      valueColor: CupertinoColors.white,
                    ),
                    AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _showDurationOptions ? 216 : 0,
                    curve: Curves.easeInOut,
                    child: _showDurationOptions
                        ? CupertinoPicker(
                            backgroundColor: const Color(0xFF1C1C1E),
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(
                              initialItem: _snoozeDuration.inMinutes - 1,
                            ),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                _snoozeDuration = Duration(minutes: index + 1);
                              });
                            },
                            children: List.generate(15, (index) {
                              final minutes = index + 1;
                              return Center(
                                child: Text(
                                  '$minutes minutes',
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 17,
                                  ),
                                ),
                              );
                            }),
                          )
                        : null,
                  ),
                  ]),
                  
                  if (widget.alarm != null) ...[
                    const SizedBox(height: 40),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text(
                          'Delete Alarm',
                          style: TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 17,
                          ),
                        ),
                        onPressed: _deleteAlarm,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem(String title, String value, VoidCallback onTap, {Color valueColor = CupertinoColors.systemGrey}) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: CupertinoColors.white, fontSize: 17),
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.forward,
                color: CupertinoColors.systemGrey3,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: CupertinoColors.white, fontSize: 17),
          ),
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: value,
              activeColor: CupertinoColors.systemGreen,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Label',
            style: TextStyle(color: CupertinoColors.white, fontSize: 17),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: _labelController,
              placeholder: 'Alarm',
              textAlign: TextAlign.right,
              style: const TextStyle(color: CupertinoColors.white, fontSize: 17),
              placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 17),
              decoration: const BoxDecoration(),
              onChanged: (value) {
                setState(() {
                  _label = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(15, (index) {
          final minutes = index + 1;
          final isSelected = _snoozeDuration.inMinutes == minutes;
          return CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            onPressed: () {
              setState(() {
                _snoozeDuration = Duration(minutes: minutes);
                _showDurationOptions = false;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$minutes minutes',
                  style: const TextStyle(color: CupertinoColors.white, fontSize: 17),
                ),
                if (isSelected)
                  const Icon(
                    CupertinoIcons.check_mark,
                    color: CupertinoColors.systemOrange,
                    size: 24,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getRepeatText() {
    if (_repeatDays.isEmpty) return 'Never';
    if (_repeatDays.length == 7) return 'Every day';
    if (_repeatDays.length == 5 &&
        _repeatDays.contains(1) &&
        _repeatDays.contains(2) &&
        _repeatDays.contains(3) &&
        _repeatDays.contains(4) &&
        _repeatDays.contains(5)) {
      return 'Weekdays';
    }
    if (_repeatDays.length == 2 &&
        _repeatDays.contains(6) &&
        _repeatDays.contains(7)) {
      return 'Weekends';
    }
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return _repeatDays.map((day) => dayNames[day - 1]).join(', ');
  }

  void _showRepeatDialog() async {
    final result = await Navigator.of(context).push<List<int>>(
      CupertinoPageRoute(
        builder: (context) => RepeatSelector(
          selectedDays: _repeatDays,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _repeatDays = result;
      });
    }
  }

  void _showSoundDialog() {
    final sounds = [
      'Radar',
      'Apex',
      'Beacon',
      'Bulletin',
      'By The Seaside',
      'Chimes',
      'Circuit',
      'Constellation',
      'Cosmic',
      'Crystals',
      'Hillside',
      'Illuminate',
      'Night Owl',
      'Opening',
      'Playtime',
      'Presto',
      'Radar (Classic)',
      'Reflection',
      'Ripples',
      'Sencha',
      'Signal',
      'Silk',
      'Slow Rise',
      'Stargaze',
      'Summit',
      'Twinkle',
      'Uplift',
      'Waves',
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: const Color(0xFF1C1C1E),
        child: Column(
          children: [
            Container(
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF3C3C3E), width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Sound',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                backgroundColor: const Color(0xFF1C1C1E),
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: sounds.indexOf(_sound),
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _sound = sounds[index];
                  });
                },
                children: sounds
                    .map(
                      (sound) => Center(
                        child: Text(
                          sound,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnoozeDurationDialog() {
    final durations = [1, 5, 10, 15, 20, 30];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: const Color(0xFF1C1C1E),
        child: Column(
          children: [
            Container(
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF3C3C3E), width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Snooze Duration',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                backgroundColor: const Color(0xFF1C1C1E),
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: durations.indexOf(_snoozeDuration.inMinutes),
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _snoozeDuration = Duration(minutes: durations[index]);
                  });
                },
                children: durations
                    .map(
                      (duration) => Center(
                        child: Text(
                          '$duration minutes',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RepeatSelector extends StatefulWidget {
  final List<int> selectedDays;

  const RepeatSelector({
    super.key,
    required this.selectedDays,
  });

  @override
  State<RepeatSelector> createState() => _RepeatSelectorState();
}

class _RepeatSelectorState extends State<RepeatSelector> {
  late List<int> _selectedDays;

  @override
  void initState() {
    super.initState();
    _selectedDays = List.from(widget.selectedDays);
  }

  @override
  Widget build(BuildContext context) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_selectedDays);
        return false;
      },
      child: CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 5),
            CustomNavBar(
              backgroundColor: const Color(0xFF1C1C1E),
              leading: NavTextIconButton(
                icon: CupertinoIcons.chevron_left,
                text: 'Back',
                iconColor: CupertinoColors.white,
                textColor: CupertinoColors.white,
                onPressed: () => Navigator.of(context).pop(_selectedDays),
              ),
              middle: const Text(
                'Repeat',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: days.length,
                separatorBuilder: (context, index) => Divider(
                  color: const Color(0xFF3C3C3E),
                  height: 0.5,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final dayIndex = index + 1;
                  final isSelected = _selectedDays.contains(dayIndex);
                  return CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(dayIndex);
                        } else {
                          _selectedDays.add(dayIndex);
                        }
                        _selectedDays.sort();
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          days[index],
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 17,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            CupertinoIcons.check_mark,
                            color: CupertinoColors.systemOrange,
                            size: 24,
                          )
                        else
                          const SizedBox(width: 24, height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ));
  }
}
