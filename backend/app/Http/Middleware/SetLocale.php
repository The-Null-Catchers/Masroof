<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Symfony\Component\HttpFoundation\Response;

/**
 * Resolves the response language: explicit Accept-Language header first,
 * then the authenticated user's saved preference, then the app default.
 */
class SetLocale
{
    public function handle(Request $request, Closure $next): Response
    {
        $supported = config('masroof.locales');
        $locale = null;

        if ($request->headers->has('Accept-Language')) {
            $preferred = $request->getPreferredLanguage($supported);
            $locale = in_array($preferred, $supported, true) ? $preferred : null;
        }

        $locale ??= $request->user('sanctum')?->locale;
        App::setLocale(in_array($locale, $supported, true) ? $locale : config('app.locale'));

        $response = $next($request);
        $response->headers->set('Content-Language', App::getLocale());

        return $response;
    }
}
