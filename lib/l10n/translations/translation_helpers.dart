import 'en.dart';

Map<String, String> mergeTranslations(Map<String, String> translations) {
  return {
    ...enTranslations,
    ...translations,
  };
}
