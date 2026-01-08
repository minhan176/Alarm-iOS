# Hướng dẫn Test Báo thức

## Chuẩn bị

1. **Thêm file âm thanh** (xem [ALARM_SOUND_SETUP.md](ALARM_SOUND_SETUP.md))
   ```powershell
   # Ví dụ: Copy âm thanh Windows
   Copy-Item "C:\Windows\Media\Alarm01.wav" "c:\flutter_application\alarm\assets\sounds\alarm_sound.mp3"
   ```

2. **Chạy app**
   ```bash
   flutter run
   ```

## Test báo thức nhanh

1. **Mở app** → Tab "Alarm"
2. **Nhấn nút +** (góc trên bên phải)
3. **Đặt thời gian** 2 phút từ bây giờ
4. **Nhập tên** (tùy chọn): "Test Alarm"
5. **Nhấn Save**
6. **Đợi 2 phút...**

## Kết quả mong đợi

Khi đến giờ báo thức:

1. ✅ **Notification hiển thị** với priority cao
2. ✅ **Điện thoại rung** (pattern: nghỉ 500ms → rung 1000ms)
3. ✅ **Âm thanh phát** liên tục (loop)
4. ✅ **Màn hình báo thức mở** toàn màn hình với animation

### Màn hình báo thức có:
- Icon báo thức với animation xoay và phóng to
- Tên báo thức
- Thời gian hiện tại
- **2 nút action:**
  - **Snooze**: Báo lại sau 5 phút
  - **Dismiss**: Tắt hoàn toàn

## Test các trường hợp

### Test 1: Báo thức không lặp
- Tạo báo thức cho 1 lần
- Sau khi kêu và dismiss → Báo thức tự tắt

### Test 2: Báo thức lặp lại
- Tạo báo thức
- Chọn các ngày: Mon, Tue, Wed, Thu, Fri
- Báo thức chỉ kêu vào các ngày đã chọn

### Test 3: Snooze
- Khi báo thức kêu, nhấn "Snooze"
- Báo thức sẽ kêu lại sau 5 phút
- Một dialog xác nhận sẽ hiển thị

### Test 4: Bật/Tắt nhanh
- Dùng switch bên cạnh báo thức để bật/tắt
- Khi tắt: Báo thức không kêu
- Khi bật: Báo thức được lên lịch lại

### Test 5: Xóa báo thức
- Vuốt sang trái trên báo thức
- Nhấn "Delete"
- Báo thức bị xóa và hủy lịch

## Debug

Nếu báo thức không kêu:

1. **Kiểm tra logs:**
   ```bash
   flutter logs
   ```
   
2. **Tìm messages:**
   - "Alarm scheduled: ..." → Báo thức đã được lên lịch
   - "Alarm triggered: ..." → Callback đã chạy
   - "Could not play custom alarm sound" → Thiếu file âm thanh

3. **Kiểm tra permissions:**
   - Settings → Apps → Alarm → Permissions
   - Đảm bảo có quyền: Notifications, Alarms & reminders

4. **Tắt Battery Optimization:**
   - Settings → Apps → Alarm → Battery
   - Chọn "Unrestricted"

## Troubleshooting

### Báo thức không kêu đúng giờ
- Kiểm tra quyền `SCHEDULE_EXACT_ALARM`
- Android 12+: Cần cấp quyền thủ công trong Settings

### Không có âm thanh
- Kiểm tra file `assets/sounds/alarm_sound.mp3` có tồn tại
- Kiểm tra volume điện thoại
- Xem console có lỗi "Could not play custom alarm sound"

### Không rung
- Kiểm tra điện thoại có bật rung
- Kiểm tra quyền VIBRATE trong AndroidManifest

### Màn hình không mở
- App có thể bị kill bởi hệ thống
- Cần tắt Battery Optimization
- Notification vẫn sẽ hiển thị

## Performance

- App đã tối ưu để chạy trong background
- Báo thức hoạt động ngay cả khi app đóng
- Tự động khôi phục sau khi reboot
