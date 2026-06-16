<?php

use App\Http\Controllers\Api\AdminDictionaryCategoryController;
use App\Http\Controllers\Api\AdminDictionaryEntryController;
use App\Http\Controllers\Api\AdminRegistrationRequestController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AvatarController;
use App\Http\Controllers\Api\ClassAssignmentController;
use App\Http\Controllers\Api\DictionaryController;
use App\Http\Controllers\Api\DictionaryImportController;
use App\Http\Controllers\Api\MediaController;
use App\Http\Controllers\Api\PublicLookupController;
use App\Http\Controllers\Api\SchoolClassController;
use App\Http\Controllers\Api\SchoolController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::prefix('public')->group(function () {
        Route::get('schools', [PublicLookupController::class, 'schools']);
        Route::get('schools/{school_id}/classes', [PublicLookupController::class, 'classes']);
        Route::get('media/{id}/content', [MediaController::class, 'publicContent']);
    });

    Route::prefix('auth')->group(function () {
        Route::post('register', [AuthController::class, 'register'])->middleware('throttle:emi-register');
        Route::post('login', [AuthController::class, 'login'])->middleware('throttle:emi-login');

        Route::middleware('auth:sanctum')->group(function () {
            Route::post('logout', [AuthController::class, 'logout']);
            Route::get('me', [AuthController::class, 'me']);
            Route::patch('me', [AuthController::class, 'updateProfile']);
            Route::put('password', [AuthController::class, 'updatePassword']);
            Route::post('me/avatar', [AvatarController::class, 'store']);
            Route::delete('me/avatar', [AvatarController::class, 'destroy']);
        });
    });

    Route::get('media/{id}/download', [MediaController::class, 'download'])
        ->name('media.download')
        ->middleware('signed:relative');

    Route::middleware(['auth:sanctum', 'role:admin'])->prefix('admin')->group(function () {
        Route::get('registration-requests', [AdminRegistrationRequestController::class, 'index']);
        Route::get('registration-requests/{id}', [AdminRegistrationRequestController::class, 'show']);
        Route::post('registration-requests/{id}/approve', [AdminRegistrationRequestController::class, 'approve']);
        Route::post('registration-requests/{id}/reject', [AdminRegistrationRequestController::class, 'reject']);
        Route::get('dictionary/categories', [AdminDictionaryCategoryController::class, 'index']);
        Route::post('dictionary/categories', [AdminDictionaryCategoryController::class, 'store']);
        Route::get('dictionary/categories/{id}', [AdminDictionaryCategoryController::class, 'show']);
        Route::put('dictionary/categories/{id}', [AdminDictionaryCategoryController::class, 'update']);
        Route::delete('dictionary/categories/{id}', [AdminDictionaryCategoryController::class, 'destroy']);
        Route::get('dictionary/entries', [AdminDictionaryEntryController::class, 'index']);
        Route::post('dictionary/entries', [AdminDictionaryEntryController::class, 'store']);
        Route::get('dictionary/entries/{id}', [AdminDictionaryEntryController::class, 'show']);
        Route::put('dictionary/entries/{id}', [AdminDictionaryEntryController::class, 'update']);
        Route::delete('dictionary/entries/{id}', [AdminDictionaryEntryController::class, 'destroy']);
        Route::get('dictionary/imports/template', [DictionaryImportController::class, 'template']);
        Route::post('dictionary/imports/preview', [DictionaryImportController::class, 'preview']);
        Route::get('dictionary/imports', [DictionaryImportController::class, 'index']);
        Route::get('dictionary/imports/{id}', [DictionaryImportController::class, 'show']);
        Route::get('dictionary/imports/{id}/errors', [DictionaryImportController::class, 'errors']);
        Route::post('dictionary/imports/{id}/confirm', [DictionaryImportController::class, 'confirm']);
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
        Route::post('media', [MediaController::class, 'store']);
        Route::get('media/{id}', [MediaController::class, 'show']);
        Route::post('media/{id}/temporary-url', [MediaController::class, 'temporaryUrl']);
        Route::delete('media/{id}', [MediaController::class, 'destroy']);
        Route::get('dictionary', [DictionaryController::class, 'index']);
        Route::get('dictionary/{id}', [DictionaryController::class, 'show']);
    });
});
