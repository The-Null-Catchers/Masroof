<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserIsActive
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user !== null && $user->isSuspended()) {
            $user->tokens()->delete();

            return response()->json(['message' => __('masroof.account_suspended')], 403);
        }

        return $next($request);
    }
}
