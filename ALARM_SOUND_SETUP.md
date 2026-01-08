# Hướng dẫn cài đặt Alarm Sound

## ⚠️ QUAN TRỌNG: Thêm file âm thanh báo thức

App cần một file âm thanh để phát khi báo thức kêu. Bạn cần thêm file âm thanh vào project.

### Cách 1: Tải âm thanh miễn phí

1. **Tải file âm thanh MP3 từ các nguồn miễn phí:**
   - [FreeSound.org](https://freesound.org/search/?q=alarm+clock)
   - [Mixkit](https://mixkit.co/free-sound-effects/alarm/)
   - [Zapsplat](https://www.zapsplat.com/sound-effect-category/alarms/)

2. **Đổi tên file thành:** `alarm_sound.mp3`

3. **Sao chép file vào thư mục:** `assets/sounds/alarm_sound.mp3`

### Cách 2: Sử dụng file âm thanh có sẵn

Nếu bạn đã có file âm thanh MP3 trên máy:

```powershell
# Copy file vào project
Copy-Item "đường_dẫn_file_của_bạn.mp3" "c:\flutter_application\alarm\assets\sounds\alarm_sound.mp3"
```

### Cách 3: Tạo âm thanh đơn giản bằng Windows

Bạn có thể tạm thời sử dụng âm thanh hệ thống Windows:

```powershell
Copy-Item "C:\Windows\Media\Alarm01.wav" "c:\flutter_application\alarm\assets\sounds\alarm_sound.mp3"
```

## Tính năng khi báo thức kêu

✅ **Âm thanh**: Phát âm thanh từ file `alarm_sound.mp3` (lặp lại liên tục)  
✅ **Rung**: Điện thoại sẽ rung theo pattern (500ms nghỉ, 1000ms rung)  
✅ **Màn hình báo thức**: Hiển thị màn hình toàn màn hình với 2 nút:
   - **Snooze**: Báo lại sau 5 phút
   - **Dismiss**: Tắt báo thức

## Test báo thức

Để test nhanh, hãy tạo một báo thức với thời gian 1-2 phút từ bây giờ.

## Nếu không có file âm thanh

App vẫn hoạt động, nhưng:
- Chỉ có âm thanh notification mặc định của hệ thống
- Vẫn có rung và màn hình báo thức
- Console sẽ in lỗi: "Could not play custom alarm sound"

## Lưu ý

- File âm thanh nên có độ dài ít nhất 5-10 giây
- Định dạng: MP3 hoặc WAV
- Kích thước khuyến nghị: dưới 5MB
- File sẽ được phát lặp lại cho đến khi bạn dismiss
