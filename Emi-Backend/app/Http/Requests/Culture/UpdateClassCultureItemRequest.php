<?php

namespace App\Http\Requests\Culture;

class UpdateClassCultureItemRequest extends StoreClassCultureItemRequest
{
    public function rules(): array
    {
        return collect(parent::rules())->map(function (array $rules) {
            return array_values(array_diff($rules, ['required']));
        })->all();
    }
}
