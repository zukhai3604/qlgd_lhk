# 🚀 Hướng dẫn Test Mock Service - Schedule Detail Page

## ✅ Mock Mode đã được BẬT

File `detail_page.dart` đã có:
```dart
static const bool _enableMockMode = true;
```

## 📱 Cách Test

### Bước 1: Mở Schedule Detail Page

Có nhiều cách để mở trang:

**Cách 1: Từ Schedule Page**
1. Mở app Flutter
2. Navigate đến tab "Lịch" (Schedule)
3. Bấm vào bất kỳ buổi học nào

**Cách 2: Direct URL (nếu dùng GoRouter)**
- Navigate đến: `/schedule/1` (hoặc bất kỳ ID nào)
- SessionId sẽ tự động chọn scenario:
  - ID 1, 6, 11... → PLANNED (No Attendance)
  - ID 2, 7, 12... → PLANNED (With Attendance)  
  - ID 3, 8, 13... → TEACHING (With Attendance)
  - ID 4, 9, 14... → DONE
  - ID 5, 10, 15... → CANCELED

### Bước 2: Sử dụng Debug Panel

Khi mở Schedule Detail Page, bạn sẽ thấy **Debug Panel** màu cam ở đầu trang với:

#### 🔍 Thông tin hiện tại:
- Current Status
- Has Attendance
- Is Editable
- Can End Session

#### ⚡ Quick Scenarios:
- **PLANNED (No Att)**: Test trường hợp chưa điểm danh
- **PLANNED (With Att)**: Test trường hợp đã điểm danh, có thể kết thúc
- **TEACHING**: Test trường hợp đang dạy
- **DONE**: Test trường hợp đã hoàn thành
- **CANCELED**: Test trường hợp đã hủy

#### 🎮 Manual Control:
- **Toggle Attendance**: Bật/tắt điểm danh
- **Set PLANNED/TEACHING/DONE**: Thay đổi status

### Bước 3: Test các chức năng

#### ✅ Test Case 1: Kết thúc buổi học khi chưa điểm danh
1. Bấm button "PLANNED (No Att)" trong Debug Panel
2. Bấm nút "Kết thúc buổi học" (màu cam)
3. **Kỳ vọng**: 
   - Dialog cảnh báo hiển thị
   - Có nút "Điểm danh ngay"
   - Có nút "Hủy"

#### ✅ Test Case 2: Kết thúc buổi học khi đã điểm danh
1. Bấm button "PLANNED (With Att)" trong Debug Panel
2. Bấm nút "Kết thúc buổi học"
3. Xác nhận trong dialog
4. **Kỳ vọng**:
   - Status chip chuyển thành "Đã hoàn thành" (màu xanh)
   - Nút "Kết thúc buổi học" biến mất
   - Nút "Lưu" chuyển thành "Đã kết thúc buổi học" (disabled)
   - Các input bị disable

#### ✅ Test Case 3: UI khi đã hoàn thành
1. Bấm button "DONE" trong Debug Panel
2. **Kỳ vọng**:
   - Status chip: "Đã hoàn thành" (màu xanh)
   - Không có nút "Kết thúc buổi học"
   - Nút "Lưu" → "Đã kết thúc buổi học" (disabled)
   - Tất cả input bị disable

#### ✅ Test Case 4: UI khi đã hủy
1. Bấm button "CANCELED" trong Debug Panel
2. **Kỳ vọng**:
   - Status chip: "Đã hủy" (màu đỏ)
   - Không có nút "Kết thúc buổi học"
   - Tất cả input bị disable

#### ✅ Test Case 5: Toggle Attendance
1. Bấm "PLANNED (No Att)"
2. Bấm "Toggle Attendance" → Attendance = YES
3. Bấm "Kết thúc buổi học" → Có thể kết thúc được
4. Bấm "Toggle Attendance" → Attendance = NO
5. Bấm "Kết thúc buổi học" → Hiển thị dialog cảnh báo

## 🎯 Tips

1. **Hot Reload**: Sau khi thay đổi code, dùng Hot Reload (R) để cập nhật nhanh
2. **Hot Restart**: Nếu có vấn đề, dùng Hot Restart (Shift+R)
3. **Console Logs**: Xem console để thấy debug logs từ Mock Service
4. **Test nhiều scenarios**: Thử tất cả các scenarios để đảm bảo UI hoạt động đúng

## ⚠️ Lưu ý

- Mock Mode đang BẬT → Không cần backend
- Tất cả data là mock → Không lưu vào database
- Debug Panel chỉ hiển thị khi Mock Mode = true
- **Nhớ tắt Mock Mode** (`_enableMockMode = false`) trước khi release!

## 🐛 Troubleshooting

### Debug Panel không hiển thị?
- Kiểm tra `_enableMockMode = true`
- Hot Restart app (không phải Hot Reload)

### Status không cập nhật?
- Bấm lại button scenario trong Debug Panel
- Hoặc bấm "Toggle Attendance" để trigger reload

### App crash?
- Kiểm tra console logs
- Đảm bảo đã import `service_mock.dart`
- Hot Restart app

---

**Chúc bạn test vui vẻ! 🎉**

Nếu có vấn đề, kiểm tra console logs hoặc báo lại cho tôi!

