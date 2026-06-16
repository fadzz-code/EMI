<?php

namespace App\Models;

use Database\Factories\SchoolClassFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class SchoolClass extends Model
{
    /** @use HasFactory<SchoolClassFactory> */
    use HasFactory, HasUuids;

    protected $table = 'classes';

    protected $fillable = [
        'school_id',
        'name',
        'grade_level',
        'academic_year',
        'status',
        'created_by',
    ];

    public function school(): BelongsTo
    {
        return $this->belongsTo(School::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function registrationRequests(): HasMany
    {
        return $this->hasMany(RegistrationRequest::class, 'class_id');
    }

    public function teacherAssignments(): HasMany
    {
        return $this->hasMany(TeacherClassAssignment::class, 'class_id');
    }

    public function studentMemberships(): HasMany
    {
        return $this->hasMany(StudentClassMembership::class, 'class_id');
    }

    public function activeTeacherAssignment(): HasOne
    {
        return $this->hasOne(TeacherClassAssignment::class, 'class_id')->where('is_active', true);
    }

    public function activeStudentMemberships(): HasMany
    {
        return $this->hasMany(StudentClassMembership::class, 'class_id')->where('is_active', true);
    }

    public function classModules(): HasMany
    {
        return $this->hasMany(ClassModule::class, 'class_id')->orderBy('sort_order');
    }
}
