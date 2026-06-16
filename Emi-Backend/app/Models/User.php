<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, HasUuids, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'full_name',
        'email',
        'email_verified_at',
        'password',
        'role',
        'status',
        'phone',
        'avatar_media_id',
        'approved_by',
        'approved_at',
        'rejected_reason',
        'last_login_at',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'approved_at' => 'datetime',
            'last_login_at' => 'datetime',
        ];
    }

    public function approvedBy(): BelongsTo
    {
        return $this->belongsTo(self::class, 'approved_by');
    }

    public function approvedUsers(): HasMany
    {
        return $this->hasMany(self::class, 'approved_by');
    }

    public function createdSchools(): HasMany
    {
        return $this->hasMany(School::class, 'created_by');
    }

    public function createdClasses(): HasMany
    {
        return $this->hasMany(SchoolClass::class, 'created_by');
    }

    public function registrationRequest(): HasOne
    {
        return $this->hasOne(RegistrationRequest::class);
    }

    public function teacherClassAssignments(): HasMany
    {
        return $this->hasMany(TeacherClassAssignment::class, 'teacher_id');
    }

    public function studentClassMemberships(): HasMany
    {
        return $this->hasMany(StudentClassMembership::class, 'student_id');
    }

    public function activeTeacherClassAssignment(): HasOne
    {
        return $this->hasOne(TeacherClassAssignment::class, 'teacher_id')->where('is_active', true);
    }

    public function activeStudentClassMembership(): HasOne
    {
        return $this->hasOne(StudentClassMembership::class, 'student_id')->where('is_active', true);
    }

    public function createdDictionaryCategories(): HasMany
    {
        return $this->hasMany(DictionaryCategory::class, 'created_by');
    }

    public function createdDictionaryEntries(): HasMany
    {
        return $this->hasMany(DictionaryEntry::class, 'created_by');
    }

    public function dictionaryImportJobs(): HasMany
    {
        return $this->hasMany(DictionaryImportJob::class, 'uploaded_by');
    }

    public function avatarMedia(): BelongsTo
    {
        return $this->belongsTo(MediaFile::class, 'avatar_media_id');
    }

    public function activeClassId(): ?string
    {
        return match ($this->role) {
            'teacher' => $this->teacherClassAssignments()->where('is_active', true)->value('class_id'),
            'student' => $this->studentClassMemberships()->where('is_active', true)->value('class_id'),
            default => null,
        };
    }

    public function activeSchoolId(): ?string
    {
        $classId = $this->activeClassId();

        return $classId ? SchoolClass::query()->whereKey($classId)->value('school_id') : null;
    }
}
