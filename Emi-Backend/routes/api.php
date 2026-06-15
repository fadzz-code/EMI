<?php

use App\Http\Controllers\Api\AdminRegistrationRequestController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ClassAssignmentController;
use App\Http\Controllers\Api\PublicLookupController;
use App\Http\Controllers\Api\SchoolClassController;
use App\Http\Controllers\Api\SchoolController;
use App\Http\Controllers\Api\UserController;
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

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('schools', [SchoolController::class, 'index']);
        Route::post('schools', [SchoolController::class, 'store']);
        Route::get('schools/{id}', [SchoolController::class, 'show']);
        Route::put('schools/{id}', [SchoolController::class, 'update']);
        Route::delete('schools/{id}', [SchoolController::class, 'destroy']);
        Route::get('classes', [SchoolClassController::class, 'index']);
        Route::post('classes', [SchoolClassController::class, 'store']);
        Route::get('classes/{id}', [SchoolClassController::class, 'show']);
        Route::put('classes/{id}', [SchoolClassController::class, 'update']);
        Route::delete('classes/{id}', [SchoolClassController::class, 'destroy']);
        Route::post('classes/{id}/assign-teacher', [ClassAssignmentController::class, 'assignTeacher']);
        Route::post('classes/{id}/assign-student', [ClassAssignmentController::class, 'assignStudent']);
        Route::get('classes/{id}/students', [SchoolClassController::class, 'students']);
        Route::get('users', [UserController::class, 'index']);
        Route::get('users/{id}', [UserController::class, 'show']);
        Route::put('users/{id}', [UserController::class, 'update']);
        Route::patch('users/{id}/status', [UserController::class, 'updateStatus']);
    });
});
