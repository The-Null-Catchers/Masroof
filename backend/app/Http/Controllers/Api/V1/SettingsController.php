<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\SettingsRequest;
use App\Http\Resources\V1\UserResource;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SettingsController extends Controller
{
    public function show(Request $request): UserResource
    {
        return new UserResource($request->user());
    }

    public function update(SettingsRequest $request): UserResource
    {
        $user = $request->user();

        DB::transaction(function () use ($request, $user) {
            $user->fill($request->profile())->save();
            $user->settingsOrDefault()->fill($request->settings())->save();
        });

        return new UserResource($user->refresh());
    }

    /**
     * Saves the onboarding answers (all optional) and marks onboarding done.
     */
    public function completeOnboarding(SettingsRequest $request): UserResource
    {
        $user = $request->user();

        DB::transaction(function () use ($request, $user) {
            $user->fill($request->profile())->save();
            $settings = $user->settingsOrDefault()->fill($request->settings());
            $settings->onboarding_completed_at ??= now();
            $settings->save();
        });

        return new UserResource($user->refresh());
    }
}
