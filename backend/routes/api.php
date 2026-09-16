<?php

use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\V1\AccountController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CategoryController;
use App\Http\Controllers\Api\V1\EmailVerificationController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\SettingsController;
use App\Http\Controllers\Api\V1\SyncController;
use App\Http\Controllers\Api\V1\TagController;
use App\Http\Controllers\Api\V1\TransactionController;
use Illuminate\Support\Facades\Route;

Route::get('health', HealthController::class)->name('health');

Route::prefix('v1')->name('v1.')->group(function () {
    Route::prefix('auth')->name('auth.')->group(function () {
        Route::middleware('throttle:auth')->group(function () {
            Route::post('register', [AuthController::class, 'register'])->name('register');
            Route::post('login', [AuthController::class, 'login'])->name('login');
        });
        Route::get('verify-email/{id}/{hash}', [EmailVerificationController::class, 'verify'])
            ->middleware(['signed', 'throttle:6,1'])
            ->name('verification.verify');
        Route::middleware('throttle:password-reset')->group(function () {
            Route::post('forgot-password', [AuthController::class, 'forgotPassword'])->name('forgot-password');
            Route::post('reset-password', [AuthController::class, 'resetPassword'])->name('reset-password');
        });
    });

    Route::middleware(['auth:sanctum', 'active', 'throttle:api'])->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout'])->name('auth.logout');
        Route::post('auth/refresh', [AuthController::class, 'refresh'])->name('auth.refresh');
        Route::post('auth/email/verification-notification', [EmailVerificationController::class, 'resend'])
            ->middleware('throttle:6,1')
            ->name('verification.send');

        Route::get('settings', [SettingsController::class, 'show'])->name('settings.show');
        Route::patch('settings', [SettingsController::class, 'update'])->name('settings.update');
        Route::post('onboarding', [SettingsController::class, 'completeOnboarding'])->name('onboarding.complete');

        Route::get('me', [ProfileController::class, 'show'])->name('me.show');
        Route::patch('me', [ProfileController::class, 'update'])->name('me.update');
        Route::put('me/password', [ProfileController::class, 'changePassword'])->name('me.password');
        Route::get('me/sessions', [ProfileController::class, 'sessions'])->name('me.sessions');
        Route::delete('me/sessions/{session}', [ProfileController::class, 'revokeSession'])->whereNumber('session')->name('me.sessions.revoke');
        Route::delete('me', [ProfileController::class, 'destroy'])->name('me.destroy');

        Route::get('accounts/summary', [AccountController::class, 'summary'])->name('accounts.summary');
        Route::apiResource('accounts', AccountController::class);
        Route::apiResource('categories', CategoryController::class);
        Route::post('transactions/{transaction}/duplicate', [TransactionController::class, 'duplicate'])->name('transactions.duplicate');
        Route::apiResource('transactions', TransactionController::class);
        Route::apiResource('tags', TagController::class)->except('show');

        Route::get('reports/summary', [ReportController::class, 'summary'])->name('reports.summary');
        Route::get('sync', [SyncController::class, 'pull'])->name('sync.pull');
    });
});
