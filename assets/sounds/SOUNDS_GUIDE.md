# Hướng dẫn thêm file âm thanh báo thức

## Danh sách âm thanh cần thiết

App sử dụng các âm thanh sau (tương ứng với lựa chọn trong AlarmModel):

### Tên file (định dạng: MP3)

Đặt tất cả các file vào thư mục `assets/sounds/` với tên chính xác:

1. **radar.mp3** - Âm thanh Radar (mặc định)
2. **apex.mp3** - Âm thanh Apex
3. **beacon.mp3** - Âm thanh Beacon
4. **bulletin.mp3** - Âm thanh Bulletin
5. **chimes.mp3** - Âm thanh Chimes
6. **circuit.mp3** - Âm thanh Circuit
7. **constellation.mp3** - Âm thanh Constellation
8. **cosmic.mp3** - Âm thanh Cosmic
9. **crystals.mp3** - Âm thanh Crystals
10. **hillside.mp3** - Âm thanh Hillside
11. **illuminate.mp3** - Âm thanh Illuminate
12. **night_owl.mp3** - Âm thanh Night Owl
13. **opening.mp3** - Âm thanh Opening
14. **playtime.mp3** - Âm thanh Playtime
15. **presto.mp3** - Âm thanh Presto
16. **reflection.mp3** - Âm thanh Reflection
17. **ripples.mp3** - Âm thanh Ripples
18. **sencha.mp3** - Âm thanh Sencha
19. **silk.mp3** - Âm thanh Silk
20. **stargaze.mp3** - Âm thanh Stargaze
21. **summit.mp3** - Âm thanh Summit
22. **twinkle.mp3** - Âm thanh Twinkle
23. **uplift.mp3** - Âm thanh Uplift
24. **waves.mp3** - Âm thanh Waves

## Cách thêm file âm thanh

### Phương pháp 1: Từ thiết bị iPhone/iOS
Nếu bạn có iPhone, copy các file âm thanh mặc định:
```
/System/Library/Audio/UISounds/
```

### Phương pháp 2: Tải từ Internet
Tìm và tải các âm thanh tương tự từ:
- [FreeSound.org](https://freesound.org/)
- [Zapsplat](https://www.zapsplat.com/)
- [Mixkit](https://mixkit.co/free-sound-effects/)

### Phương pháp 3: Sử dụng âm thanh Windows
Copy từ thư mục Windows sounds:
```powershell
# Ví dụ copy một số âm thanh Windows
Copy-Item "C:\Windows\Media\Alarm01.wav" "assets\sounds\radar.mp3"
Copy-Item "C:\Windows\Media\Alarm02.wav" "assets\sounds\apex.mp3"
Copy-Item "C:\Windows\Media\Alarm03.wav" "assets\sounds\beacon.mp3"
```

## Yêu cầu kỹ thuật

- **Định dạng**: MP3 (khuyến nghị) hoặc WAV
- **Tên file**: Phải viết thường (lowercase), không dấu cách
- **Kích thước**: Tốt nhất dưới 2MB mỗi file
- **Độ dài**: 5-30 giây (sẽ được loop)
- **Chất lượng**: 128kbps - 320kbps

## Cấu trúc thư mục

```
assets/
  sounds/
    radar.mp3
    apex.mp3
    beacon.mp3
    ... (các file khác)
```

## Kiểm tra

Sau khi thêm file âm thanh:
1. Chạy `flutter pub get`
2. Restart app
3. Tạo báo thức và chọn âm thanh
4. Test báo thức

## Lưu ý

- Nếu file âm thanh không tồn tại, app sẽ in lỗi trong console nhưng vẫn hoạt động (chỉ có rung và notification)
- Tên âm thanh trong code được convert sang lowercase tự động
- Ví dụ: "Radar" → tìm file "radar.mp3"
