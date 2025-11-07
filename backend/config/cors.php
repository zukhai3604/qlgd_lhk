<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Laravel CORS Configuration
    |--------------------------------------------------------------------------
    |
    | File này kiểm soát quyền truy cập tài nguyên từ các origin khác nhau.
    | Flutter Web cần được cho phép gọi API qua trình duyệt, nên ta cho phép
    | các origin localhost và 127.0.0.1 (vì đó là nơi FE đang chạy).
    |
    */

    'paths' => [
        'api/*',               // Cho phép mọi route API
        'sanctum/csrf-cookie', // Nếu dùng Sanctum (Web)
    ],

    'allowed_methods' => ['*'], // Cho phép mọi phương thức: GET, POST, PUT, DELETE...

    'allowed_origins' => [
        'http://localhost',
        'http://localhost:*',  // Cho phép mọi port của localhost (VD: 5173, 8080...)
        'http://127.0.0.1',
        'http://127.0.0.1:*',  // Cho phép mọi port của 127.0.0.1
        'http://192.168.1.14', // IP máy tính - THAY BẰNG IP THẬT CỦA BẠN
        'http://192.168.1.100:*',
    ],

    'allowed_origins_patterns' => [
        '/^http:\/\/192\.168\.\d+\.\d+/',  // Cho phép tất cả IP trong mạng LAN 192.168.x.x
        '/^http:\/\/10\.\d+\.\d+\.\d+/',   // Cho phép mạng 10.x.x.x
    ],

    'allowed_headers' => ['*'], // Cho phép mọi header (quan trọng để gửi token JSON)

    'exposed_headers' => ['Authorization'], // Cho phép FE đọc token trong header nếu cần

    'max_age' => 0,

    /*
    |--------------------------------------------------------------------------
    | Credentials (Cookie / Auth)
    |--------------------------------------------------------------------------
    | Nếu bạn chỉ dùng Bearer token → để false.
    | Nếu bạn dùng Sanctum với cookie (CSRF) → đổi thành true.
    */
    'supports_credentials' => false,

];
