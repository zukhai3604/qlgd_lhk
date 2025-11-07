# Hướng dẫn sử dụng Mock Service cho Schedule Detail Page

## Tổng quan

Mock Service cho phép bạn test và debug Schedule Detail Page **không cần backend**. Điều này giúp:
- ✅ Test nhanh các trường hợp khác nhau
- ✅ Không phụ thuộc vào backend/database
- ✅ Dễ dàng thay đổi trạng thái để test UI logic
- ✅ Test offline hoàn toàn

## Cách sử dụng

### 1. Bật/Tắt Mock Mode

Mở file `detail_page.dart` và tìm dòng:

```dart
static const bool _enableMockMode = true; // TODO: Set false khi release
```

- `true` = Sử dụng Mock Service (không cần backend)
- `false` = Sử dụng Real Service (cần backend)

### 2. Test với các Scenario có sẵn

Khi Mock Mode được bật, bạn sẽ thấy **Debug Panel** ở đầu trang. Panel này có:

#### Quick Scenarios (Test nhanh):
- **PLANNED (No Att)**: Buổi học chưa điểm danh
- **PLANNED (With Att)**: Buổi học đã điểm danh, có thể kết thúc
- **TEACHING**: Đang dạy, đã điểm danh
- **DONE**: Đã hoàn thành, không thể chỉnh sửa
- **CANCELED**: Đã hủy, không thể chỉnh sửa

Bấm vào các button này để chuyển đổi scenario và reload trang.

#### Manual Control (Điều khiển thủ công):
- **Toggle Attendance**: Bật/tắt điểm danh
- **Set PLANNED/TEACHING/DONE**: Thay đổi status trực tiếp

### 3. Test các trường hợp cụ thể

#### Test Case 1: Kết thúc buổi học khi chưa điểm danh
1. Chọn scenario "PLANNED (No Att)"
2. Bấm nút "Kết thúc buổi học"
3. Kiểm tra: Dialog cảnh báo hiển thị, có nút "Điểm danh ngay"

#### Test Case 2: Kết thúc buổi học khi đã điểm danh
1. Chọn scenario "PLANNED (With Att)"
2. Bấm nút "Kết thúc buổi học"
3. Xác nhận trong dialog
4. Kiểm tra: Status chuyển thành "DONE", các input bị disable

#### Test Case 3: UI khi đã hoàn thành
1. Chọn scenario "DONE"
2. Kiểm tra:
   - Status chip hiển thị "Đã hoàn thành" (màu xanh)
   - Nút "Kết thúc buổi học" không hiển thị
   - Nút "Lưu" chuyển thành "Đã kết thúc buổi học" (disabled)
   - Các input (thêm nội dung, ghi chú) bị disable

#### Test Case 4: UI khi đã hủy
1. Chọn scenario "CANCELED"
2. Kiểm tra:
   - Status chip hiển thị "Đã hủy" (màu đỏ)
   - Các input bị disable
   - Không có nút "Kết thúc buổi học"

### 4. Sử dụng sessionId để tự động chọn scenario

Khi mở trang với sessionId khác nhau, Mock Service sẽ tự động chọn scenario:
- `sessionId % 5 == 0` → PLANNED (No Attendance)
- `sessionId % 5 == 1` → PLANNED (With Attendance)
- `sessionId % 5 == 2` → TEACHING (With Attendance)
- `sessionId % 5 == 3` → DONE
- `sessionId % 5 == 4` → CANCELED

Ví dụ:
- `/schedule/1` → Scenario 1 (PLANNED - No Att)
- `/schedule/2` → Scenario 2 (PLANNED - With Att)
- `/schedule/3` → Scenario 3 (TEACHING)
- `/schedule/4` → Scenario 4 (DONE)
- `/schedule/5` → Scenario 5 (CANCELED)

### 5. Tùy chỉnh Mock Service

Nếu cần test các trường hợp đặc biệt, bạn có thể sửa trực tiếp trong `service_mock.dart`:

```dart
// Thay đổi mock data
_mockStatus = 'YOUR_STATUS';
_mockHasAttendance = true/false;
_mockNote = 'Your note';
_mockMaterials = [...];
```

Hoặc thêm method mới trong `LecturerScheduleServiceMock`:

```dart
void setupCustomScenario() {
  _mockStatus = 'PLANNED';
  _mockHasAttendance = true;
  // ... custom logic
}
```

## Lưu ý quan trọng

⚠️ **NHỚ TẮT MOCK MODE TRƯỚC KHI RELEASE!**

Trước khi deploy hoặc commit code, đảm bảo:
```dart
static const bool _enableMockMode = false;
```

## Debug Logs

Mock Service sẽ in ra console các thông tin debug:
- `🔧 Mock: Setup scenario - ...` - Khi setup scenario
- `🔧 Mock: Status changed to ...` - Khi thay đổi status
- `🔧 Mock: Attendance changed to ...` - Khi thay đổi attendance

Kiểm tra console để theo dõi các thay đổi.

## Troubleshooting

### Mock Service không hoạt động?
1. Kiểm tra `_enableMockMode = true`
2. Kiểm tra import `service_mock.dart`
3. Hot restart app (không phải hot reload)

### Debug Panel không hiển thị?
- Đảm bảo `_enableMockMode = true`
- Đảm bảo `_mockSvc != null`
- Kiểm tra code có gọi `_buildMockDebugPanel()` trong build method

### Status không cập nhật sau khi thay đổi?
- Gọi `_load()` sau khi thay đổi mock state
- Hoặc bấm nút scenario trong Debug Panel (tự động reload)

## Ví dụ sử dụng

```dart
// Trong detail_page.dart, initState:
if (_enableMockMode) {
  _svc = LecturerScheduleServiceMock();
  final mockSvc = _svc as LecturerScheduleServiceMock;
  
  // Setup scenario dựa trên sessionId
  mockSvc.setupScenarioPlannedWithAttendance();
  
  // Hoặc setup thủ công
  mockSvc.setMockStatus('TEACHING');
  mockSvc.setMockHasAttendance(true);
}
```

## Kết luận

Mock Service giúp bạn:
- ✅ Test nhanh các trường hợp khác nhau
- ✅ Debug UI logic mà không cần backend
- ✅ Phát triển offline
- ✅ Dễ dàng reproduce bugs

Chúc bạn test vui vẻ! 🎉

