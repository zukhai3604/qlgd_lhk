<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Cache\RateLimiting\Limit;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // ✅ Định nghĩa rate limiter tên "api"
        RateLimiter::for('api', function (Request $request) {
            // Giới hạn 60 request/phút theo user ID hoặc IP
            return Limit::perMinute(60)->by(
                optional($request->user())->id ?: $request->ip()
            );
        });
    }
}
