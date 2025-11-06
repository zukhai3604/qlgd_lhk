-- Script SQL để xóa cột is_active khỏi bảng semesters
-- Chạy trong MySQL: mysql -u root -p database_name < drop_is_active.sql
-- Hoặc trong Docker: docker exec -i mysql_container mysql -u root -p database_name < drop_is_active.sql

USE your_database_name;

-- Xóa foreign key nếu có
SET @constraint_name = (
    SELECT CONSTRAINT_NAME 
    FROM information_schema.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'assignments' 
    AND COLUMN_NAME = 'semester_id' 
    AND REFERENCED_TABLE_NAME = 'semesters'
    LIMIT 1
);

SET @sql = IF(@constraint_name IS NOT NULL, 
    CONCAT('ALTER TABLE assignments DROP FOREIGN KEY `', @constraint_name, '`'),
    'SELECT "No foreign key to drop"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Xóa cột is_active nếu có
SET @has_column = (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'semesters' 
    AND COLUMN_NAME = 'is_active'
);

SET @sql = IF(@has_column > 0, 
    'ALTER TABLE semesters DROP COLUMN is_active',
    'SELECT "Column is_active does not exist"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Thêm lại foreign key nếu cần
SET @constraint_exists = (
    SELECT COUNT(*) 
    FROM information_schema.KEY_COLUMN_USAGE 
    WHERE TABLE_SCHEMA = DATABASE() 
    AND TABLE_NAME = 'assignments' 
    AND COLUMN_NAME = 'semester_id' 
    AND REFERENCED_TABLE_NAME = 'semesters'
);

SET @sql = IF(@constraint_exists = 0, 
    'ALTER TABLE assignments ADD CONSTRAINT assignments_semester_id_foreign FOREIGN KEY (semester_id) REFERENCES semesters(id) ON DELETE CASCADE',
    'SELECT "Foreign key already exists"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Kiểm tra kết quả
SELECT COLUMN_NAME, DATA_TYPE 
FROM information_schema.COLUMNS 
WHERE TABLE_SCHEMA = DATABASE() 
AND TABLE_NAME = 'semesters' 
ORDER BY ORDINAL_POSITION;

