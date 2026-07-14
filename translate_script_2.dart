import 'dart:io';
import 'dart:convert';

const texts = {
  'proNoPurchasesFound': 'Không tìm thấy giao dịch mua nào!',
  'proActivated': 'Đã kích hoạt Pro thành công!',
  'proActivatedStatus': 'Đã kích hoạt Pro',
  'upgradePro': 'Nâng cấp Pro',
};

const fallbackTexts = {
  'proNoPurchasesFound': 'No purchases found!',
  'proActivated': 'Pro activated successfully!',
  'proActivatedStatus': 'Pro Activated',
  'upgradePro': 'Upgrade Pro',
};

Future<String> translateText(String key, String targetLang) async {
  if (targetLang == 'vi') return texts[key]!;
  if (targetLang == 'en') return fallbackTexts[key]!;
  
  String lang = targetLang;
  if (lang == 'zh_cn') lang = 'zh-cn';
  if (lang == 'zh_tw') lang = 'zh-tw';

  final text = texts[key]!;
  final uri = Uri.parse('https://translate.googleapis.com/translate_a/single?client=gtx&sl=vi&tl=$lang&dt=t&q=${Uri.encodeComponent(text)}');
  try {
    final request = await HttpClient().getUrl(uri);
    final response = await request.close();
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final jsonResponse = jsonDecode(body);
      final chunks = jsonResponse[0] as List;
      return chunks.map((c) => c[0] as String).join('');
    }
  } catch (_) {}
  
  final lingvaUri = Uri.parse('https://lingva.ml/api/v1/vi/$lang/${Uri.encodeComponent(text)}');
  try {
    final request = await HttpClient().getUrl(lingvaUri);
    final response = await request.close();
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final jsonResponse = jsonDecode(body);
      return jsonResponse['translation'];
    }
  } catch (_) {}

  return fallbackTexts[key]!;
}

void main() async {
  final dir = Directory('lib/l10n/translations');
  final files = dir.listSync();

  for (final entity in files) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart') || entity.path.endsWith('translation_helpers.dart')) continue;

    final filename = entity.uri.pathSegments.last;
    final langCode = filename.replaceAll('.dart', '');

    final content = await entity.readAsString();
    
    // We want to add only missing keys
    final missingKeys = texts.keys.where((k) => !content.contains("'$k'") && !content.contains('"$k"')).toList();
    
    if (missingKeys.isEmpty) {
      print('Skipping $filename');
      continue;
    }

    print('Translating $missingKeys for $langCode...');
    final translations = <String>[];
    for (final key in missingKeys) {
      final translated = await translateText(key, langCode);
      final escaped = translated.replaceAll("'", "\\'");
      translations.add("  '$key': '$escaped',");
    }

    final lines = content.split('\n');
    bool inserted = false;
    for (int i = lines.length - 1; i >= 0; i--) {
      if (lines[i].contains('});') || lines[i].contains('};') || lines[i].trim() == '}' || lines[i].trim() == '})') {
        lines.insertAll(i, translations);
        inserted = true;
        break;
      }
    }
    
    if (inserted) {
      await entity.writeAsString(lines.join('\n'));
      print('Updated $filename');
    }
    
    await Future.delayed(Duration(milliseconds: 300));
  }
  print('Done!');
}
