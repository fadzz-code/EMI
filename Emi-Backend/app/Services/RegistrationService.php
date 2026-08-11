<?php

namespace App\Services;

use App\Models\RegistrationRequest;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class RegistrationService
{
    public function register(array $data): User
    {
        return DB::transaction(function () use ($data) {
            $user = User::query()->create([
                'full_name' => $data['full_name'],
                'email' => $data['email'],
                'password' => $data['password'],
                'role' => $data['requested_role'],
                'status' => 'pending',
                'privacy_policy_accepted_at' => now(),
                'privacy_policy_version' => $data['privacy_policy_version'],
            ]);

            RegistrationRequest::query()->create([
                'user_id' => $user->id,
                'school_id' => $data['school_id'],
                'class_id' => $data['class_id'],
                'requested_role' => $data['requested_role'],
                'status' => 'pending',
            ]);

            return $user;
        });
    }
}
