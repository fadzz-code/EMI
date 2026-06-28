<?php

namespace App\Http\Requests\Culture;

class UpdateCultureTemplateItemRequest extends StoreCultureTemplateItemRequest
{
    public function rules(): array
    {
        return collect(parent::rules())->map(function (array $rules) {
            return array_values(array_diff($rules, ['required']));
        })->all();
    }
}
