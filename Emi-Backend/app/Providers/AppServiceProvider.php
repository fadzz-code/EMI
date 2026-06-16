<?php

namespace App\Providers;

use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\DictionaryImportJob;
use App\Models\LessonProgress;
use App\Models\LessonTemplate;
use App\Models\MediaFile;
use App\Models\ModuleProgress;
use App\Models\ModuleTemplate;
use App\Models\RegistrationRequest;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\User;
use App\Policies\ClassLessonPolicy;
use App\Policies\ClassModulePolicy;
use App\Policies\DictionaryCategoryPolicy;
use App\Policies\DictionaryEntryPolicy;
use App\Policies\DictionaryImportJobPolicy;
use App\Policies\LessonProgressPolicy;
use App\Policies\LessonTemplatePolicy;
use App\Policies\MediaFilePolicy;
use App\Policies\ModuleProgressPolicy;
use App\Policies\ModuleTemplatePolicy;
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
        Gate::policy(ModuleTemplate::class, ModuleTemplatePolicy::class);
        Gate::policy(LessonTemplate::class, LessonTemplatePolicy::class);
        Gate::policy(ClassModule::class, ClassModulePolicy::class);
        Gate::policy(ClassLesson::class, ClassLessonPolicy::class);
        Gate::policy(LessonProgress::class, LessonProgressPolicy::class);
        Gate::policy(ModuleProgress::class, ModuleProgressPolicy::class);
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
