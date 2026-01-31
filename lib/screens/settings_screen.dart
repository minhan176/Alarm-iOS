import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../widgets/custom_buttons.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _sendFeedback(BuildContext context) async {
    // Collect device information
    String deviceInfo = await _getDeviceInfo(context);

    // Construct mailto URL manually to preserve spaces
    final String subject = 'Feedback clock';
    final String mailtoUrl = 'mailto:oaptech.sp@gmail.com?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(deviceInfo)}';

    final Uri emailUri = Uri.parse(mailtoUrl);

    await launchUrl(emailUri);
  }

  Future<String> _getDeviceInfo(BuildContext context) async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    final mediaQuery = MediaQuery.of(context);
    
    String deviceName = 'Unknown';
    String osVersion = 'Unknown';
    String language = 'Unknown';
    String timezone = 'Unknown';
    String screenInfo = 'Unknown';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        deviceName = androidInfo.model ?? 'Unknown Android Device';
        osVersion = 'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceName = iosInfo.utsname.machine ?? 'Unknown iOS Device';
        osVersion = 'iOS ${iosInfo.systemVersion}';
      }
      
      // Language
      language = Platform.localeName;
      
      // Timezone
      timezone = DateTime.now().timeZoneName;
      
      // Screen info
      screenInfo = '${mediaQuery.size.width.toInt()}x${mediaQuery.size.height.toInt()} (${mediaQuery.devicePixelRatio.toStringAsFixed(1)}x)';
      
    } catch (e) {
      // If device info collection fails, use fallback
      deviceName = 'Device info collection failed';
    }

    return '''
DEVICE INFORMATION:

Device Name: $deviceName
Operating System: $osVersion
Language: $language
Timezone: $timezone
Screen Resolution: $screenInfo

Please describe your feedback below:

''';
  }

  void _shareApp() {
    Share.share('Check out this amazing Alarm app! Download it now.');
  }

  void _rateApp() {
    StoreRedirect.redirect(androidAppId: 'com.example.alarm', iOSAppId: '123456789');
  }

  void _openPrivacyPolicy(BuildContext context) async {
    const url = 'https://example.com/privacy-policy';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Privacy Policy'),
          content: const Text('Unable to open privacy policy. Please visit our website.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize system setting on first build if not already initialized
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    settingsProvider.initializeWithSystemSetting(MediaQuery.of(context).alwaysUse24HourFormat);

    return CupertinoPageScaffold(
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
                onPressed: () => Navigator.of(context).pop(),
              ),
              middle: const Text(
                'Settings',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Consumer<SettingsProvider>(
                builder: (context, settingsProvider, child) {
                  return ListView(
                    children: [
                      // Section 1: Time Format
                      const Padding(
                        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                        child: Text(
                          'TIME FORMAT',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
                                '24-Hour Format',
                                style: TextStyle(color: CupertinoColors.white, fontSize: 17),
                              ),
                              Transform.scale(
                                scale: 0.8,
                                child: CupertinoSwitch(
                                  value: settingsProvider.is24HourFormat,
                                  activeColor: CupertinoColors.systemGreen,
                                  onChanged: (value) => settingsProvider.set24HourFormat(value),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Section 2: Support & Feedback
                      const Padding(
                        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                        child: Text(
                          'SUPPORT & FEEDBACK',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              pressedOpacity: 1.0,
                              onPressed: () => _sendFeedback(context),
                              child: const Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.mail,
                                    color: CupertinoColors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Send Feedback',
                                      style: TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: CupertinoColors.systemGrey,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Section 3: About
                      const Padding(
                        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                        child: Text(
                          'ABOUT',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              pressedOpacity: 1.0,
                              onPressed: _shareApp,
                              child: const Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.share,
                                    color: CupertinoColors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Share App',
                                      style: TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: CupertinoColors.systemGrey,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              color: const Color(0xFF3C3C3E),
                              height: 0.5,
                              indent: 48,
                              endIndent: 16,
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              pressedOpacity: 1.0,
                              onPressed: _rateApp,
                              child: const Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.star,
                                    color: CupertinoColors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Rate App',
                                      style: TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: CupertinoColors.systemGrey,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              color: const Color(0xFF3C3C3E),
                              height: 0.5,
                              indent: 48,
                              endIndent: 16,
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              pressedOpacity: 1.0,
                              onPressed: () => _openPrivacyPolicy(context),
                              child: const Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.doc_text,
                                    color: CupertinoColors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Privacy Policy',
                                      style: TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: CupertinoColors.systemGrey,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}