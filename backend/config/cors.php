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
        'http://localhost:*',  // Cho phép mọi port của localhost (VD: 51978, 57744...)
        'http://127.0.0.1',
        'http://127.0.0.1:*',  // Cho phép mọi port của 127.0.0.1
    ],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'], // Cho phép mọi header (quan trọng để gửi token JSON)

    'exposed_headers' => [],

    'max_age' => 0,

    /*
    |--------------------------------------------------------------------------
    | Credentials (Cookie / Auth)
    |--------------------------------------------------------------------------
    | Nếu bạn chỉ dùng token (Bearer token) → để false.
    | Nếu bạn dùng Sanctum với cookie (CSRF) → đổi thành true.
    */
    'supports_credentials' => false,

];
