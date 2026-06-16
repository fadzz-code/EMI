<?php

namespace App\Providers;

use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\DictionaryImportJob;
use App\Models\MediaFile;
use App\Models\RegistrationRequest;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\User;
use App\Policies\DictionaryCategoryPolicy;
use App\Policies\DictionaryEntryPolicy;
use App\Policies\DictionaryImportJobPolicy;
use App\Policies\MediaFilePolicy;
use App\Policies\RegistrationRequestPolicy;
use App\Policies\SchoolClassPolicy;
use App\Policies\SchoolPolicy;
use App\Policies\UserPolicy;
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
        Gate::policy(MediaFile::class, MediaFilePolicy::class);
        Gate::policy(DictionaryCategory::class, DictionaryCategoryPolicy::class);
        Gate::policy(DictionaryEntry::class, DictionaryEntryPolicy::class);
        Gate::policy(DictionaryImportJob::class, DictionaryImportJobPolicy::class);
        Gate::policy(School::class, SchoolPolicy::class);
        Gate::policy(SchoolClass::class, SchoolClassPolicy::class);
        Gate::policy(User::class, UserPolicy::class);

        RateLimiter::for('emi-login', function (Request $request) {
            $email = Str::lower((string) $request->input('email', ''));

            return Limit::perMinute(5)->by($request->ip().'|'.$email);
        });

        RateLimiter::for('emi-register', function (Request $request) {
            return Limit::perMinute(10)->by($request->ip());
        });
    }
}
