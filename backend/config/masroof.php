<?php

return [
    /*
    | Supported UI/API locales. The first entry is the default.
    */
    'locales' => ['ar', 'en'],

    /*
    | Supported ISO 4217 currencies and their minor-unit exponent.
    | Amounts are always persisted as integers in minor units.
    */
    'currencies' => [
        // Primary market currencies first.
        'ILS' => 2, 'USD' => 2, 'JOD' => 3, 'EUR' => 2,
        'EGP' => 2, 'SAR' => 2, 'AED' => 2, 'KWD' => 3, 'BHD' => 3, 'OMR' => 3,
        'QAR' => 2, 'GBP' => 2, 'TRY' => 2, 'MAD' => 2, 'TND' => 3, 'DZD' => 2,
        'IQD' => 3, 'LBP' => 2,
    ],

    /*
    | Currencies surfaced first in pickers.
    */
    'primary_currencies' => ['ILS', 'USD', 'JOD', 'EUR'],

    'payment_methods' => ['cash', 'card', 'bank_transfer', 'wallet', 'cheque', 'other'],

    'financial_goals' => ['track_spending', 'save_money', 'emergency_fund', 'pay_debt', 'budget_better', 'invest', 'other'],

    /*
    | Largest absolute amount (in major units) accepted for a single entry.
    */
    'max_amount' => 1_000_000_000,

    /*
    | Public URL of the web app (used in password reset e-mails).
    */
    'frontend_url' => env('FRONTEND_URL', 'http://localhost:3000'),

    /*
    | Lifetime of API tokens in minutes (null = never expire).
    */
    'token_ttl_minutes' => env('MASROOF_TOKEN_TTL_MINUTES', 60 * 24 * 30),

    /*
    | Notification types with default channels. Users override per type.
    */
    'notifications' => [
        'budget_threshold' => ['in_app' => true, 'email' => false],
        'bill_reminder' => ['in_app' => true, 'email' => false],
        'recurring_reminder' => ['in_app' => true, 'email' => false],
        'goal_reminder' => ['in_app' => true, 'email' => false],
        'weekly_summary' => ['in_app' => true, 'email' => false],
        'monthly_summary' => ['in_app' => true, 'email' => true],
    ],

    /*
    | Local hour (user timezone) at which reminders and summaries are sent.
    */
    'notification_hour' => (int) env('MASROOF_NOTIFICATION_HOUR', 8),

    /*
    | Receipt OCR. "tesseract" runs locally (free); "mock" needs no engine and
    | is used in tests. Add providers by implementing App\Services\Ocr\OcrProvider.
    */
    'ocr' => [
        'driver' => env('MASROOF_OCR_DRIVER', 'tesseract'),
        'tesseract_binary' => env('MASROOF_TESSERACT_BINARY', 'tesseract'),
        'tesseract_languages' => env('MASROOF_TESSERACT_LANGUAGES', 'ara+eng'),
    ],
];
