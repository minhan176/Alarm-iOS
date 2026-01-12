import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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
    );

    if (widget.alarm != null) {
      provider.updateAlarm(widget.alarm!.id, alarm);
    } else {
      provider.addAlarm(alarm);
    }

    Navigator.of(context).pop();
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
                Navigator.of(context).pop(); // Close edit screen
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

    return CupertinoScaffold(
      body: CupertinoPageScaffold(
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
                  onPressed: () => Navigator.of(context).pop(),
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
                      ),
                      _buildSettingItem(
                        'Label',
                        _label.isEmpty ? 'Alarm' : _label,
                        () => _showLabelDialog(),
                      ),
                      _buildSettingItem(
                        'Sound',
                        _sound,
                        () => _showSoundDialog(),
                      ),
                      _buildSwitchItem(
                        'Snooze',
                        _snooze,
                        (value) => setState(() => _snooze = value),
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

  Widget _buildSettingItem(String title, String value, VoidCallback onTap) {
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
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
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
    showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RepeatSelector(
        selectedDays: _repeatDays,
        onDaysChanged: (days) {
          setState(() {
            _repeatDays = days;
          });
        },
      ),
    );
  }

  void _showLabelDialog() {
    final controller = TextEditingController(text: _label);
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Label'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Alarm',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () {
              setState(() {
                _label = controller.text;
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
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
}

class RepeatSelector extends StatefulWidget {
  final List<int> selectedDays;
  final Function(List<int>) onDaysChanged;

  const RepeatSelector({
    super.key,
    required this.selectedDays,
    required this.onDaysChanged,
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

    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: 500,
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: SafeArea(
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
                      'Repeat',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        widget.onDaysChanged(_selectedDays);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final dayIndex = index + 1;
                    final isSelected = _selectedDays.contains(dayIndex);
                    return Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF3C3C3E), width: 0.5),
                        ),
                      ),
                      child: CupertinoButton(
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
                              ),
                          ],
                        ),
                      ),
                    );
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
