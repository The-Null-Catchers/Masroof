<?php

use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\V1\AccountController;
use App\Http\Controllers\Api\V1\Admin;
use App\Http\Controllers\Api\V1\AnalyticsController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\BudgetController;
use App\Http\Controllers\Api\V1\CategoryController;
use App\Http\Controllers\Api\V1\DashboardController;
use App\Http\Controllers\Api\V1\EmailVerificationController;
use App\Http\Controllers\Api\V1\GoalController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\ProfileController;
use App\Http\Controllers\Api\V1\ReceiptController;
use App\Http\Controllers\Api\V1\RecurringTransactionController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\ReportExportController;
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
        Route::post('receipts', [ReceiptController::class, 'store'])->middleware('throttle:20,1')->name('receipts.store');
        Route::get('receipts/{receipt}', [ReceiptController::class, 'show'])->name('receipts.show');
        Route::get('receipts/{receipt}/image', [ReceiptController::class, 'image'])->name('receipts.image');
        Route::post('receipts/{receipt}/transaction', [ReceiptController::class, 'confirm'])->name('receipts.confirm');
        Route::delete('receipts/{receipt}', [ReceiptController::class, 'destroy'])->name('receipts.destroy');

        Route::post('transactions/{transaction}/duplicate', [TransactionController::class, 'duplicate'])->name('transactions.duplicate');
        Route::apiResource('transactions', TransactionController::class);
        Route::apiResource('tags', TagController::class)->except('show');

        Route::apiResource('budgets', BudgetController::class);
        Route::apiResource('goals', GoalController::class);
        Route::get('recurring/upcoming', [RecurringTransactionController::class, 'upcoming'])->name('recurring.upcoming');
        Route::apiResource('recurring', RecurringTransactionController::class)->parameters(['recurring' => 'recurring']);

        Route::get('notifications', [NotificationController::class, 'index'])->name('notifications.index');
        Route::post('notifications/read-all', [NotificationController::class, 'markAllRead'])->name('notifications.read-all');
        Route::post('notifications/{id}/read', [NotificationController::class, 'markRead'])->whereUuid('id')->name('notifications.read');
        Route::delete('notifications/{id}', [NotificationController::class, 'destroy'])->whereUuid('id')->name('notifications.destroy');
        Route::get('notification-preferences', [NotificationController::class, 'preferences'])->name('notifications.preferences');
        Route::put('notification-preferences', [NotificationController::class, 'updatePreferences'])->name('notifications.preferences.update');

        Route::get('goals/{goal}/entries', [GoalController::class, 'entries'])->name('goals.entries.index');
        Route::post('goals/{goal}/entries', [GoalController::class, 'addEntry'])->name('goals.entries.store');
        Route::delete('goals/{goal}/entries/{entry}', [GoalController::class, 'deleteEntry'])->name('goals.entries.destroy');

        Route::get('reports/summary', [ReportController::class, 'summary'])->name('reports.summary');
        Route::get('reports/exports', [ReportExportController::class, 'index'])->name('reports.exports.index');
        Route::post('reports/exports', [ReportExportController::class, 'store'])->middleware('throttle:10,1')->name('reports.exports.store');
        Route::get('reports/exports/{export}', [ReportExportController::class, 'show'])->name('reports.exports.show');
        Route::get('reports/exports/{export}/download', [ReportExportController::class, 'download'])->name('reports.exports.download');
        Route::get('dashboard', DashboardController::class)->name('dashboard');
        Route::get('analytics/summary', [AnalyticsController::class, 'summary'])->name('analytics.summary');
        Route::get('analytics/trends', [AnalyticsController::class, 'trends'])->name('analytics.trends');
        Route::get('insights', [AnalyticsController::class, 'insights'])->name('insights.index');
        Route::get('sync', [SyncController::class, 'pull'])->name('sync.pull');

        Route::prefix('admin')->name('admin.')->middleware('admin')->group(function () {
            Route::get('stats', Admin\StatsController::class)->name('stats');
            Route::get('users', [Admin\UserController::class, 'index'])->name('users.index');
            Route::post('users/{user}/suspend', [Admin\UserController::class, 'suspend'])->name('users.suspend');
            Route::post('users/{user}/reactivate', [Admin\UserController::class, 'reactivate'])->name('users.reactivate');
            Route::get('audit-log', [Admin\UserController::class, 'audit'])->name('audit');
            Route::get('system', [Admin\SystemController::class, 'status'])->name('system');
            Route::get('failed-jobs', [Admin\SystemController::class, 'failedJobs'])->name('failed-jobs.index');
            Route::post('failed-jobs/{uuid}/retry', [Admin\SystemController::class, 'retry'])->whereUuid('uuid')->name('failed-jobs.retry');
            Route::delete('failed-jobs/{uuid}', [Admin\SystemController::class, 'forget'])->whereUuid('uuid')->name('failed-jobs.destroy');
        });
    });
});
