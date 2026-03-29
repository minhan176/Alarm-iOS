import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/rating_dialog.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:jbh_ringtone/jbh_ringtone.dart';
import 'package:permission_handler/permission_handler.dart';
import '../l10n/app_localizations.dart';
import '../models/alarm_model.dart';
import '../providers/alarm_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/custom_buttons.dart';
import 'package:audioplayers/audioplayers.dart';

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

  static const MethodChannel _alarmChannel = MethodChannel('com.oaptech.clock/alarm');

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
      _sound = 'assets/sounds/alarm.mp3';
      _soundDisplayName = 'Alarm Phone 17 OS 26';
      _snooze = true;
      _vibrate = true;
    }
    _labelController = TextEditingController(text: _label);
    _snoozeDuration = widget.alarm?.snoozeDuration ?? const Duration(minutes: 5);
    _showDurationOptions = false;
    _previewPlayer = AudioPlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _soundDisplayName = _getSoundDisplayName(_sound, AppLocalizations.of(context));
  }

  String _getSoundDisplayName(String sound, [AppLocalizations? loc]) {
    if (sound == 'None') {
      return loc?.none ?? 'None';
    }
    if (sound == 'assets/sounds/alarm.mp3') {
      return 'Alarm Phone 17 OS 26';
    }
    // For system ringtones, we can't easily get the display name without loading the list
    // So we'll show a generic name or the URI basename
    if (sound.startsWith('content://')) {
      return loc?.systemRingtone ?? 'System Ringtone';
    }
    // For built-in sounds, return the sound name (truncated if too long)
    return _truncateSoundName(path.basename(sound));
  }

  @override
  void dispose() {
    _labelController.dispose();
    _previewPlayer.dispose();
    // Stop any playing system ringtone preview
    _stopSystemRingtonePreview();
    super.dispose();
  }

  void _saveAlarm() async {
    final provider = Provider.of<AlarmProvider>(context, listen: false);
    final alarm = AlarmModel(
      id: widget.alarm?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      time: _selectedTime,
      label: _label,
      isEnabled: true, // Always enable the alarm when saving
      repeatDays: _repeatDays,
      sound: _sound,
      snooze: _snooze,
      vibrate: _vibrate,
      snoozeDuration: _snoozeDuration,
    );

    final isNewAlarm = widget.alarm == null;

    if (widget.alarm != null) {
      provider.updateAlarm(widget.alarm!.id, alarm);
    } else {
      provider.addAlarm(alarm);
    }

    // Set last saved alarm for toast on list screen
    provider.setLastSavedAlarm(alarm);

    Navigator.of(context, rootNavigator: true).pop();

    // Check and show review dialog after adding new alarm
    if (isNewAlarm) {
      await _checkAndShowReviewDialog();
    }
  }

  Future<void> _checkAndShowReviewDialog() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user already rated or dismissed
    final hasRated = prefs.getBool('has_rated_app') ?? false;
    final dismissed = prefs.getBool('rating_dialog_dismissed') ?? false;
    
    if (hasRated || dismissed) return;
    
    // Increment add alarm count
    int addCount = prefs.getInt('add_alarm_count') ?? 0;
    addCount++;
    await prefs.setInt('add_alarm_count', addCount);
    
    // Show dialog after 3rd alarm
    if (addCount >= 3 && mounted) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return const RatingDialog();
        },
      );
    }
  }

  void _deleteAlarm() {
    if (widget.alarm != null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(AppLocalizations.of(context).deleteAlarm),
          content: Text(AppLocalizations.of(context).deleteAlarmConfirm),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(AppLocalizations.of(context).cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(AppLocalizations.of(context).delete),
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
      await _alarmChannel.invokeMethod('stopSystemRingtonePreview');
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
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
              middle: FittedBox(
                fit: BoxFit.scaleDown, child: Text(
                widget.alarm != null ? AppLocalizations.of(context).editAlarm : AppLocalizations.of(context).addAlarm,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              )),
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
                use24hFormat: Provider.of<SettingsProvider>(context).is24HourFormat,
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
                      AppLocalizations.of(context).repeat,
                      _getRepeatText(AppLocalizations.of(context)),
                      () => _showRepeatDialog(),
                      valueColor: CupertinoColors.white,
                    ),
                    _buildLabelItem(),
                    _buildSettingItem(
                      AppLocalizations.of(context).sound,
                      _soundDisplayName,
                      () => _showSoundPage(),
                      valueColor: CupertinoColors.white,
                    ),
                    _buildSwitchItem(
                      AppLocalizations.of(context).snooze,
                      _snooze,
                      (value) => setState(() => _snooze = value),
                    ),
                    Column(
                      children: [
                        _buildSettingItem(
                          AppLocalizations.of(context).snoozeDuration,
                          AppLocalizations.of(context).minutesValue(_snoozeDuration.inMinutes),
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
                                          AppLocalizations.of(context).minutesValue(minutes),
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
                        onPressed: _deleteAlarm,
                        child: Text(
                          AppLocalizations.of(context).deleteAlarm,
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 17,
                          ),
                        ),
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
          Text(
            AppLocalizations.of(context).label,
            style: const TextStyle(color: CupertinoColors.white, fontSize: 17),
          ),
          Expanded(
            child: CupertinoTextField(
              controller: _labelController,
              placeholder: AppLocalizations.of(context).alarm,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _label.isEmpty ? CupertinoColors.systemGrey : CupertinoColors.white,
                fontSize: 17,
              ),
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


  String _getRepeatText(AppLocalizations loc) {
    if (_repeatDays.isEmpty) return loc.never;
    if (_repeatDays.length == 7) return loc.everyDay;
    if (_repeatDays.length == 5 &&
        _repeatDays.contains(1) &&
        _repeatDays.contains(2) &&
        _repeatDays.contains(3) &&
        _repeatDays.contains(4) &&
        _repeatDays.contains(5)) {
      return loc.weekdays;
    }
    if (_repeatDays.length == 2 &&
        _repeatDays.contains(6) &&
        _repeatDays.contains(7)) {
      return loc.weekends;
    }
    final dayNames = [loc.mon, loc.tue, loc.wed, loc.thu, loc.fri, loc.sat, loc.sun];
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
        _soundDisplayName = result['soundDisplayName'] ?? _getSoundDisplayName(result['sound'], AppLocalizations.of(context));
        _vibrate = result['vibrate'];
      });
    }
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
    final days = [
      AppLocalizations.of(context).monday,
      AppLocalizations.of(context).tuesday,
      AppLocalizations.of(context).wednesday,
      AppLocalizations.of(context).thursday,
      AppLocalizations.of(context).friday,
      AppLocalizations.of(context).saturday,
      AppLocalizations.of(context).sunday,
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
                text: AppLocalizations.of(context).back,
                iconColor: CupertinoColors.white,
                textColor: CupertinoColors.white,
                onPressed: () => Navigator.of(context).pop(_selectedDays),
              ),
              middle: Text(
                AppLocalizations.of(context).repeat,
                style: const TextStyle(
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
  late AudioPlayer _previewPlayer;
  late String? _currentlyPreviewingUri;
  late String? _selectedCustomSound;

  static const MethodChannel _alarmChannel = MethodChannel('com.oaptech.clock/alarm');

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
          displayTitle: AppLocalizations.of(context).none,
          uri: 'None',
        );
        final alarmOS26 = CustomRingtone(
          displayTitle: 'Alarm Phone 17 OS 26',
          uri: 'assets/sounds/alarm.mp3',
        );
        
        // Combine system ringtones with custom ringtones
        _systemRingtones = [noneRingtone, alarmOS26, ...uniqueSounds.values];
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
              displayTitle: AppLocalizations.of(context).none,
              uri: 'None',
            );
            final alarmOS26 = CustomRingtone(
              displayTitle: 'Alarm Phone 17 OS 26',
              uri: 'assets/sounds/alarm.mp3',
            );
            
            // Combine system ringtones with custom ringtones
            _systemRingtones = [noneRingtone, alarmOS26, ...uniqueSounds.values];
          });
        } else {
          // Permission denied, just use built-in sounds
          setState(() {
          });
        }
      } catch (e2) {
        // If still fails, just use built-in sounds
        setState(() {
        });
      }
    }
  }

  void _playRingtonePreview(dynamic ringtone) async {
    try {
      // Stop any currently playing preview
      await _stopRingtonePreview();

      String? soundUri;
      if (ringtone is CustomRingtone) {
        soundUri = ringtone.uri;
      } else if (ringtone is Map<String, dynamic>) {
        soundUri = ringtone['uri'] as String?;
      } else if (ringtone is String) {
        // Handle direct string URI
        soundUri = ringtone;
      } else {
        // Handle JbhRingtoneModel and other objects with uri property
        try {
          soundUri = (ringtone as dynamic).uri as String?;
        } catch (e) {
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
            _currentlyPreviewingUri = soundUri;

            // Auto-stop after 30 seconds (since playSystemRingtone loops)
            Future.delayed(const Duration(seconds: 30), () {
              if (_currentlyPreviewingUri == soundUri) {
                _stopRingtonePreview();
              }
            });
          } else if (soundUri.startsWith('assets/')) {
            // It's an asset file (like our custom Alarm Phone 17 OS 26)
            await _previewPlayer.setReleaseMode(ReleaseMode.stop);
            await _previewPlayer.setVolume(1.0);
            final assetPath = soundUri.replaceFirst('assets/', '');
            final audioSource = AssetSource(assetPath);
            await _previewPlayer.play(audioSource);
            _currentlyPreviewingUri = soundUri;

            // Auto-stop after 3 seconds for asset previews
            Future.delayed(const Duration(seconds: 3), () {
              if (_currentlyPreviewingUri == soundUri) {
                _stopRingtonePreview();
              }
            });
          } else {
            // Use audioplayers for other sounds
            await _previewPlayer.setReleaseMode(ReleaseMode.stop);
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
            _currentlyPreviewingUri = soundUri;
          }
        } catch (e) {
          if (!soundUri.startsWith('content://') && !soundUri.startsWith('/') && !soundUri.startsWith('assets/') && !soundUri.contains('\\')) {
          }
        }
      } else {
      }
    } catch (e) {
    }
  }

  Future<void> _stopRingtonePreview() async {
    try {
      await _previewPlayer.stop();

      // Also stop system ringtone if playing
      if (_currentlyPreviewingUri != null && _currentlyPreviewingUri!.startsWith('content://')) {
        await _alarmChannel.invokeMethod('stopSystemRingtone');
      }

      _currentlyPreviewingUri = null;
    } catch (e) {
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
    _stopRingtonePreview();
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
                  text: AppLocalizations.of(context).back,
                  iconColor: CupertinoColors.white,
                  textColor: CupertinoColors.white,
                  onPressed: () => Navigator.of(context).pop({
                    'sound': _selectedSound, 
                    'soundDisplayName': _getSelectedSoundDisplayName(),
                    'vibrate': _vibrate
                  }),
                ),
                middle: Text(
                  AppLocalizations.of(context).sound,
                  style: const TextStyle(
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
                      Text(
                        AppLocalizations.of(context).vibrate,
                        style: const TextStyle(color: CupertinoColors.white, fontSize: 17),
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
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                child: Text(
                  AppLocalizations.of(context).songs,
                  style: const TextStyle(
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
                              Text(
                                AppLocalizations.of(context).pickASong,
                                style: const TextStyle(
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
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                  child: Text(
                    AppLocalizations.of(context).systemRingtones,
                    style: const TextStyle(
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
