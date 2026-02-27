import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_buttons.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomNavBar(
              backgroundColor: const Color(0xFF1C1C1E),
              leading: NavTextIconButton(
                icon: CupertinoIcons.chevron_left,
                text: 'Back',
                iconColor: CupertinoColors.white,
                textColor: CupertinoColors.white,
                onPressed: () => Navigator.of(context).pop(),
              ),
              middle: const Text(
                'Guide',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'For the alarm to work properly, we recommend following these steps:',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildGuideItem(
                    number: '1',
                    title: 'Grant "Display Over Other Apps" permission',
                    steps: [
                      'Go to Settings → Apps → Clock OS 26',
                      'Select "Display over other apps"',
                      'Allow display over other apps',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildGuideItem(
                    number: '2',
                    title: 'Allow background battery usage',
                    steps: [
                      'Go to Settings → Apps → Clock OS 26',
                      'Select "App Battery Usage"',
                      'Manage battery usage → Allow battery usage in background',
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(                    
                    child: CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      color: CupertinoColors.systemOrange,
                      child: const Text(
                        'Got it',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem({
    required String number,
    required String title,
    required List<String> steps,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: CupertinoColors.systemOrange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: CupertinoColors.systemOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildStepWidgets(steps, number),
        ],
      ),
    );
  }

  List<Widget> _buildStepWidgets(List<String> steps, String number) {
    List<Widget> widgets = [];
    for (int i = 0; i < steps.length; i++) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '• ',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 14,
              ),
            ),
            Expanded(
              child: Text(
                steps[i],
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ));
      if ((number == '1' || number == '2') && i == 0) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(Image.asset('assets/images/app info.jpg'));
        widgets.add(const SizedBox(height: 8));
      }
      if (number == '1' && i == 1) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(Image.asset('assets/images/app info - overlay.jpg'));
        widgets.add(const SizedBox(height: 8));
      }
      if (number == '1' && i == 2) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(Image.asset('assets/images/overlay - on.jpg'));
        widgets.add(const SizedBox(height: 8));
      }
      if (number == '2' && i == 1) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(Image.asset('assets/images/app info - battery.jpg'));
        widgets.add(const SizedBox(height: 8));
      }
      if (number == '2' && i == 2) {
        widgets.add(const SizedBox(height: 8));
        widgets.add(Image.asset('assets/images/manage battery.jpg'));
        widgets.add(const SizedBox(height: 8));
        widgets.add(Image.asset('assets/images/allow battery.jpg'));
        widgets.add(const SizedBox(height: 8));
      }
    }
    return widgets;
  }
}