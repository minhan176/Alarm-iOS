import 'package:clock_os_26/screens/upgrade_pro_screen.dart';
import 'package:clock_os_26/widgets/settings_large_banner_ad.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../widgets/custom_buttons.dart';
import '../providers/settings_provider.dart';
import 'guide_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import '../widgets/rating_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _sendFeedback(BuildContext context) async {
    // Collect device information
    String deviceInfo = await _getDeviceInfo(context);

    // Construct mailto URL manually to preserve spaces
    final String subject = 'Feedback Alarm Phone 17 OS 26';
    final String mailtoUrl =
        'mailto:oaptech.sp@gmail.com?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(deviceInfo)}';

    final Uri emailUri = Uri.parse(mailtoUrl);

    AdService.shouldSuppressAppOpenAd = true;
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
        deviceName = androidInfo.model;
        osVersion =
            'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        deviceName = iosInfo.utsname.machine;
        osVersion = 'iOS ${iosInfo.systemVersion}';
      }

      // Language
      language = Platform.localeName;

      // Timezone
      timezone = DateTime.now().timeZoneName;

      // Screen info
      screenInfo =
          '${mediaQuery.size.width.toInt()} px x ${mediaQuery.size.height.toInt()} px';
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

  void _rateApp(BuildContext context) {
    AdService.shouldSuppressAppOpenAd = true;
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return const RatingDialog();
      },
    );
  }

  void _openPrivacyPolicy(BuildContext context) async {
    const url = 'https://sites.google.com/view/clockos26';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      print('DEBUG: Opening Privacy Policy URL');
      AdService.shouldSuppressAppOpenAd = true;
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

  void _checkForUpdates(BuildContext context) async {
    const url =
        'https://play.google.com/store/apps/details?id=com.oaptech.clock';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      AdService.shouldSuppressAppOpenAd = true;
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<SettingsProvider>(context, listen: false);

    return WillPopScope(
      onWillPop: () async {
        AdService.shouldSuppressAppOpenAd = true;
        return true;
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
                  onPressed: () {
                    AdService.shouldSuppressAppOpenAd = true;
                    Navigator.of(context).pop();
                  },
                ),
                middle: Text(
                  AppLocalizations.of(context).settings,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
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
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 8,
                          ),
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
                          margin: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Column(
                              children: [
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 0,
                                  ),
                                  pressedOpacity: 1.0,
                                  onPressed: settingsProvider.isProUnlocked
                                      ? () {}
                                      : () => Navigator.of(context).push(
                                          CupertinoPageRoute(
                                            builder: (context) =>
                                                const UpgradeProScreen(),
                                            fullscreenDialog: true,
                                          ),
                                        ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.workspace_premium,
                                        color: CupertinoColors.systemOrange,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            settingsProvider.isProUnlocked
                                                ? AppLocalizations.of(
                                                    context,
                                                  ).proActivatedStatus
                                                : AppLocalizations.of(
                                                    context,
                                                  ).bestExperience,
                                            style: const TextStyle(
                                              color: CupertinoColors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      settingsProvider.isProUnlocked
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              child: Icon(
                                                CupertinoIcons.checkmark,
                                                color: CupertinoColors
                                                    .systemOrange,
                                                size: 20,
                                              ),
                                            )
                                          : CupertinoButton(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              minSize: 0,
                                              color: CupertinoColors
                                                  .systemOrange
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  CupertinoPageRoute(
                                                    builder: (context) =>
                                                        const UpgradeProScreen(),
                                                    fullscreenDialog: true,
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                AppLocalizations.of(
                                                  context,
                                                ).UPGRADE_PRO,
                                                style: const TextStyle(
                                                  color: CupertinoColors
                                                      .systemOrange,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                                Divider(
                                  color: const Color(0xFF3C3C3E),
                                  height: 0.5,
                                  indent: 32,

                                  //endIndent: 0,
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.clock,
                                          color: CupertinoColors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          ).twentyFourHourFormat,
                                          style: const TextStyle(
                                            color: CupertinoColors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),

                                    CupertinoSwitch(
                                      value: settingsProvider.is24HourFormat,
                                      activeColor: CupertinoColors.systemGreen,
                                      onChanged: (value) => settingsProvider
                                          .set24HourFormat(value),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Section 2: Support & Feedback
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 8,
                          ),
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
                          margin: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                pressedOpacity: 1.0,
                                onPressed: () => Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (context) => const GuideScreen(),
                                  ),
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
                                          fontSize: 16,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
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
                                        AppLocalizations.of(
                                          context,
                                        ).sendFeedback,
                                        style: const TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 16,
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
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 8,
                          ),
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
                          margin: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
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
                                          fontSize: 16,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                pressedOpacity: 1.0,
                                onPressed: () => _rateApp(context),
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
                                          fontSize: 16,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
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
                                        AppLocalizations.of(
                                          context,
                                        ).privacyPolicy,
                                        style: const TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 16,
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                pressedOpacity: 1.0,
                                onPressed: () => _checkForUpdates(context),
                                child: Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.arrow_2_circlepath,
                                      color: CupertinoColors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).checkForUpdates,
                                        style: const TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 16,
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
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
              const SettingsLargeBannerAd(),
            ],
          ),
        ),
      ),
    );
  }
}
