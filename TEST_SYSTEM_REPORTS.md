# 🎯 Hướng dẫn Test Hệ thống Báo cáo

## 📋 Checklist Backend

### 1. **Chạy Seeder tạo dữ liệu mẫu**
```bash
docker exec laradock-workspace-1 php artisan db:seed --class=SystemReportSeeder
```

✅ Kết quả mong đợi: "✅ Đã tạo 7 báo cáo hệ thống mẫu"

### 2. **Kiểm tra Database**
Vào phpMyAdmin hoặc MySQL client, check:
- Bảng `system_reports`: phải có 7 records
- Bảng `system_report_comments`: phải có comments
- Bảng `system_report_attachments`: phải có attachments cho báo cáo CRITICAL

### 3. **Test API endpoints** (dùng Postman/Thunder Client)

**Lấy token admin:**
```bash
POST http://localhost:8888/api/login
{
  "email": "admin@tlu.edu.vn",
  "password": "password"
}
```

**Danh sách báo cáo:**
```bash
GET http://localhost:8888/api/admin/reports
Authorization: Bearer {token}
```

**Thống kê:**
```bash
GET http://localhost:8888/api/admin/reports/statistics
Authorization: Bearer {token}
```

**Chi tiết báo cáo:**
```bash
GET http://localhost:8888/api/admin/reports/1
Authorization: Bearer {token}
```

**Cập nhật trạng thái:**
```bash
PATCH http://localhost:8888/api/admin/reports/1/status
Authorization: Bearer {token}
{
  "status": "IN_PROGRESS"
}
```

**Thêm comment:**
```bash
POST http://localhost:8888/api/admin/reports/1/comments
Authorization: Bearer {token}
{
  "content": "Đang xử lý vấn đề này"
}
```

---

## 📱 Checklist Frontend (Flutter)

### 1. **Hot Restart ứng dụng**
```bash
# Trong terminal Flutter, nhấn:
R    # Hot Restart (không phải r - hot reload)
```
HOẶC
```bash
cd d:\qlgd_lhk\frontend
flutter run
```

### 2. **Test Navigation**
- [ ] Đăng nhập với tài khoản admin
- [ ] Vào Admin Dashboard
- [ ] Nhấn nút "Báo cáo hệ thống" 🐛
- [ ] Màn hình danh sách báo cáo phải load thành công

### 3. **Test Danh sách Báo cáo**
- [ ] Hiển thị 4 card thống kê ở trên (Tổng số, Mới, Đang xử lý, Nghiêm trọng)
- [ ] Hiển thị filter chips (Tất cả, Mới, Đang xử lý, v.v.)
- [ ] Hiển thị danh sách 7 báo cáo
- [ ] Mỗi card hiển thị:
  - Severity badge (màu đúng: Nghiêm trọng=đỏ, Cao=cam, v.v.)
  - Category badge
  - Status badge
  - Tiêu đề
  - Mô tả (2 dòng)
  - Người báo cáo
  - Thời gian (tương đối: "2 giờ trước", "3 ngày trước")

### 4. **Test Filters**
- [ ] Nhấn "Mới" → Chỉ hiển thị báo cáo status=NEW
- [ ] Nhấn "Đang xử lý" → Chỉ hiển thị status=IN_PROGRESS
- [ ] Nhấn "Bug" → Chỉ hiển thị category=BUG
- [ ] Nhấn "Nghiêm trọng" → Chỉ hiển thị severity=CRITICAL
- [ ] Nhấn "Tất cả" → Hiển thị lại toàn bộ

### 5. **Test Chi tiết Báo cáo**
- [ ] Nhấn vào 1 báo cáo → Chuyển sang trang chi tiết
- [ ] Hiển thị đầy đủ:
  - Header card với severity icon
  - Thông tin người báo cáo, email, loại, thời gian
  - Mô tả chi tiết
  - File đính kèm (nếu có)
  - Các nút cập nhật trạng thái
  - Danh sách comments
  - Form thêm comment

### 6. **Test Cập nhật Trạng thái**
- [ ] Chọn báo cáo có status=NEW
- [ ] Nhấn nút "Bắt đầu xử lý"
- [ ] Thông báo "Đã cập nhật trạng thái: IN_PROGRESS"
- [ ] Trạng thái thay đổi, hiển thị nút "Đã giải quyết"
- [ ] Nhấn "Đã giải quyết" → Chuyển sang RESOLVED
- [ ] Nhấn "Đóng báo cáo" → Chuyển sang CLOSED
- [ ] Nhấn "Mở lại" → Chuyển lại IN_PROGRESS

### 7. **Test Thêm Comment**
- [ ] Nhập nội dung vào ô "Thêm phản hồi"
- [ ] Nhấn "Gửi phản hồi"
- [ ] Loading indicator hiển thị
- [ ] Thông báo "Đã thêm comment"
- [ ] Comment mới xuất hiện trong danh sách
- [ ] Hiển thị tên admin, thời gian, nội dung

### 8. **Test File đính kèm**
- [ ] Báo cáo có severity=CRITICAL phải có file đính kèm
- [ ] Nhấn icon "Mở file" → Mở trình duyệt/app xem ảnh

### 9. **Test Pagination** (nếu có >20 báo cáo)
- [ ] Hiển thị "Trang X / Y" ở dưới
- [ ] Nút Previous/Next hoạt động
- [ ] Load đúng trang

### 10. **Test Refresh**
- [ ] Nhấn icon refresh ở AppBar
- [ ] Dữ liệu load lại
- [ ] Thống kê cập nhật

---

## 🐛 Các lỗi thường gặp

### Backend
❌ **Lỗi: "Class 'SystemReportSeeder' not found"**
✅ Fix: Chạy `docker exec laradock-workspace-1 composer dump-autoload`

❌ **Lỗi: "SQLSTATE[23000]: Integrity constraint violation"**
✅ Fix: Đảm bảo đã có user admin và giảng viên trong database

### Frontend
❌ **Lỗi: "Unknown route name: admin_reports"**
✅ Fix: Hot Restart (nhấn R) hoặc restart app

❌ **Lỗi: "Failed to load reports: 401"**
✅ Fix: Kiểm tra token đã được lưu, AuthInterceptor đã inject đúng

❌ **Lỗi: "Exception: A RenderFlex overflowed by X pixels"**
✅ Fix: Thêm SingleChildScrollView hoặc Expanded

❌ **Lỗi: "The method 'copyWith' isn't defined for the type"**
✅ Fix: Check ReportsFilter class có method copyWith

---

## ✅ Kết quả mong đợi

Sau khi test xong, bạn sẽ có:
1. ✅ Hệ thống quản lý báo cáo hoàn chỉnh
2. ✅ 7 báo cáo mẫu với đủ loại status, severity, category
3. ✅ Giao diện đẹp, responsive, smooth
4. ✅ Filters hoạt động tốt
5. ✅ Cập nhật trạng thái real-time
6. ✅ Comments thread hoạt động
7. ✅ File đính kèm mở được

---

## 🎓 Bonus: Tính năng có thể mở rộng

1. **Gán người xử lý** - Assign report cho admin cụ thể
2. **Priority tags** - Thêm tag quan trọng/khẩn cấp
3. **Email notification** - Gửi email khi có báo cáo mới
4. **Export Excel** - Xuất danh sách báo cáo
5. **Chart dashboard** - Biểu đồ thống kê theo thời gian
6. **Search** - Tìm kiếm theo keyword
7. **SLA tracking** - Theo dõi thời gian xử lý

---

Chúc bạn test thành công! 🚀
