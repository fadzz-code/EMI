<?php

use App\Http\Controllers\Api\AdminRegistrationRequestController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PublicLookupController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::prefix('public')->group(function () {
        Route::get('schools', [PublicLookupController::class, 'schools']);
        Route::get('schools/{school_id}/classes', [PublicLookupController::class, 'classes']);
    });

    Route::prefix('auth')->group(function () {
        Route::post('register', [AuthController::class, 'register'])->middleware('throttle:emi-register');
        Route::post('login', [AuthController::class, 'login'])->middleware('throttle:emi-login');

        Route::middleware('auth:sanctum')->group(function () {
            Route::post('logout', [AuthController::class, 'logout']);
            Route::get('me', [AuthController::class, 'me']);
            Route::patch('me', [AuthController::class, 'updateProfile']);
            Route::put('password', [AuthController::class, 'updatePassword']);
        });
    });

    Route::middleware(['auth:sanctum', 'role:admin'])->prefix('admin')->group(function () {
        Route::get('registration-requests', [AdminRegistrationRequestController::class, 'index']);
        Route::get('registration-requests/{id}', [AdminRegistrationRequestController::class, 'show']);
        Route::post('registration-requests/{id}/approve', [AdminRegistrationRequestController::class, 'approve']);
        Route::post('registration-requests/{id}/reject', [AdminRegistrationRequestController::class, 'reject']);
    });
});
