<?php

namespace Database\Seeders;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

trait DemoSeederSupport
{
    protected function upsertModel(string $modelClass, array $attributes, array $values = []): Model
    {
        $model = $modelClass::query()->where($attributes)->first();

        if (! $model) {
            $model = new $modelClass;
            $model->id = (string) Str::uuid();
            $model->fill($attributes);
        }

        $model->fill($values);
        $model->save();

        return $model->refresh();
    }
}
