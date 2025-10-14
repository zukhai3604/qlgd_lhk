<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RedirectIfAuthenticated
{
    public function handle(Request $request, Closure $next, ...$guards): Response
    {
        // Web app mới cần redirect, API thì bỏ qua
        return $next($request);
    }
}
