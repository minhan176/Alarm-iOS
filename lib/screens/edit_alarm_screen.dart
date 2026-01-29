import 'package:alarm/utils/alarm_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:jbh_ringtone/jbh_ringtone.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/alarm_model.dart';
import '../providers/alarm_provider.dart';
import '../widgets/custom_buttons.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

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
  late String _soundDisplayName;
  late bool _snooze;
  late bool _vibrate;
  late TextEditingController _labelController;
  late Duration _snoozeDuration;
  late bool _showDurationOptions;
  late AudioPlayer _previewPlayer;
  late String? _currentlyPreviewingUri;

  static const MethodChannel _alarmChannel = MethodChannel('com.example.alarm/alarm');

  @override
  void initState() {
    super.initState();
    if (widget.alarm != null) {
      _selectedTime = widget.alarm!.time;
      _label = widget.alarm!.label;
      _repeatDays = List.from(widget.alarm!.repeatDays);
      _sound = widget.alarm!.sound;
      _soundDisplayName = _getSoundDisplayName(_sound);
      _snooze = widget.alarm!.snooze;
      _vibrate = widget.alarm!.vibrate;
    } else {
      final now = DateTime.now();
      _selectedTime = now.add(const Duration(minutes: 1));
      _label = '';
      _repeatDays = [];
      _sound = 'assets/sounds/alarm.wav';
      _soundDisplayName = 'Alarm OS 26';
      _snooze = true;
      _vibrate = true;
    }
    _labelController = TextEditingController(text: _label == 'Alarm' ? '' : _label);
    _snoozeDuration = widget.alarm?.snoozeDuration ?? const Duration(minutes: 5);
    _showDurationOptions = false;
    _previewPlayer = AudioPlayer();
    _currentlyPreviewingUri = null;
  }

  String _getSoundDisplayName(String sound) {
    if (sound == 'None') {
      return 'None';
    }
    if (sound == 'assets/sounds/alarm.wav') {
      return 'Alarm OS 26';
    }
    // For system ringtones, we can't easily get the display name without loading the list
    // So we'll show a generic name or the URI basename
    if (sound.startsWith('content://')) {
      return 'System Ringtone';
    }
    // For built-in sounds, return the sound name
    return path.basename(sound);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _previewPlayer.dispose();
    // Stop any playing system ringtone preview
    _stopSystemRingtonePreview();
    super.dispose();
  }

  void _saveAlarm() {
    final provider = Provider.of<AlarmProvider>(context, listen: false);
    final alarm = AlarmModel(
      id: widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      time: _selectedTime,
      label: _label.isEmpty ? 'Alarm' : _label,
      isEnabled: true, // Always enable the alarm when saving
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

    // Set last saved alarm for toast on list screen
    provider.setLastSavedAlarm(alarm);

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

  Future<void> _stopSystemRingtonePreview() async {
    try {
      print('📱 Stopping system ringtone preview in EditAlarmScreen');
      await _alarmChannel.invokeMethod('stopSystemRingtonePreview');
      print('📱 System ringtone preview stopped successfully');
    } catch (e) {
      print('❌ Error stopping system ringtone preview: $e');
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
                      _soundDisplayName,
                      () => _showSoundPage(),
                      valueColor: CupertinoColors.white,
                    ),
                    _buildSwitchItem(
                      'Snooze',
                      _snooze,
                      (value) => setState(() => _snooze = value),
                    ),
                    Column(
                      children: [
                        _buildSettingItem(
                          'Snooze Duration',
                          '${_snoozeDuration.inMinutes} minutes',
                          () => setState(() => _showDurationOptions = !_showDurationOptions),
                          valueColor: CupertinoColors.systemOrange,
                          showArrow: false,
                          pressedOpacity: 1.0,
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _showDurationOptions ? 216 : 0,
                          curve: Curves.easeInOut,
                          child: _showDurationOptions
                              ? Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2C2C2E),
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: CupertinoPicker(
                                    backgroundColor: Colors.transparent,
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
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ]),
                  
                  if (widget.alarm != null) ...[
                    const SizedBox(height: 40),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                color: const Color(0xFF3C3C3E),
                height: 0.5,
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String value, VoidCallback onTap, {Color valueColor = CupertinoColors.systemGrey, bool showArrow = true, double pressedOpacity = 0.4}) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      pressedOpacity: pressedOpacity,
      onPressed: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: CupertinoColors.white, fontSize: 17),
            ),
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
              if (showArrow) ...[
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.forward,
                  color: CupertinoColors.systemGrey3,
                  size: 20,
                ),
              ],
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
              style: TextStyle(
                color: (_label.isEmpty || _label == 'Alarm') ? CupertinoColors.systemGrey : CupertinoColors.white,
                fontSize: 17,
              ),
              placeholderStyle: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 17),
              decoration: const BoxDecoration(),
              onChanged: (value) {
                setState(() {
                  _label = value.isEmpty ? 'Alarm' : value;
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

  void _showSoundPage() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      CupertinoPageRoute(
        builder: (context) => SoundSelector(currentSound: _sound, currentVibrate: _vibrate),
      ),
    );
    if (result != null) {
      setState(() {
        _sound = result['sound'];
        _soundDisplayName = result['soundDisplayName'] ?? _getSoundDisplayName(result['sound']);
        _vibrate = result['vibrate'];
      });
    }
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
                    pressedOpacity: 1.0,
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

String _truncateSoundName(String soundName, {int maxLength = 25}) {
  if (soundName.length <= maxLength) {
    return soundName;
  }
  return '${soundName.substring(0, maxLength - 3)}...';
}

class CustomRingtone {
  final String displayTitle;
  final String uri;
  
  CustomRingtone({required this.displayTitle, required this.uri});
}

class SoundSelector extends StatefulWidget {
  final String currentSound;
  final bool currentVibrate;

  const SoundSelector({
    super.key,
    required this.currentSound,
    required this.currentVibrate,
  });

  @override
  State<SoundSelector> createState() => _SoundSelectorState();
}

class _SoundSelectorState extends State<SoundSelector> {
  late String _selectedSound;
  late bool _vibrate;
  List<dynamic> _systemRingtones = [];
  bool _isLoadingRingtones = true;
  late AudioPlayer _previewPlayer;
  late String? _currentlyPreviewingUri;
  late String? _selectedCustomSound;

  static const MethodChannel _alarmChannel = MethodChannel('com.example.alarm/alarm');

  @override
  void initState() {
    super.initState();
    _selectedSound = widget.currentSound;
    _vibrate = widget.currentVibrate;
    _previewPlayer = AudioPlayer();
    _currentlyPreviewingUri = null;
    _selectedCustomSound = null;
    if (widget.currentSound.startsWith('/') || widget.currentSound.contains('\\')) {
      _selectedCustomSound = widget.currentSound;
    }
    _loadSystemRingtones();
  }

  Future<void> _loadSystemRingtones() async {
    try {
      // Try to load system ringtones without requesting permissions first
      // jbh_ringtone package may handle permissions internally
      final jbhRingtone = JbhRingtone();

      // Get both ringtone and alarm sounds
      final ringtoneSounds = await jbhRingtone.getRingtoneOnly();
      final alarmSounds = await jbhRingtone.getAlarmRingtones();

      // Combine and remove duplicates based on URI
      final allSounds = [...ringtoneSounds, ...alarmSounds];
      final uniqueSounds = <String, JbhRingtoneModel>{};

      for (final sound in allSounds) {
        if (!uniqueSounds.containsKey(sound.uri)) {
          uniqueSounds[sound.uri] = sound;
        }
      }
      

      setState(() {
        // Create the custom ringtones
        final noneRingtone = CustomRingtone(
          displayTitle: 'None',
          uri: 'None',
        );
        final alarmOS26 = CustomRingtone(
          displayTitle: 'Alarm OS 26',
          uri: 'assets/sounds/alarm.wav',
        );
        
        // Combine system ringtones with custom ringtones
        _systemRingtones = [noneRingtone, alarmOS26, ...uniqueSounds.values];
        _isLoadingRingtones = false;
      });
    } catch (e) {
      // If loading fails, try requesting permission and retry once
      try {
        PermissionStatus status = await Permission.storage.request();
        if (status.isGranted) {
          final jbhRingtone = JbhRingtone();

          // Get both ringtone and alarm sounds
          final ringtoneSounds = await jbhRingtone.getRingtoneOnly();
          final alarmSounds = await jbhRingtone.getAlarmRingtones();

          // Combine and remove duplicates based on URI
          final allSounds = [...ringtoneSounds, ...alarmSounds];
          final uniqueSounds = <String, JbhRingtoneModel>{};

          for (final sound in allSounds) {
            if (!uniqueSounds.containsKey(sound.uri)) {
              uniqueSounds[sound.uri] = sound;
            }
          }

          setState(() {
            // Create the custom ringtones
            final noneRingtone = CustomRingtone(
              displayTitle: 'None',
              uri: 'None',
            );
            final alarmOS26 = CustomRingtone(
              displayTitle: 'Alarm OS 26',
              uri: 'assets/sounds/alarm.wav',
            );
            
            // Combine system ringtones with custom ringtones
            _systemRingtones = [noneRingtone, alarmOS26, ...uniqueSounds.values];
            _isLoadingRingtones = false;
          });
        } else {
          // Permission denied, just use built-in sounds
          setState(() {
            _isLoadingRingtones = false;
          });
        }
      } catch (e2) {
        // If still fails, just use built-in sounds
        setState(() {
          _isLoadingRingtones = false;
        });
      }
    }
  }

  void _playRingtonePreview(dynamic ringtone) async {
    try {
      print('🎵 Starting ringtone preview for: $ringtone');
      // Stop any currently playing preview
      await _stopRingtonePreview();

      String? soundUri;
      if (ringtone is CustomRingtone) {
        soundUri = ringtone.uri;
        print('🎵 CustomRingtone URI: $soundUri');
      } else if (ringtone is Map<String, dynamic>) {
        soundUri = ringtone['uri'] as String?;
        print('🎵 Map URI: $soundUri');
      } else if (ringtone is String) {
        // Handle direct string URI
        soundUri = ringtone;
        print('🎵 String URI: $soundUri');
      } else {
        // Handle JbhRingtoneModel and other objects with uri property
        try {
          soundUri = (ringtone as dynamic).uri as String?;
          print('🎵 Dynamic URI: $soundUri, type: ${soundUri?.startsWith('assets/')}, ringtone type: ${ringtone.runtimeType}');
        } catch (e) {
          print('❌ Could not extract URI from ringtone: $e');
        }
      }

      if (soundUri != null && soundUri != 'None') {
        try {
          // Set audio context like alarm ring screen
          final AudioContext audioContext = AudioContext(
            android: AudioContextAndroid(
              usageType: AndroidUsageType.alarm,
              audioFocus: AndroidAudioFocus.gainTransientExclusive,
              audioMode: AndroidAudioMode.normal,
              contentType: AndroidContentType.music,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: {},
            ),
          );
          await _previewPlayer.setAudioContext(audioContext);

          if (soundUri.startsWith('content://')) {
            // It's a system ringtone URI - use native RingtoneManager like alarm ring screen
            await _alarmChannel.invokeMethod('playSystemRingtone', {'uri': soundUri});
            print('Playing system ringtone preview: $soundUri');
            _currentlyPreviewingUri = soundUri;

            // Auto-stop after 30 seconds (since playSystemRingtone loops)
            Future.delayed(const Duration(seconds: 30), () {
              if (_currentlyPreviewingUri == soundUri) {
                print('🎵 Auto-stopping system ringtone preview after 30 seconds');
                _stopRingtonePreview();
              }
            });
          } else if (soundUri.startsWith('assets/')) {
            // It's an asset file (like our custom Alarm OS 26)
            await _previewPlayer.setReleaseMode(ReleaseMode.loop);
            await _previewPlayer.setVolume(1.0);
            final assetPath = soundUri.replaceFirst('assets/', '');
            final audioSource = AssetSource(assetPath);
            await _previewPlayer.play(audioSource);
            print('Playing asset sound preview: $soundUri');
            _currentlyPreviewingUri = soundUri;

            // Auto-stop after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (_currentlyPreviewingUri == soundUri) {
                print('🎵 Auto-stopping asset preview after 3 seconds');
                _stopRingtonePreview();
              }
            });
          } else {
            // Use audioplayers for other sounds
            await _previewPlayer.setReleaseMode(ReleaseMode.loop);
            await _previewPlayer.setVolume(1.0);

            Source audioSource;
            if (soundUri.startsWith('/') || soundUri.contains('\\')) {
              // It's a file path from device
              audioSource = DeviceFileSource(soundUri);
            } else {
              // It's a built-in sound
              final soundFileName = soundUri.toLowerCase();
              final soundPath = 'sounds/$soundFileName.mp3';
              audioSource = AssetSource(soundPath);
            }

            await _previewPlayer.play(audioSource);
            print('Playing other sound preview: $soundUri');
            _currentlyPreviewingUri = soundUri;

            // Auto-stop after 30 seconds
            Future.delayed(const Duration(seconds: 30), () {
              if (_currentlyPreviewingUri == soundUri) {
                print('🎵 Auto-stopping other preview after 30 seconds');
                _stopRingtonePreview();
              }
            });
          }
        } catch (e) {
          print('Could not play preview sound "$soundUri": $e');
          if (!soundUri.startsWith('content://') && !soundUri.startsWith('/') && !soundUri.startsWith('assets/') && !soundUri.contains('\\')) {
            print(
              'Make sure the file assets/sounds/${soundUri.toLowerCase()}.mp3 exists',
            );
          }
        }
      } else {
        print('No sound selected for preview');
      }
    } catch (e) {
      print('Error starting preview: $e');
    }
  }

  Future<void> _stopRingtonePreview() async {
    try {
      print('🛑 Stopping ringtone preview');
      await _previewPlayer.stop();

      // Also stop system ringtone if playing
      if (_currentlyPreviewingUri != null && _currentlyPreviewingUri!.startsWith('content://')) {
        await _alarmChannel.invokeMethod('stopSystemRingtone');
        print('🛑 Stopped system ringtone');
      }

      _currentlyPreviewingUri = null;
      print('🛑 Preview stopped successfully');
    } catch (e) {
      print('❌ Error stopping ringtone preview: $e');
    }
  }

  Future<void> _playSystemRingtonePreview(String uri) async {
    try {
      print('📱 Playing system ringtone preview: $uri');
      await _alarmChannel.invokeMethod('playSystemRingtonePreview', {'uri': uri});
      _currentlyPreviewingUri = uri;
      print('📱 System ringtone preview started successfully');
    } catch (e) {
      print('❌ Error playing system ringtone preview: $e');
    }
  }

  Future<void> _stopSystemRingtonePreview() async {
    try {
      print('📱 Stopping system ringtone preview');
      await _alarmChannel.invokeMethod('stopSystemRingtonePreview');
      _currentlyPreviewingUri = null;
      print('📱 System ringtone preview stopped successfully');
    } catch (e) {
      print('❌ Error stopping system ringtone preview: $e');
    }
  }

  void _pickFromDevice() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg', 'aiff'],
    );
    if (result != null) {
      setState(() {
        _selectedSound = result.files.single.path!;
        _selectedCustomSound = result.files.single.path!;
      });
    }
  }

  String _truncateSoundName(String soundName, {int maxLength = 25}) {
    if (soundName.length <= maxLength) {
      return soundName;
    }
    return '${soundName.substring(0, maxLength - 3)}...';
  }

  String _getSelectedSoundDisplayName() {
    // Find the ringtone with the selected URI
    final ringtone = _systemRingtones.cast<dynamic>().firstWhere(
      (r) => r.uri == _selectedSound,
      orElse: () => null,
    );
    
    if (ringtone != null) {
      return ringtone.displayTitle;
    }
    
    // For custom sounds from device
    if (_selectedSound.startsWith('/') || _selectedSound.contains('\\')) {
      return _truncateSoundName(path.basename(_selectedSound));
    }
    
    // For built-in sounds
    return _selectedSound;
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop({
          'sound': _selectedSound, 
          'soundDisplayName': _getSelectedSoundDisplayName(),
          'vibrate': _vibrate
        });
        return false;
      },
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              CustomNavBar(
                backgroundColor: const Color(0xFF1C1C1E),
                leading: NavTextIconButton(
                  icon: CupertinoIcons.chevron_left,
                  text: 'Back',
                  iconColor: CupertinoColors.white,
                  textColor: CupertinoColors.white,
                  onPressed: () => Navigator.of(context).pop({
                    'sound': _selectedSound, 
                    'soundDisplayName': _getSelectedSoundDisplayName(),
                    'vibrate': _vibrate
                  }),
                ),
                middle: const Text(
                  'Sound',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Make the rest of the content scrollable
              Container(
                margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Vibrate',
                        style: TextStyle(color: CupertinoColors.white, fontSize: 17),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: CupertinoSwitch(
                          value: _vibrate,
                          activeColor: CupertinoColors.systemGreen,
                          onChanged: (value) => setState(() => _vibrate = value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Section 1: Add from device
              const Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                child: Text(
                  'SONGS',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  //physics: const ClampingScrollPhysics(),
                  itemCount: _selectedCustomSound != null ? 2 : 1, // Show custom song (if selected) and pick button
                  separatorBuilder: (context, index) => Divider(
                    color: const Color(0xFF3C3C3E),
                    height: 0.5,
                    indent: 48,
                    endIndent: 16,
                  ),
                  itemBuilder: (context, index) {
                    // Index 0: Show selected custom song if exists, otherwise show pick button
                    if (index == 0 && _selectedCustomSound != null) {
                      // Selected custom song
                      final isSelected = _selectedSound == _selectedCustomSound;
                      return CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        pressedOpacity: 1.0,
                        onPressed: () {
                          setState(() {
                            _selectedSound = _selectedCustomSound!;
                            _playRingtonePreview(_selectedSound);
                          });
                        },
                        child: SizedBox(
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: isSelected
                                    ? Icon(
                                        CupertinoIcons.check_mark,
                                        color: CupertinoColors.systemOrange,
                                        size: 24,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 200),
                                  child: Text(
                                    _truncateSoundName(path.basename(_selectedCustomSound!)),
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 17,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (index == 0 || index == 1) {
                      // Pick a song button
                      return CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        pressedOpacity: 1.0,
                        onPressed: _pickFromDevice,
                        child: SizedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(width: 32),
                              const Text(
                                'Pick a song',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 17,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                CupertinoIcons.chevron_right,
                                color: CupertinoColors.systemGrey3,
                                size: 17,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink(); // Should not reach here
                  },
                ),
              ),
              // Section 2: System Ringtones
              if (_systemRingtones.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                  child: Text(
                    'SYSTEM RINGTONES',
                    style: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      //physics: const ClampingScrollPhysics(),
                      itemCount: _systemRingtones.length,
                      separatorBuilder: (context, index) => Divider(
                        color: const Color(0xFF3C3C3E),
                        height: 0.5,
                        indent: index == 0 ? 0 : 48,
                        endIndent: index == 0 ? 0 : 16,
                      ),
                      itemBuilder: (context, index) {
                        final ringtone = _systemRingtones[index];
                        final isSelected = _selectedSound == ringtone.uri;
                        return CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          pressedOpacity: 1.0,
                          onPressed: () {
                            setState(() {
                              _selectedSound = ringtone.uri;
                              _playRingtonePreview(_selectedSound);
                            });
                          },
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: isSelected
                                    ? const Icon(
                                        CupertinoIcons.check_mark,
                                        color: CupertinoColors.systemOrange,
                                        size: 18,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  constraints: const BoxConstraints(maxWidth: 200),
                                  child: Text(
                                    _truncateSoundName(ringtone.displayTitle),
                                    style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 17,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
