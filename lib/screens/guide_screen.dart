import 'package:flutter/cupertino.dart';
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
                'Hướng dẫn',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Để báo thức hoạt động tốt, vui lòng làm theo các bước sau:',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildGuideItem(
                    number: '1',
                    title: 'Cấp quyền hiển thị trên các ứng dụng khác (Overlay)',
                    steps: [
                      'Vào Cài đặt > Ứng dụng > Clock OS 26',
                      'Chọn "Hiển thị trên các ứng dụng khác"',
                      'Bật quyền này để app có thể hiển thị báo thức khi màn hình khóa.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildGuideItem(
                    number: '2',
                    title: 'Cấp quyền chạy dưới nền',
                    steps: [
                      'Vào Cài đặt > Ứng dụng > Clock OS 26',
                      'Chọn "Quyền" > "Chạy dưới nền"',
                      'Cho phép để app tiếp tục chạy khi không sử dụng.',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildGuideItem(
                    number: '3',
                    title: 'Không tắt đa nhiệm ứng dụng',
                    steps: [
                      'Sau khi đặt báo thức, không tắt app trong đa nhiệm.',
                      'Để đảm bảo báo thức đổ chuông đúng giờ.',
                      'App cần chạy nền để kích hoạt báo thức.',
                    ],
                  ),
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
                  color: CupertinoColors.systemBlue,
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
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.map((step) => Padding(
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
                        step,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}