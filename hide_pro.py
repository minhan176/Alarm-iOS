import re

def hide_upgrade_pro_in_settings():
    path = r'C:\flutter_application\Alarm-iOS\lib\screens\settings_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # In settings_screen.dart, the Upgrade Pro section is a Container pushing UpgradeProScreen.
    # Let's just hide the container by wrapping it in if (false) or returning empty SizedBox.
    # We can replace the padding containing UPGRADE_PRO and the Container after it.
    # Let's find: Padding(\n padding: const EdgeInsets.only(\n left: 32,\n bottom: 8,\n ),\n child: Text(\n AppLocalizations.of(context).UPGRADE_PRO,
    old_code = r'''Padding(
                          padding: const EdgeInsets.only(
                            left: 32,
                            bottom: 8,
                          ),
                          child: Text(
                            AppLocalizations.of(context).UPGRADE_PRO,
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),'''
    
    new_code = r'''if(false) Padding(
                          padding: const EdgeInsets.only(
                            left: 32,
                            bottom: 8,
                          ),
                          child: Text(
                            AppLocalizations.of(context).UPGRADE_PRO,
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),'''
    
    content = content.replace(old_code, new_code)
    
    # Hide the Container
    # The container starts with Container(\n margin: const EdgeInsets.only(\n left: 16,\n right: 16,\n bottom: 16,\n ),\n decoration: BoxDecoration(
    old_container = r'''Container(
                        margin: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),'''
    
    new_container = r'''if(false) Container(
                        margin: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),'''
                          
    content = content.replace(old_container, new_container)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def hide_in_alarm_list():
    path = r'C:\flutter_application\Alarm-iOS\lib\screens\alarm_list_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    old_code = r'''if (!Provider.of<SettingsProvider>(
                              context,
                            ).isProUnlocked)'''
    new_code = r'''if (false)'''
    content = content.replace(old_code, new_code)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

def hide_in_world_clock():
    path = r'C:\flutter_application\Alarm-iOS\lib\screens\world_clock_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    old_code = r'''if (!Provider.of<SettingsProvider>(
                            context,
                          ).isProUnlocked)'''
    new_code = r'''if (false)'''
    content = content.replace(old_code, new_code)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

hide_upgrade_pro_in_settings()
hide_in_alarm_list()
hide_in_world_clock()
