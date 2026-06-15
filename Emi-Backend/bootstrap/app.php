<?php

use App\Exceptions\ApiException;
use App\Helpers\ApiResponse;
use App\Http\Middleware\RoleMiddleware;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'role' => RoleMiddleware::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (AuthenticationException $e, $request) {
            if (! $request->expectsJson() && ! $request->is('api/*')) {
                return null;
            }

            return ApiResponse::error('Anda belum login atau token tidak valid.', 'UNAUTHENTICATED', 401);
        });

        $exceptions->render(function (AuthorizationException $e, $request) {
            if (! $request->expectsJson() && ! $request->is('api/*')) {
                return null;
            }

            return ApiResponse::error('Anda tidak memiliki izin untuk melakukan tindakan ini.', 'FORBIDDEN', 403);
        });

        $exceptions->render(function (ValidationException $e, $request) {
            if (! $request->expectsJson() && ! $request->is('api/*')) {
                return null;
            }

            return ApiResponse::error('Data yang diberikan tidak valid.', 'VALIDATION_ERROR', 422, $e->errors());
        });

        $exceptions->render(function (NotFoundHttpException $e, $request) {
            if (! $request->expectsJson() && ! $request->is('api/*')) {
                return null;
            }

            return ApiResponse::error('Data tidak ditemukan.', 'NOT_FOUND', 404);
        });

        $exceptions->render(function (ApiException $e, $request) {
            return ApiResponse::error($e->getMessage(), $e->errorCode, $e->statusCode, $e->errors);
        });
    })->create();
