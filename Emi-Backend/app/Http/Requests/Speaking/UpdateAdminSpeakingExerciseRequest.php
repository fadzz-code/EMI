<?php

namespace App\Http\Requests\Speaking;

class UpdateAdminSpeakingExerciseRequest extends StoreAdminSpeakingExerciseRequest
{
    public function rules(): array
    {
        $rules = parent::rules();
        $rules['title'][0] = 'sometimes';
        $rules['target_text'][0] = 'sometimes';

        return $rules;
    }
}
