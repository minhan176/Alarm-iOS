import os
import re
import json
import urllib.request
import urllib.parse
import time

TEXTS = {
    "proOneTime": "1 lần • mãi mãi",
    "proRestoreDesc": "Sau khi mua, Pro sẽ được mở vĩnh viễn trên thiết bị này. Nếu đăng nhập lại cùng tài khoản cửa hàng đã dùng để mua ở thiết bị khác, bạn chỉ cần nhấn Khôi phục mua hàng.",
    "proRestoreBtn": "Khôi phục mua hàng"
}

def translate_text(text, target_lang):
    if target_lang == "vi":
        return text
    # some locale fixes
    if target_lang == "zh_cn": target_lang = "zh-cn"
    if target_lang == "zh_tw": target_lang = "zh-tw"
    
    url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=vi&tl=" + target_lang + "&dt=t&q=" + urllib.parse.quote(text)
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode())
            return "".join([x[0] for x in result[0]])
    except Exception as e:
        print(f"Error translating to {target_lang}: {e}")
        return text

dir_path = "lib/l10n/translations"
for filename in os.listdir(dir_path):
    if not filename.endswith(".dart") or filename == "translation_helpers.dart":
        continue
        
    lang_code = filename.replace(".dart", "")
    filepath = os.path.join(dir_path, filename)
    
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()
        
    # Check if already added
    if "'proOneTime'" in content or '"proOneTime"' in content:
        print(f"Skipping {filename}")
        continue
        
    print(f"Translating for {lang_code}...")
    translations = []
    for key, val in TEXTS.items():
        translated = translate_text(val, lang_code).replace("'", "\\'")
        translations.append(f"  '{key}': '{translated}',")
        
    lines = content.split('\n')
    # find last closing brace
    for i in range(len(lines)-1, -1, -1):
        if '};' in lines[i] or '}' in lines[i]:
            lines.insert(i, '\n'.join(translations))
            break
            
    with open(filepath, "w", encoding="utf-8") as f:
        f.write('\n'.join(lines))
        
    time.sleep(0.5)

print("Done!")
