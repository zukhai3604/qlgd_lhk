<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

// Bắt lỗi cụ thể
use Illuminate\Auth\Access\AuthorizationException; // 403
use Illuminate\Database\QueryException;           // Lỗi DB
use Symfony\Component\HttpFoundation\Response;    // Mã HTTP

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )

    // 📌 ĐĂNG KÝ MIDDLEWARE Ở ĐÂY (KHÔNG đặt trong withExceptions)
    ->withMiddleware(function (Middleware $middleware): void {

        // Alias cho route middleware
        $middleware->alias([
            'role'           => \App\Http\Middleware\RoleMiddleware::class,
            'ensure.active'  => \App\Http\Middleware\EnsureUserIsActive::class,
        ]);

        // Bổ sung group 'api'
        $middleware->appendToGroup('api', [
            \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
            'throttle:api',
            \Illuminate\Routing\Middleware\SubstituteBindings::class,
        ]);
    })

    // 📌 XỬ LÝ NGOẠI LỆ CHO API
    ->withExceptions(function (Exceptions $exceptions) {
        $exceptions->render(function (\Throwable $e, Request $request) {
            if ($request->is('api/*')) {
                $response = ['message' => 'Đã có lỗi xảy ra, vui lòng thử lại sau.'];
                $statusCode = 500;

                // Wrap logging trong try-catch để tránh crash khi không thể ghi log
                try {
                    if (config('app.debug')) {
                        $response['debug'] = [
                            'message' => $e->getMessage(),
                            'file'    => $e->getFile(),
                            'line'    => $e->getLine(),
                        ];
                    }
                } catch (\Exception $logError) {
                    // Ignore logging errors - vẫn trả về response
                }

                if ($e instanceof \Illuminate\Validation\ValidationException) {
                    $response['message'] = 'Dữ liệu đầu vào không hợp lệ.';
                    $response['errors']  = $e->errors();
                    $statusCode = 422;
                } elseif ($e instanceof AuthorizationException) {
                    $response['message'] = 'Bạn không có quyền truy cập chức năng này.';
                    $statusCode = Response::HTTP_FORBIDDEN; // 403
                } elseif ($e instanceof \Illuminate\Database\Eloquent\ModelNotFoundException) {
                    $response['message'] = 'Không tìm thấy đối tượng yêu cầu.';
                    $statusCode = 404;
                } elseif ($e instanceof \Illuminate\Auth\AuthenticationException) {
                    $response['message'] = 'Chưa xác thực.';
                    $statusCode = 401;
                } elseif ($e instanceof QueryException && $e->getCode() == 2002) {
                    $response['message'] = 'Lỗi kết nối CSDL: Database chưa khởi động hoặc sai host.';
                    $statusCode = 503;
                } elseif ($e instanceof QueryException) {
                    $response['message'] = 'Lỗi truy vấn cơ sở dữ liệu. Vui lòng kiểm tra lại.';
                    $statusCode = 500;
                }

                return response()->json($response, $statusCode, [
                    'Content-Type' => 'application/json; charset=utf-8'
                ]);
            }
        });
    })
    ->create();
