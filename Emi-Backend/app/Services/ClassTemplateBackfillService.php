<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ModuleTemplate;
use App\Models\QuizTemplate;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Http\Request;

class ClassTemplateBackfillService
{
    public function __construct(
        private readonly ModuleTemplateApplyService $moduleTemplateApplyService,
        private readonly QuizTemplateApplyService $quizTemplateApplyService,
    ) {}

    public function backfill(SchoolClass $schoolClass, User $teacher, Request $request): void
    {
        foreach (ModuleTemplate::query()->where('status', 'published')->cursor() as $template) {
            $this->ensureApplied($this->moduleTemplateApplyService->apply($template, [$schoolClass->id], $teacher, $request));
        }

        foreach (QuizTemplate::query()->where('status', 'published')->cursor() as $template) {
            $this->ensureApplied($this->quizTemplateApplyService->apply($template, [$schoolClass->id], $teacher, $request));
        }
    }

    private function ensureApplied(array $summary): void
    {
        if ($summary['failed']) {
            throw new ApiException('Backfill template kelas gagal.', $summary['failed'][0]['reason'], 409);
        }
    }
}
