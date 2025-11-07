<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        $user = $request->user();
        if (!$user) {
            Log::error('RoleMiddleware: No authenticated user');
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        Log::info('RoleMiddleware check', [
            'user_role' => $user->role,
            'required_roles' => $roles,
            'user_id' => $user->id,
        ]);

        // roles là mảng tham số từ route middleware, ví dụ: role:ADMIN
        if (!in_array($user->role, $roles, true)) {
            Log::warning('RoleMiddleware: Access denied', [
                'user_role' => $user->role,
                'required' => $roles,
            ]);
            return response()->json([
                'message' => 'Forbidden (role).',
                'debug' => [
                    'your_role' => $user->role,
                    'required' => $roles,
                ]
            ], 403);
        }

        return $next($request);
    }
}
