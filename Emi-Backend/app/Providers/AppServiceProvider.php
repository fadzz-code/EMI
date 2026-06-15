<?php

namespace App\Providers;

use App\Models\RegistrationRequest;
use App\Policies\RegistrationRequestPolicy;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Gate::policy(RegistrationRequest::class, RegistrationRequestPolicy::class);

        RateLimiter::for('emi-login', function (Request $request) {
            $email = Str::lower((string) $request->input('email', ''));

            return Limit::perMinute(5)->by($request->ip().'|'.$email);
        });

        RateLimiter::for('emi-register', function (Request $request) {
            return Limit::perMinute(10)->by($request->ip());
        });
    }
}
