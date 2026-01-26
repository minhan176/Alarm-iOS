import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

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
  late bool _selectedVibrate;

  @override
  void initState() {
    super.initState();
    _selectedSound = widget.currentSound;
    _selectedVibrate = widget.currentVibrate;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black,
        middle: const Text(
          'When Timer Ends',
          style: TextStyle(color: CupertinoColors.white),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).pop({
              'sound': _selectedSound,
              'vibrate': _selectedVibrate,
            });
          },
          child: const Text(
            'Done',
            style: TextStyle(color: CupertinoColors.systemBlue),
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            // Sound selection
            CupertinoListSection.insetGrouped(
              backgroundColor: CupertinoColors.black,
              children: [
                CupertinoListTile(
                  title: const Text(
                    'Sound',
                    style: TextStyle(color: CupertinoColors.white),
                  ),
                  subtitle: Text(
                    _getSoundDisplayName(),
                    style: const TextStyle(color: CupertinoColors.systemGrey),
                  ),
                  trailing: const CupertinoListTileChevron(),
                  onTap: _showSoundPicker,
                ),
              ],
            ),
            // Vibration toggle
            CupertinoListSection.insetGrouped(
              backgroundColor: CupertinoColors.black,
              children: [
                CupertinoListTile(
                  title: const Text(
                    'Vibrate',
                    style: TextStyle(color: CupertinoColors.white),
                  ),
                  trailing: CupertinoSwitch(
                    value: _selectedVibrate,
                    onChanged: (value) {
                      setState(() {
                        _selectedVibrate = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSoundPicker() async {
    final result = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Choose Sound'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop('Radar'),
            child: const Text('Radar'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop('Bell'),
            child: const Text('Bell'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop('Chime'),
            child: const Text('Chime'),
          ),
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop('None'),
            child: const Text('None'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.audio,
              );
              if (result != null && result.files.single.path != null) {
                Navigator.of(context).pop(result.files.single.path);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Custom...'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedSound = result;
      });
    }
  }

  String _getSoundDisplayName() {
    if (_selectedSound == 'None') return 'None';
    if (_selectedSound.startsWith('/') || _selectedSound.contains('\\')) {
      return path.basename(_selectedSound);
    }
    return _selectedSound;
  }
}