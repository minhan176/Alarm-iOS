import re

with open(r'C:\flutter_application\Alarm-iOS\lib\screens\sound_selector.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace the import
code = code.replace("import 'package:jbh_ringtone/jbh_ringtone.dart';", "")

# Replace the _loadSystemRingtones body
pattern = r'final jbhRingtone = JbhRingtone\(\);.*?for \(final sound in allSounds\) \{[^\}]+\}'
new_code = '''final List<dynamic> result = await _alarmChannel.invokeMethod('getSystemRingtones');
      final uniqueSounds = <String, dynamic>{};

      for (var item in result) {
        final uri = item['uri'] as String;
        final title = item['title'] as String;
        if (!uniqueSounds.containsKey(uri)) {
          uniqueSounds[uri] = {'displayTitle': title, 'uri': uri};
        }
      }'''

code = re.sub(pattern, new_code, code, flags=re.DOTALL)

# Since JbhRingtoneModel is no longer used, we need to map uniqueSounds.values properly inside setState
# Actually we can just create CustomRingtone directly if it exists, or just use dynamic.
# Wait, let's fix the class instead. Let's see how CustomRingtone is defined.
# I will just write it manually in Python
with open(r'C:\flutter_application\Alarm-iOS\lib\screens\sound_selector.dart', 'w', encoding='utf-8') as f:
    f.write(code)
