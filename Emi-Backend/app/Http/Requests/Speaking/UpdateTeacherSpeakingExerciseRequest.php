<?php

namespace App\Http\Requests\Speaking;

class UpdateTeacherSpeakingExerciseRequest extends StoreTeacherSpeakingExerciseRequest
{
    public function rules(): array
    {
        $rules = parent::rules();
        $rules['classroom_id'][0] = 'sometimes';
        $rules['title'][0] = 'sometimes';
        $rules['target_text'][0] = 'sometimes';

        return $rules;
    }
}
