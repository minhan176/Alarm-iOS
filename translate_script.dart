import 'dart:io';
import 'dart:convert';

const texts = {
  'proOneTime': '1 lần • mãi mãi',
  'proRestoreDesc': 'Sau khi mua, Pro sẽ được mở vĩnh viễn trên thiết bị này. Nếu đăng nhập lại cùng tài khoản cửa hàng đã dùng để mua ở thiết bị khác, bạn chỉ cần nhấn Khôi phục mua hàng.',
  'proRestoreBtn': 'Khôi phục mua hàng',
};

// Fallback to English if translation fails to avoid empty/Vietnamese strings in other languages.
const fallbackTexts = {
  'proOneTime': '1 time • forever',
  'proRestoreDesc': 'Once purchased, Pro will be unlocked permanently on this device. If you sign in again with the same store account used for the purchase on another device, simply tap Restore Purchases.',
  'proRestoreBtn': 'Restore Purchases',
};

Future<String> translateText(String key, String targetLang) async {
  if (targetLang == 'vi') return texts[key]!;
  if (targetLang == 'en') return fallbackTexts[key]!;
  
  String lang = targetLang;
  if (lang == 'zh_cn') lang = 'zh-cn';
  if (lang == 'zh_tw') lang = 'zh-tw';

  // Try Google Translate API first
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
  
  // Try Lingva API
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
    if (content.contains("'proOneTime'") || content.contains('"proOneTime"')) {
      print('Skipping $filename');
      continue;
    }

    print('Translating for $langCode...');
    final translations = <String>[];
    for (final entry in texts.entries) {
      final translated = await translateText(entry.key, langCode);
      final escaped = translated.replaceAll("'", "\\'");
      translations.add("  '${entry.key}': '$escaped',");
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
    } else {
      print('Failed to find insertion point for $filename');
    }
    
    await Future.delayed(Duration(milliseconds: 300));
  }
  print('Done!');
}
