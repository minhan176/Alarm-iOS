import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'translations/ar.dart';
import 'translations/bn.dart';
import 'translations/bg.dart';
import 'translations/ca.dart';
import 'translations/zh_cn.dart';
import 'translations/zh_tw.dart';
import 'translations/hr.dart';
import 'translations/cs.dart';
import 'translations/da.dart';
import 'translations/nl.dart';
import 'translations/en.dart';
import 'translations/et.dart';
import 'translations/fi.dart';
import 'translations/fr.dart';
import 'translations/de.dart';
import 'translations/el.dart';
import 'translations/gu.dart';
import 'translations/he.dart';
import 'translations/hi.dart';
import 'translations/hu.dart';
import 'translations/is_.dart';
import 'translations/id.dart';
import 'translations/it.dart';
import 'translations/ja.dart';
import 'translations/kn.dart';
import 'translations/ko.dart';
import 'translations/lv.dart';
import 'translations/lt.dart';
import 'translations/ml.dart';
import 'translations/mr.dart';
import 'translations/no.dart';
import 'translations/fa.dart';
import 'translations/pl.dart';
import 'translations/pt.dart';
import 'translations/pa.dart';
import 'translations/ro.dart';
import 'translations/ru.dart';
import 'translations/sk.dart';
import 'translations/sl.dart';
import 'translations/es.dart';
import 'translations/sw.dart';
import 'translations/sv.dart';
import 'translations/ta.dart';
import 'translations/te.dart';
import 'translations/th.dart';
import 'translations/tr.dart';
import 'translations/uk.dart';
import 'translations/ur.dart';
import 'translations/vi.dart';
import 'translations/zu.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate> localizationsDelegates = [
    delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('bn'),
    Locale('bg'),
    Locale('ca'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale('hr'),
    Locale('cs'),
    Locale('da'),
    Locale('nl'),
    Locale('en'),
    Locale('et'),
    Locale('fi'),
    Locale('fr'),
    Locale('de'),
    Locale('el'),
    Locale('gu'),
    Locale('he'),
    Locale('hi'),
    Locale('hu'),
    Locale('is'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('kn'),
    Locale('ko'),
    Locale('lv'),
    Locale('lt'),
    Locale('ml'),
    Locale('mr'),
    Locale('no'),
    Locale('nb'),
    Locale('fa'),
    Locale('pl'),
    Locale('pt'),
    Locale('pa'),
    Locale('ro'),
    Locale('ru'),
    Locale('sk'),
    Locale('sl'),
    Locale('es'),
    Locale('sw'),
    Locale('sv'),
    Locale('ta'),
    Locale('te'),
    Locale('th'),
    Locale('tr'),
    Locale('uk'),
    Locale('ur'),
    Locale('vi'),
    Locale('zu'),
  ];

  late final Map<String, String> _localizedStrings = _getTranslations();

  Map<String, String> _getTranslations() {
    final String langCode;
    if (locale.scriptCode == 'Hant') {
      langCode = 'zh_tw';
    } else if (locale.languageCode == 'zh') {
      langCode = 'zh_cn';
    } else if (locale.languageCode == 'nb') {
      langCode = 'no';
    } else {
      langCode = locale.languageCode;
    }

    final Map<String, Map<String, String>> allTranslations = {
      'ar': arTranslations,
      'bn': bnTranslations,
      'bg': bgTranslations,
      'ca': caTranslations,
      'zh_cn': zhCnTranslations,
      'zh_tw': zhTwTranslations,
      'hr': hrTranslations,
      'cs': csTranslations,
      'da': daTranslations,
      'nl': nlTranslations,
      'en': enTranslations,
      'et': etTranslations,
      'fi': fiTranslations,
      'fr': frTranslations,
      'de': deTranslations,
      'el': elTranslations,
      'gu': guTranslations,
      'he': heTranslations,
      'hi': hiTranslations,
      'hu': huTranslations,
      'is': isTranslations,
      'id': idTranslations,
      'it': itTranslations,
      'ja': jaTranslations,
      'kn': knTranslations,
      'ko': koTranslations,
      'lv': lvTranslations,
      'lt': ltTranslations,
      'ml': mlTranslations,
      'mr': mrTranslations,
      'no': noTranslations,
      'fa': faTranslations,
      'pl': plTranslations,
      'pt': ptTranslations,
      'pa': paTranslations,
      'ro': roTranslations,
      'ru': ruTranslations,
      'sk': skTranslations,
      'sl': slTranslations,
      'es': esTranslations,
      'sw': swTranslations,
      'sv': svTranslations,
      'ta': taTranslations,
      'te': teTranslations,
      'th': thTranslations,
      'tr': trTranslations,
      'uk': ukTranslations,
      'ur': urTranslations,
      'vi': viTranslations,
      'zu': zuTranslations,
    };

    return allTranslations[langCode] ?? enTranslations;
  }

  String _t(String key) => _localizedStrings[key] ?? enTranslations[key] ?? key;

  // App title
  String get appTitle => _t('appTitle');

  // Tab bar
  String get tabWorldClock => _t('tabWorldClock');
  String get tabAlarm => _t('tabAlarm');
  String get tabStopwatch => _t('tabStopwatch');
  String get tabTimer => _t('tabTimer');

  // Common
  String get edit => _t('edit');
  String get done => _t('done');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get back => _t('back');
  String get ok => _t('ok');
  String get start => _t('start');
  String get stop => _t('stop');
  String get search => _t('search');

  // Alarm list screen
  String get alarms => _t('alarms');
  String get noAlarm => _t('noAlarm');
  String get settings => _t('settings');
  String get noAlarmData => _t('noAlarmData');
  String get tipKeepAppRunning => _t('tipKeepAppRunning');

  // Time remaining
  String daysText(int count) => '$count ${_t('days')}';
  String hoursText(int count) => '$count ${_t('hours')}';
  String minutesText(int count) => '$count ${_t('minutes')}';
  String get oneMinute => '1 ${_t('minute')}';
  String remaining(String time) => '${_t('remaining')} $time';
  String ringingIn(String time) => '${_t('ringingIn')} $time.';

  // Alarm ring screen
  String get alarm => _t('alarm');
  String get snooze => _t('snooze');
  String get slideToStop => _t('slideToStop');

  // Day names full
  String get monday => _t('monday');
  String get tuesday => _t('tuesday');
  String get wednesday => _t('wednesday');
  String get thursday => _t('thursday');
  String get friday => _t('friday');
  String get saturday => _t('saturday');
  String get sunday => _t('sunday');

  // Day names abbreviated
  String get mon => _t('mon');
  String get tue => _t('tue');
  String get wed => _t('wed');
  String get thu => _t('thu');
  String get fri => _t('fri');
  String get sat => _t('sat');
  String get sun => _t('sun');

  // Month names
  String get january => _t('january');
  String get february => _t('february');
  String get march => _t('march');
  String get april => _t('april');
  String get may => _t('may');
  String get june => _t('june');
  String get july => _t('july');
  String get august => _t('august');
  String get september => _t('september');
  String get october => _t('october');
  String get november => _t('november');
  String get december => _t('december');

  // Edit alarm screen
  String get editAlarm => _t('editAlarm');
  String get addAlarm => _t('addAlarm');
  String get deleteAlarm => _t('deleteAlarm');
  String get deleteAlarmConfirm => _t('deleteAlarmConfirm');
  String get repeat => _t('repeat');
  String get sound => _t('sound');
  String get snoozeDuration => _t('snoozeDuration');
  String get label => _t('label');
  String get never => _t('never');
  String get everyDay => _t('everyDay');
  String get weekdays => _t('weekdays');
  String get weekends => _t('weekends');
  String minutesValue(int count) => '$count ${_t('minutes')}';
  String get none => _t('none');
  String get systemRingtone => _t('systemRingtone');

  // Sound selector
  String get vibrate => _t('vibrate');
  String get songs => _t('songs');
  String get pickASong => _t('pickASong');
  String get systemRingtones => _t('systemRingtones');
  String get whenTimerEnds => _t('whenTimerEnds');

  // World clock screen
  String get worldClock => _t('worldClock');
  String get noWorldClocks => _t('noWorldClocks');
  String get chooseACity => _t('chooseACity');
  String get today => _t('today');

  // Timer screen
  String get timer => _t('timer');
  String get resume => _t('resume');
  String get pause => _t('pause');
  String get hoursLabel => _t('hoursLabel');
  String get minLabel => _t('minLabel');
  String get secLabel => _t('secLabel');

  // Stopwatch screen
  String get lap => _t('lap');
  String get reset => _t('reset');
  String lapNumber(int number) => '${_t('lap')} $number';

  // Settings screen
  String get timeFormat => _t('timeFormat');
  String get twentyFourHourFormat => _t('twentyFourHourFormat');
  String get supportAndFeedback => _t('supportAndFeedback');
  String get upgradePro => _t('upgradePro');
  String get proIntro => _t('proIntro');
  String get proPriceLabel => _t('proPriceLabel');
  String get proLifetimeNote => _t('proLifetimeNote');
  String get proBuyNow => _t('proBuyNow');
  String get guide => _t('guide');
  String get sendFeedback => _t('sendFeedback');
  String get about => _t('about');
  String get shareApp => _t('shareApp');
  String get rateApp => _t('rateApp');
  String get privacyPolicy => _t('privacyPolicy');
  String get privacyPolicyError => _t('privacyPolicyError');
  String get shareMessage => _t('shareMessage');

  // Notification strings
  String get alarmNotifications => _t('alarmNotifications');
  String get alarmNotificationsDesc => _t('alarmNotificationsDesc');
  String get dismiss => _t('dismiss');

  // AM/PM
  String get am => _t('am');
  String get pm => _t('pm');

  // Rating dialog
  String get ratingTitle => _t('ratingTitle');
  String get ratingContent => _t('ratingContent');
  String get submit => _t('submit');

  // Battery optimization dialog
  String get allowBackgroundRunning => _t('allowBackgroundRunning');
  String get batteryDialogContent => _t('batteryDialogContent');
  String get openAppSettings => _t('openAppSettings');
  String get close => _t('close');

  // Overlay permission dialog
  String get allowDisplayOverOtherApps => _t('allowDisplayOverOtherApps');
  String get overlayDialogContent => _t('overlayDialogContent');
  String get openSettings => _t('openSettings');

  // Guide screen
  String get guideIntro => _t('guideIntro');
  String get guideStep1Title => _t('guideStep1Title');
  String get guideStep1Sub1 => _t('guideStep1Sub1');
  String get guideStep1Sub2 => _t('guideStep1Sub2');
  String get guideStep1Sub3 => _t('guideStep1Sub3');
  String get guideStep2Title => _t('guideStep2Title');
  String get guideStep2Sub1 => _t('guideStep2Sub1');
  String get guideStep2Sub2 => _t('guideStep2Sub2');
  String get guideStep2Sub3 => _t('guideStep2Sub3');
  String get gotIt => _t('gotIt');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    if (locale.languageCode == 'zh') {
      return true;
    }
    return ['ar', 'bn', 'bg', 'ca', 'hr', 'cs', 'da', 'nl', 'en', 'et',
            'fi', 'fr', 'de', 'el', 'gu', 'he', 'hi', 'hu', 'is', 'id',
            'it', 'ja', 'kn', 'ko', 'lv', 'lt', 'ml', 'mr', 'no', 'nb',
            'fa', 'pl', 'pt', 'pa', 'ro', 'ru', 'sk', 'sl', 'es', 'sw',
            'sv', 'ta', 'te', 'th', 'tr', 'uk', 'ur', 'vi', 'zu']
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
