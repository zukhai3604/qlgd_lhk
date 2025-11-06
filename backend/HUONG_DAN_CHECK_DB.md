# HƯỚNG DẪN KIỂM TRA DATABASE SCHEMA

## ⚠️ QUAN TRỌNG: Kiểm tra Database đang chạy

Trước khi chạy script, đảm bảo database đang chạy:

```bash
# Nếu dùng Laradock/Docker
cd projectcuoiki/laradock
docker-compose up -d mysql

# Hoặc kiểm tra
docker-compose ps mysql
```

---

## Cách 1: Dùng script PHP (Khuyến nghị - Dễ nhất) ⭐

### Chạy script tự động:
```bash
cd projectcuoiki/backend
php artisan tinker < check_db_final.php
```

**Hoặc nếu PowerShell không hỗ trợ `<`:**

```powershell
cd projectcuoiki/backend
Get-Content check_db_final.php | php artisan tinker
```

Script này sẽ tự động:
- ✅ Kiểm tra cấu trúc bảng `semesters` và `assignments`
- ✅ Kiểm tra có cột `is_active` và `semester_label` không
- ✅ Kiểm tra foreign keys
- ✅ Hiển thị migrations đã chạy
- ✅ Hiển thị dữ liệu mẫu
- ✅ Đưa ra kết luận và hướng dẫn sửa

---

## Cách 2: Dùng Artisan Tinker (Thủ công)

### Bước 1: Vào thư mục backend
```bash
cd projectcuoiki/backend
```

### Bước 2: Chạy Tinker
```bash
php artisan tinker
```

### Bước 3: Copy-paste từng lệnh (KHÔNG copy markdown code blocks!)

**⚠️ LƯU Ý:** Copy từng dòng code, KHÔNG copy cả khối markdown ```php ... ```

```php
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;
```

```php
echo "=== KIỂM TRA DATABASE SCHEMA ===\n\n";
```

```php
// Kiểm tra bảng semesters
if (!Schema::hasTable('semesters')) {
    echo "❌ Bảng semesters KHÔNG TỒN TẠI\n";
} else {
    echo "✅ Bảng semesters tồn tại\n";
    $columns = DB::select("SELECT COLUMN_NAME, DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'semesters' ORDER BY ORDINAL_POSITION");
    foreach ($columns as $col) {
        echo "  - {$col->COLUMN_NAME}: {$col->DATA_TYPE}\n";
    }
    $hasIsActive = Schema::hasColumn('semesters', 'is_active');
    echo "Cột is_active: " . ($hasIsActive ? "CÓ ❌" : "KHÔNG ✅") . "\n";
}
```

```php
// Kiểm tra bảng assignments
if (!Schema::hasTable('assignments')) {
    echo "❌ Bảng assignments KHÔNG TỒN TẠI\n";
} else {
    echo "✅ Bảng assignments tồn tại\n";
    $columns = DB::select("SELECT COLUMN_NAME, DATA_TYPE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'assignments' ORDER BY ORDINAL_POSITION");
    foreach ($columns as $col) {
        echo "  - {$col->COLUMN_NAME}: {$col->DATA_TYPE}\n";
    }
    $hasSemesterLabel = Schema::hasColumn('assignments', 'semester_label');
    $hasSemesterId = Schema::hasColumn('assignments', 'semester_id');
    echo "Cột semester_label: " . ($hasSemesterLabel ? "CÓ ❌" : "KHÔNG ✅") . "\n";
    echo "Cột semester_id: " . ($hasSemesterId ? "CÓ ✅" : "KHÔNG ❌") . "\n";
}
```

---

## Cách 3: Kiểm tra trực tiếp bằng SQL (Nếu dùng MySQL client)

```sql
-- Kiểm tra cấu trúc bảng semesters
DESCRIBE semesters;
-- Hoặc
SHOW COLUMNS FROM semesters;

-- Kiểm tra cấu trúc bảng assignments
DESCRIBE assignments;
-- Hoặc
SHOW COLUMNS FROM assignments;

-- Kiểm tra có cột is_active trong semesters không
SELECT COLUMN_NAME, DATA_TYPE 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'semesters' 
AND COLUMN_NAME = 'is_active';

-- Kiểm tra có cột semester_label trong assignments không
SELECT COLUMN_NAME, DATA_TYPE 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'assignments' 
AND COLUMN_NAME = 'semester_label';
```

---

## 🔧 Nếu phát hiện có is_active hoặc semester_label:

### ⭐ Cách tốt nhất: Fresh migration (sẽ mất data)
```bash
cd projectcuoiki/backend
php artisan migrate:fresh --seed
```

**Lưu ý:** Cách này sẽ xóa tất cả data và tạo lại từ đầu với cấu trúc đúng.

### Cách 2: Dùng migration fix (nếu migrations đã tồn tại)
```bash
php artisan migrate --path=database/migrations/2025_11_06_000000_remove_is_active_from_semesters_final.php
php artisan migrate --path=database/migrations/2025_11_06_000001_remove_semester_label_from_assignments_final.php
```

**Lưu ý:** Các migrations này đã được xóa và logic đã tích hợp vào migrations chính.

---

## ❌ LỖI THƯỜNG GẶP

### Lỗi: `getaddrinfo for mysql failed`
**Nguyên nhân:** Database chưa chạy hoặc config sai

**Giải pháp:**
```bash
# Kiểm tra Docker đang chạy
docker-compose ps

# Khởi động MySQL
docker-compose up -d mysql

# Kiểm tra .env
cat .env | grep DB_
```

### Lỗi: `Syntax error, unexpected '`'` trong tinker
**Nguyên nhân:** Copy cả markdown code blocks (```php ... ```)

**Giải pháp:** 
- Chỉ copy code bên trong, không copy markdown markers
- Hoặc dùng script `check_db_final.php` thay vì copy-paste thủ công

