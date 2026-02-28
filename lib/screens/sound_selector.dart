import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:jbh_ringtone/jbh_ringtone.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/custom_buttons.dart';
import 'package:audioplayers/audioplayers.dart';
import '../l10n/app_localizations.dart';

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
          // Stop any current preview
          await _previewPlayer.stop();

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

            // Auto-stop after 5 seconds (since playSystemRingtone loops)
            Future.delayed(const Duration(seconds: 5), () {
              if (_currentlyPreviewingUri == soundUri) {
                print('🎵 Auto-stopping system ringtone preview after 5 seconds');
                _stopRingtonePreview();
              }
            });
          } else if (soundUri.startsWith('assets/')) {
            // It's an asset file (like our custom Alarm OS 26)
            await _previewPlayer.setReleaseMode(ReleaseMode.stop);
            await _previewPlayer.setVolume(1.0);
            final assetPath = soundUri.replaceFirst('assets/', '');
            final audioSource = AssetSource(assetPath);
            await _previewPlayer.play(audioSource);
            print('Playing asset sound preview: $soundUri');
            _currentlyPreviewingUri = soundUri;
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
            print('Playing other sound preview: $soundUri');
            _currentlyPreviewingUri = soundUri;
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
                  AppLocalizations.of(context).whenTimerEnds,
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