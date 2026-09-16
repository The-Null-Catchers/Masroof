<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Auth\Events\Verified;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class EmailVerificationController extends Controller
{
    /**
     * Signed link from the verification e-mail. Works without an API token so
     * it can be opened on any device; redirects to the web app afterwards.
     */
    public function verify(Request $request, string $id, string $hash): RedirectResponse
    {
        $user = User::query()->findOrFail($id);
        $frontend = rtrim((string) config('masroof.frontend_url'), '/');

        if (! hash_equals(sha1($user->getEmailForVerification()), $hash)) {
            return redirect()->away("{$frontend}/verify-email?status=invalid");
        }

        if (! $user->hasVerifiedEmail() && $user->markEmailAsVerified()) {
            event(new Verified($user));
        }

        return redirect()->away("{$frontend}/verify-email?status=verified");
    }

    public function resend(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->hasVerifiedEmail()) {
            return response()->json(['message' => __('masroof.email_already_verified')]);
        }

        $user->sendEmailVerificationNotification();

        return response()->json(['message' => __('masroof.verification_sent')], 202);
    }
}
