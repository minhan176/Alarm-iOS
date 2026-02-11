# Hướng dẫn sử dụng Alarm App

## Tính năng đã tích hợp

Ứng dụng báo thức đã được tích hợp với:
- ✅ **android_alarm_manager_plus**: Lên lịch báo thức chính xác
- ✅ **flutter_local_notifications**: Hiển thị thông báo báo thức

## Các tính năng chính

### 1. Tạo báo thức
- Nhấn nút "+" trên màn hình Alarm
- Chọn thời gian báo thức
- Đặt tên cho báo thức (tùy chọn)
- Chọn các ngày lặp lại (tùy chọn)
- Báo thức sẽ tự động được lên lịch khi bật

### 2. Chỉnh sửa báo thức
- Nhấn vào báo thức cần chỉnh sửa
- Thay đổi thông tin
- Báo thức sẽ tự động được cập nhật

### 3. Bật/Tắt báo thức
- Sử dụng công tắc bên cạnh mỗi báo thức
- Khi bật: Báo thức được lên lịch
- Khi tắt: Báo thức bị hủy

### 4. Xóa báo thức
- Vuốt sang trái trên báo thức
- Nhấn "Delete"
- Báo thức sẽ bị xóa và hủy lịch

## Quyền cần thiết (Android)

App yêu cầu các quyền sau:
- `RECEIVE_BOOT_COMPLETED`: Khôi phục báo thức sau khi khởi động lại
- `WAKE_LOCK`: Đánh thức thiết bị khi báo thức kêu
- `VIBRATE`: Rung khi báo thức kêu
- `SCHEDULE_EXACT_ALARM`: Lên lịch báo thức chính xác
- `POST_NOTIFICATIONS`: Hiển thị thông báo (Android 13+)
- `USE_FULL_SCREEN_INTENT`: Hiển thị báo thức toàn màn hình

## Cách hoạt động

1. **Lên lịch báo thức**:
   - Khi tạo hoặc bật báo thức, app sử dụng `AndroidAlarmManager` để lên lịch
   - Báo thức sẽ kêu đúng giờ ngay cả khi app đóng

2. **Hiển thị thông báo**:
   - Khi đến giờ báo thức, `FlutterLocalNotifications` hiển thị thông báo
   - Thông báo có độ ưu tiên cao với âm thanh và rung

3. **Báo thức lặp lại**:
   - Nếu chọn các ngày lặp lại, báo thức sẽ tự động kiểm tra và kêu vào các ngày đã chọn
   - Ví dụ: Chọn Thứ 2, 3, 4, 5, 6 để báo thức kêu vào các ngày trong tuần

4. **Khôi phục sau khởi động lại**:
   - Khi điện thoại khởi động lại, tất cả báo thức đã bật sẽ tự động được lên lịch lại

## Chạy ứng dụng

```bash
# Cài đặt dependencies
flutter pub get

# Chạy trên Android
flutter run
```

## Notes

- **SCHEDULE_EXACT_ALARM Permission**: On Android 12+, users may need to manually grant permission in Settings
- **Battery Optimization**: To ensure alarms work correctly, battery optimization for the app may need to be disabled
- **Do Not Disturb**: Alarms will still ring in Do Not Disturb mode thanks to `InterruptionLevel.critical`

## Testing

To test notification:
```dart
await AlarmService.showTestNotification();
```

## Cấu trúc code

```
lib/
  ├── models/
  │   └── alarm_model.dart         # Model dữ liệu báo thức
  ├── providers/
  │   └── alarm_provider.dart       # Quản lý state báo thức
  ├── services/
  │   └── alarm_service.dart        # Service lên lịch báo thức
  ├── screens/
  │   ├── alarm_list_screen.dart    # Màn hình danh sách báo thức
  │   ├── edit_alarm_screen.dart    # Màn hình chỉnh sửa báo thức
  │   ├── world_clock_screen.dart   # Màn hình đồng hồ thế giới
  │   ├── stopwatch_screen.dart     # Màn hình đồng hồ bấm giờ
  │   └── timer_screen.dart         # Màn hình đếm ngược
  └── main.dart                     # Entry point với bottom tab bar
```
