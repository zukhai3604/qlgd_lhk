# 📊 Hệ thống Quản lý Báo cáo - Tài liệu Tổng quan

## 🎯 Tổng quan

Hệ thống **Báo cáo Hệ thống** (System Reports) cho phép Admin quản lý các báo cáo lỗi, góp ý, và vấn đề từ người dùng một cách chuyên nghiệp.

---

## 🏗️ Kiến trúc

### Backend (Laravel 11)
```
backend/
├── app/
│   ├── Http/Controllers/Admin/
│   │   └── SystemReportController.php    # API endpoints
│   └── Models/
│       ├── SystemReport.php               # Model chính
│       ├── SystemReportComment.php        # Comments
│       └── SystemReportAttachment.php     # File đính kèm
├── database/
│   ├── migrations/
│   │   ├── *_create_system_reports_table.php
│   │   ├── *_create_system_report_comments_table.php
│   │   └── *_create_system_report_attachments_table.php
│   └── seeders/
│       └── SystemReportSeeder.php         # Dữ liệu mẫu
└── routes/
    └── api.php                            # Routes definition
```

### Frontend (Flutter + Riverpod)
```
frontend/lib/features/admin/
├── presentation/
│   └── system_report_providers.dart       # Riverpod providers
└── view/
    ├── admin_system_reports_page.dart     # Danh sách
    └── admin_report_detail_page.dart      # Chi tiết
```

---

## 📋 Database Schema

### `system_reports`
| Column | Type | Mô tả |
|--------|------|-------|
| id | bigint | Primary key |
| source_type | enum | GIANG_VIEN, DAO_TAO, GUEST |
| reporter_user_id | bigint | FK users (nullable) |
| contact_email | string | Email liên hệ |
| title | string(200) | Tiêu đề |
| description | text | Mô tả chi tiết |
| category | enum | BUG, FEEDBACK, DATA_ISSUE, PERFORMANCE, SECURITY, OTHER |
| severity | enum | LOW, MEDIUM, HIGH, CRITICAL |
| status | enum | NEW, IN_PROGRESS, RESOLVED, CLOSED |
| created_at | timestamp | Thời gian tạo |
| updated_at | timestamp | Thời gian cập nhật |
| closed_at | timestamp | Thời gian đóng |
| closed_by | bigint | FK users |

### `system_report_comments`
| Column | Type | Mô tả |
|--------|------|-------|
| id | bigint | Primary key |
| report_id | bigint | FK system_reports |
| author_user_id | bigint | FK users |
| body | text | Nội dung comment |
| created_at | timestamp | Thời gian tạo |

### `system_report_attachments`
| Column | Type | Mô tả |
|--------|------|-------|
| id | bigint | Primary key |
| report_id | bigint | FK system_reports |
| file_url | string | URL file |
| file_type | string(50) | MIME type |
| uploaded_by | bigint | FK users |
| uploaded_at | timestamp | Thời gian upload |

---

## 🔌 API Endpoints

### 1. **Danh sách báo cáo**
```http
GET /api/admin/reports
Authorization: Bearer {token}
Query params:
  - status: NEW|IN_PROGRESS|RESOLVED|CLOSED
  - severity: LOW|MEDIUM|HIGH|CRITICAL
  - category: BUG|FEEDBACK|DATA_ISSUE|PERFORMANCE|SECURITY|OTHER
  - page: số trang

Response:
{
  "data": [...],
  "current_page": 1,
  "last_page": 3,
  "total": 52
}
```

### 2. **Thống kê**
```http
GET /api/admin/reports/statistics
Authorization: Bearer {token}

Response:
{
  "total": 52,
  "by_status": {"NEW": 10, "IN_PROGRESS": 15, ...},
  "by_severity": {"CRITICAL": 5, "HIGH": 12, ...},
  "by_category": {"BUG": 20, "FEEDBACK": 15, ...},
  "recent": [...]
}
```

### 3. **Chi tiết báo cáo**
```http
GET /api/admin/reports/{id}
Authorization: Bearer {token}

Response:
{
  "data": {
    "id": 1,
    "title": "...",
    "description": "...",
    "reporter": {...},
    "attachments": [...],
    "comments": [...]
  }
}
```

### 4. **Cập nhật trạng thái**
```http
PATCH /api/admin/reports/{id}/status
Authorization: Bearer {token}
Body:
{
  "status": "IN_PROGRESS"
}

Response:
{
  "data": {...}
}
```

### 5. **Thêm comment**
```http
POST /api/admin/reports/{id}/comments
Authorization: Bearer {token}
Body:
{
  "content": "Đang xử lý..."
}

Response:
{
  "data": {
    "id": 10,
    "body": "Đang xử lý...",
    "author": {...}
  }
}
```

---

## 🎨 UI/UX Features

### Trang Danh sách (`AdminSystemReportsPage`)

**Header:**
- Title: "Báo cáo Hệ thống"
- Refresh button

**Statistics Cards:**
- Tổng số báo cáo
- Số báo cáo MỚI
- Số báo cáo ĐANG XỬ LÝ
- Số báo cáo NGHIÊM TRỌNG

**Filter Chips:**
- Tất cả
- Mới
- Đang xử lý
- Đã giải quyết
- Bug
- Nghiêm trọng

**Report Cards:**
Mỗi card hiển thị:
- Severity badge (màu sắc theo mức độ)
- Category badge
- Status badge
- Tiêu đề (bold, 2 dòng max)
- Mô tả (2 dòng max)
- Người báo cáo
- Thời gian (relative: "2 giờ trước")

**Pagination:**
- Previous/Next buttons
- "Trang X / Y"

---

### Trang Chi tiết (`AdminReportDetailPage`)

**Header Card:**
- Severity icon (lớn, màu sắc)
- Tiêu đề
- Thông tin: Người báo, Email, Loại, Thời gian

**Description Card:**
- Mô tả chi tiết đầy đủ

**Attachments Card:** (nếu có)
- Danh sách file đính kèm
- Icon phân loại (image/file)
- Nút "Mở file"

**Status Actions Card:**
- Trạng thái hiện tại
- Các nút hành động:
  - NEW → "Bắt đầu xử lý"
  - IN_PROGRESS → "Đã giải quyết" / "Quay lại Mới"
  - RESOLVED → "Đóng báo cáo"
  - CLOSED → "Mở lại"

**Comments Card:**
- Danh sách tất cả comments
- Avatar + tên + thời gian
- Nội dung comment

**Add Comment Card:**
- TextField nhiều dòng
- Nút "Gửi phản hồi"
- Loading state

---

## 🎨 Color Scheme

### Severity Colors
- 🔴 **CRITICAL**: `Colors.red`
- 🟠 **HIGH**: `Colors.orange`
- 🔵 **MEDIUM**: `Colors.blue`
- 🟢 **LOW**: `Colors.green`

### Status Colors
- 🟠 **NEW**: `Colors.orange`
- 🟣 **IN_PROGRESS**: `Colors.purple`
- 🟢 **RESOLVED**: `Colors.green`
- ⚫ **CLOSED**: `Colors.grey`

### Category Icons
- 🐛 **BUG**: Bug icon
- 💬 **FEEDBACK**: Chat icon
- 📊 **DATA_ISSUE**: Bar chart icon
- ⚡ **PERFORMANCE**: Bolt icon
- 🔒 **SECURITY**: Lock icon
- 📋 **OTHER**: Document icon

---

## 🔄 Workflow

### Chu trình xử lý báo cáo:

```
1. User tạo báo cáo → Status: NEW
   ↓
2. Admin nhận thông báo
   ↓
3. Admin xem chi tiết, nhấn "Bắt đầu xử lý" → Status: IN_PROGRESS
   ↓
4. Admin thêm comment trao đổi với user
   ↓
5. Admin fix xong, nhấn "Đã giải quyết" → Status: RESOLVED
   ↓
6. User xác nhận OK
   ↓
7. Admin nhấn "Đóng báo cáo" → Status: CLOSED
   ↓
8. Lưu thời gian đóng (closed_at) và người đóng (closed_by)
```

---

## 📊 Statistics Dashboard

### Metrics theo dõi:
1. **Tổng số báo cáo**: Tất cả thời gian
2. **Phân bổ theo Status**: NEW, IN_PROGRESS, RESOLVED, CLOSED
3. **Phân bổ theo Severity**: Ưu tiên xử lý CRITICAL
4. **Phân bổ theo Category**: Biết loại vấn đề nào nhiều nhất
5. **Báo cáo gần đây**: 5 báo cáo mới nhất

---

## 🚀 Cách sử dụng

### Bước 1: Truy cập
- Đăng nhập với tài khoản Admin
- Vào Dashboard
- Nhấn "Báo cáo hệ thống" 🐛

### Bước 2: Xem danh sách
- Xem statistics ở trên
- Dùng filter để lọc theo status/severity/category
- Nhấn vào báo cáo để xem chi tiết

### Bước 3: Xử lý báo cáo
- Đọc mô tả, xem file đính kèm
- Nhấn "Bắt đầu xử lý" để đánh dấu đang làm
- Thêm comment để trao đổi với người báo
- Sau khi fix xong, nhấn "Đã giải quyết"
- Khi người dùng xác nhận OK, nhấn "Đóng báo cáo"

---

## 🔐 Phân quyền

Hiện tại: Chỉ có **ADMIN** mới truy cập được.

Có thể mở rộng:
- **DAO_TAO**: Xem và comment (không update status)
- **GIANG_VIEN**: Chỉ xem báo cáo của chính mình

Implement bằng Policy:
```php
// app/Policies/SystemReportPolicy.php
public function viewAny(User $user) {
    return $user->role === 'ADMIN';
}
```

---

## 📝 Dữ liệu mẫu

Seeder tạo **7 báo cáo** mẫu:

1. ✅ **CRITICAL BUG** - App crash khi xuất Excel (IN_PROGRESS)
2. ⚠️ **HIGH PERFORMANCE** - Điểm danh bị lag (NEW)
3. ℹ️ **MEDIUM DATA_ISSUE** - Thiếu môn học (RESOLVED)
4. 🟢 **LOW FEEDBACK** - Xuất báo cáo theo học kỳ (NEW)
5. ✅ **CRITICAL SECURITY** - Xem được lịch người khác (RESOLVED)
6. ℹ️ **MEDIUM BUG** - Không đăng ký được tài khoản (NEW)
7. ℹ️ **MEDIUM FEEDBACK** - UI không responsive (IN_PROGRESS)

---

## 🧪 Testing Checklist

- [x] Backend API hoạt động
- [x] Seeder tạo dữ liệu thành công
- [x] Frontend load danh sách
- [x] Filter hoạt động
- [x] Statistics hiển thị đúng
- [x] Chi tiết báo cáo load
- [x] Cập nhật status thành công
- [x] Thêm comment thành công
- [x] Pagination hoạt động
- [x] Refresh data

---

## 🎓 Tính năng mở rộng

### Phase 2:
1. **Assign to Admin** - Gán báo cáo cho admin cụ thể
2. **Due date** - Hạn xử lý
3. **Email notification** - Thông báo qua email
4. **Priority tags** - Tag quan trọng/khẩn cấp

### Phase 3:
1. **Search** - Tìm kiếm full-text
2. **Export Excel** - Xuất báo cáo
3. **Chart dashboard** - Biểu đồ xu hướng
4. **SLA tracking** - KPI thời gian xử lý

### Phase 4:
1. **Auto-categorize** - AI phân loại tự động
2. **Duplicate detection** - Phát hiện báo cáo trùng
3. **Knowledge base** - Liên kết với hướng dẫn
4. **Public status page** - Trang trạng thái công khai

---

## 👨‍💻 Maintainer Notes

### Cấu trúc code:
- **Backend**: RESTful API, Laravel conventions
- **Frontend**: Clean Architecture, Riverpod state management
- **UI**: Material Design 3, responsive

### Dependencies mới:
- `intl`: Format date/time
- `url_launcher`: Mở file đính kèm

### Best practices:
- ✅ Separation of concerns
- ✅ Immutable state
- ✅ Error handling
- ✅ Loading states
- ✅ Empty states
- ✅ Type safety

---

## 📚 Tài liệu tham khảo

- [Laravel API Resources](https://laravel.com/docs/11.x/eloquent-resources)
- [Riverpod Documentation](https://riverpod.dev)
- [Flutter Material Design](https://m3.material.io)
- [Go Router](https://pub.dev/packages/go_router)

---

**Version**: 1.0.0  
**Last updated**: November 6, 2025  
**Author**: GitHub Copilot  
**Status**: ✅ Production Ready
