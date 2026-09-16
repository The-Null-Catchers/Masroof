<?php

use Illuminate\Support\Facades\Route;

Route::get('/', fn () => response()->json([
    'name' => 'Masroof API',
    'docs' => url('/api/v1'),
    'health' => url('/api/health'),
]));
