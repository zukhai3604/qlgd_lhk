<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        // roles là mảng tham số từ route middleware, ví dụ: role:ADMIN
        if (!in_array($user->role, $roles, true)) {
            return response()->json(['message' => 'Forbidden (role).'], 403);
        }

        return $next($request);
    }
}
