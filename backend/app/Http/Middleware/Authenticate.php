<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;
use Illuminate\Http\Request;

class Authenticate extends Middleware
{
    protected function redirectTo(Request $request): ?string
    {
        // API: không redirect, chỉ trả 401 JSON
        if (! $request->expectsJson()) {
            return route('login');
        }
        return null;
    }
}
