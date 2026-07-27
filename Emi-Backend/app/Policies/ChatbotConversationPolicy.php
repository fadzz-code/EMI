<?php

namespace App\Policies;

use App\Models\ChatbotConversation;
use App\Models\User;

class ChatbotConversationPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->role === 'student';
    }

    public function view(User $user, ChatbotConversation $conversation): bool
    {
        return $user->role === 'student' && $conversation->user_id === $user->id;
    }

    public function create(User $user): bool
    {
        return $user->role === 'student';
    }

    public function update(User $user, ChatbotConversation $conversation): bool
    {
        return $user->role === 'student' && $conversation->user_id === $user->id;
    }

    public function delete(User $user, ChatbotConversation $conversation): bool
    {
        return $user->role === 'student' && $conversation->user_id === $user->id;
    }
}
