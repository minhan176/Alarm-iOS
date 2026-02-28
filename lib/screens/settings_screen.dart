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
import 'guide_screen.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _sendFeedback(BuildContext context) async {
    // Collect device information
    String deviceInfo = await _getDeviceInfo(context);

    // Construct mailto URL manually to preserve spaces
    final String subject = 'Feedback Clock OS 26';
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
      screenInfo = '${mediaQuery.size.width.toInt()} px x ${mediaQuery.size.height.toInt()} px';
      
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

  void _shareApp(BuildContext context) {
    Share.share(AppLocalizations.of(context).shareMessage);
  }

  void _rateApp() {
    StoreRedirect.redirect(androidAppId: 'com.oaptech.clock', iOSAppId: '123456789');
  }

  void _openPrivacyPolicy(BuildContext context) async {
    const url = 'https://sites.google.com/view/clockos26';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      print('DEBUG: Opening Privacy Policy URL');
      await launchUrl(uri);
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(AppLocalizations.of(context).privacyPolicy),
          content: Text(AppLocalizations.of(context).privacyPolicyError),
          actions: [
            CupertinoDialogAction(
              child: Text(AppLocalizations.of(context).ok),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

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
                text: AppLocalizations.of(context).back,
                iconColor: CupertinoColors.white,
                textColor: CupertinoColors.white,
                onPressed: () => Navigator.of(context).pop(),
              ),
              middle: Text(
                AppLocalizations.of(context).settings,
                style: const TextStyle(
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
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                        child: Text(
                          AppLocalizations.of(context).timeFormat,
                          style: const TextStyle(
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
                              Text(
                                AppLocalizations.of(context).twentyFourHourFormat,
                                style: const TextStyle(color: CupertinoColors.white, fontSize: 17),
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
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                        child: Text(
                          AppLocalizations.of(context).supportAndFeedback,
                          style: const TextStyle(
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
                              onPressed: () => Navigator.of(context).push(
                                CupertinoPageRoute(builder: (context) => const GuideScreen()),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.book,
                                    color: CupertinoColors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context).guide,
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  const Icon(
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
                              onPressed: () => _sendFeedback(context),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.mail,
                                    color: CupertinoColors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context).sendFeedback,
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  const Icon(
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
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                        child: Text(
                          AppLocalizations.of(context).about,
                          style: const TextStyle(
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
                              onPressed: () => _shareApp(context),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.share,
                                    color: CupertinoColors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context).shareApp,
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  const Icon(
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
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.star,
                                    color: CupertinoColors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context).rateApp,
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  const Icon(
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
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.doc_text,
                                    color: CupertinoColors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(context).privacyPolicy,
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  const Icon(
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