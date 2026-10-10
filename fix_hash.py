import re

path = r'C:\flutter_application\Alarm-iOS\lib\services\alarm_service.dart'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

stable_id_code = '''
  // Generate a stable 32-bit integer ID from a string
  static int getStableId(String id) {
    var parsed = int.tryParse(id);
    if (parsed != null) {
      return parsed & 0x7FFFFFFF;
    }
    int hash = 5381;
    for (int i = 0; i < id.length; i++) {
      hash = ((hash << 5) + hash) + id.codeUnitAt(i);
    }
    return hash.abs() & 0x7FFFFFFF;
  }
'''

if 'static int getStableId' not in content:
    content = content.replace('class AlarmService {', 'class AlarmService {' + stable_id_code)

content = content.replace('alarm.id.hashCode', 'AlarmService.getStableId(alarm.id)')
content = content.replace('alarmId.hashCode', 'AlarmService.getStableId(alarmId)')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
