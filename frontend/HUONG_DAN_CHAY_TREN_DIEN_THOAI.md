# HƯỚNG DẪN CHẠY APP TRÊN ĐIỆN THOẠI THẬT
# ===========================================

# IP máy tính: 192.168.26.103
# Port backend: 8888
# Backend URL: http://192.168.26.103:8888

# CÁCH 1: Dùng script tự động (Khuyến nghị)
# Chạy file: run_on_phone.ps1
# .\run_on_phone.ps1

# CÁCH 2: Chạy trực tiếp lệnh
# flutter run -d <device-id> --dart-define=BASE_URL=http://192.168.26.103:8888

# CÁCH 3: Chạy với release mode (tối ưu hiệu năng)
# flutter run --release -d <device-id> --dart-define=BASE_URL=http://192.168.26.103:8888

# KIỂM TRA THIẾT BỊ ĐÃ KẾT NỐI:
# flutter devices

# LƯU Ý:
# 1. Đảm bảo điện thoại và máy tính cùng mạng WiFi
# 2. Đảm bảo backend đang chạy trên port 8888
# 3. Nếu IP thay đổi, cập nhật lại BASE_URL trong script

# KIỂM TRA BACKEND CÓ HOẠT ĐỘNG:
# Mở trình duyệt trên điện thoại và truy cập: http://192.168.26.103:8888

