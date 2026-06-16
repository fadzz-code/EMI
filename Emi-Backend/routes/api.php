<?php

use App\Http\Controllers\Api\AdminDictionaryCategoryController;
use App\Http\Controllers\Api\AdminDictionaryEntryController;
use App\Http\Controllers\Api\AdminLessonTemplateController;
use App\Http\Controllers\Api\AdminModuleTemplateController;
use App\Http\Controllers\Api\AdminRegistrationRequestController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AvatarController;
use App\Http\Controllers\Api\ClassAssignmentController;
use App\Http\Controllers\Api\ClassLessonController;
use App\Http\Controllers\Api\ClassModuleController;
use App\Http\Controllers\Api\DictionaryController;
use App\Http\Controllers\Api\DictionaryImportController;
use App\Http\Controllers\Api\MediaController;
use App\Http\Controllers\Api\ModuleTemplateApplyController;
use App\Http\Controllers\Api\PublicLookupController;
use App\Http\Controllers\Api\SchoolClassController;
use App\Http\Controllers\Api\SchoolController;
use App\Http\Controllers\Api\StudentModuleController;
use App\Http\Controllers\Api\StudentProgressController;
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
        Route::get('module-templates', [AdminModuleTemplateController::class, 'index']);
        Route::post('module-templates', [AdminModuleTemplateController::class, 'store']);
        Route::get('module-templates/{id}', [AdminModuleTemplateController::class, 'show']);
        Route::put('module-templates/{id}', [AdminModuleTemplateController::class, 'update']);
        Route::delete('module-templates/{id}', [AdminModuleTemplateController::class, 'destroy']);
        Route::post('module-templates/{id}/publish', [AdminModuleTemplateController::class, 'publish']);
        Route::post('module-templates/{id}/archive', [AdminModuleTemplateController::class, 'archive']);
        Route::post('module-templates/{id}/apply', ModuleTemplateApplyController::class);
        Route::get('module-templates/{module_template_id}/lessons', [AdminLessonTemplateController::class, 'index']);
        Route::post('module-templates/{module_template_id}/lessons', [AdminLessonTemplateController::class, 'store']);
        Route::patch('module-templates/{id}/lessons/reorder', [AdminLessonTemplateController::class, 'reorder']);
        Route::get('lesson-templates/{id}', [AdminLessonTemplateController::class, 'show']);
        Route::put('lesson-templates/{id}', [AdminLessonTemplateController::class, 'update']);
        Route::delete('lesson-templates/{id}', [AdminLessonTemplateController::class, 'destroy']);
        Route::post('lesson-templates/{id}/publish', [AdminLessonTemplateController::class, 'publish']);
        Route::post('lesson-templates/{id}/archive', [AdminLessonTemplateController::class, 'archive']);
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
        Route::get('classes/{class_id}/modules', [ClassModuleController::class, 'index']);
        Route::post('classes/{class_id}/modules', [ClassModuleController::class, 'store']);
        Route::patch('classes/{class_id}/modules/reorder', [ClassModuleController::class, 'reorder']);
        Route::get('class-modules/{id}', [ClassModuleController::class, 'show']);
        Route::put('class-modules/{id}', [ClassModuleController::class, 'update']);
        Route::delete('class-modules/{id}', [ClassModuleController::class, 'destroy']);
        Route::post('class-modules/{id}/publish', [ClassModuleController::class, 'publish']);
        Route::post('class-modules/{id}/archive', [ClassModuleController::class, 'archive']);
        Route::get('class-modules/{class_module_id}/lessons', [ClassLessonController::class, 'index']);
        Route::post('class-modules/{class_module_id}/lessons', [ClassLessonController::class, 'store']);
        Route::patch('class-modules/{id}/lessons/reorder', [ClassLessonController::class, 'reorder']);
        Route::get('class-lessons/{id}', [ClassLessonController::class, 'show']);
        Route::put('class-lessons/{id}', [ClassLessonController::class, 'update']);
        Route::delete('class-lessons/{id}', [ClassLessonController::class, 'destroy']);
        Route::post('class-lessons/{id}/publish', [ClassLessonController::class, 'publish']);
        Route::post('class-lessons/{id}/archive', [ClassLessonController::class, 'archive']);
        Route::get('class-lessons/{id}/content-url', [ClassLessonController::class, 'contentUrl']);
    });

    Route::middleware(['auth:sanctum', 'role:student'])->prefix('student')->group(function () {
        Route::get('modules', [StudentModuleController::class, 'index']);
        Route::get('modules/{id}', [StudentModuleController::class, 'show']);
        Route::post('modules/{id}/start', [StudentModuleController::class, 'start']);
        Route::patch('lessons/{id}/progress', [StudentProgressController::class, 'updateLesson']);
        Route::get('progress/modules', [StudentProgressController::class, 'modules']);
    });
});
