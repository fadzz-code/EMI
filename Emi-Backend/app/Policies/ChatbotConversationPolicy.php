<?php

namespace App\Policies;

use App\Models\ChatbotConversation;
use App\Models\User;

class ChatbotConversationPolicy
{
    private function allowedRole(User $user): bool
    {
        return in_array($user->role, ['student', 'teacher'], true);
    }

    public function viewAny(User $user): bool
    {
        return $this->allowedRole($user);
    }

    public function view(User $user, ChatbotConversation $conversation): bool
    {
        return $this->allowedRole($user) && $conversation->user_id === $user->id;
    }

    public function create(User $user): bool
    {
        return $this->allowedRole($user);
    }

    public function update(User $user, ChatbotConversation $conversation): bool
    {
        return $this->allowedRole($user) && $conversation->user_id === $user->id;
    }

    public function delete(User $user, ChatbotConversation $conversation): bool
    {
        return $this->allowedRole($user) && $conversation->user_id === $user->id;
    }
}
