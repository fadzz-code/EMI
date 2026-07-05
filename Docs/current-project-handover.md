# EMI Current Project Handover

## 1. Project Identity

EMI / E-Learning Mekongga Indonesia is a learning platform for Bahasa Mekongga and related cultural learning.

Repository root: `D:\!Kerjaan\EMI`

Main components:

- `Emi-Backend` — Laravel 12 API backend and canonical data source.
- `Emi-Frontend` — Next.js web frontend.
- `Emi-Speaking-AI` — internal FastAPI speech analysis service.
- `Docs` — project documentation and handover material.

Do not use or modify `D:\!Kerjaan\EMI2` for this project.

## 2. Product Goal

EMI aims to support:

- Bahasa Mekongga learning.
- Dictionary and vocabulary learning.
- Modules and lessons.
- Quizzes and learning assessment.
- Culture content.
- AI chatbot using Basis AI/RAG.
- Speaking practice with AI-assisted initial scoring and teacher review.

## 3. Target Users

| User | Goal |
|---|---|
| Admin | Manage users, classes, content templates, dictionary, culture, reports, and Basis AI knowledge. |
| Teacher | Manage assigned classes, learning content, quizzes, culture content, reports, and speaking review. |
| Student | Learn through modules, lessons, quizzes, dictionary, culture, chatbot, progress pages, and speaking practice. |
| Future mobile user | Primarily student first, consuming the same Laravel API. |

## 4. Current Architecture

```text
Next.js Web / Future Mobile
        ↓
Laravel API /api/v1
        ↓
PostgreSQL + storage + queue
        ↓
Internal Python Speaking AI only for speaking analysis
```

Architecture rules:

- Laravel Backend is the main API backend and source of truth.
- Next.js Frontend is the current web frontend.
- Python Speaking AI is an internal speech analysis service only.
- Future mobile app should consume the Laravel API.
- Do not recommend building a new backend for mobile unless a specific future requirement proves it necessary.
- Frontend and mobile must never call Python Speaking AI directly.

## 5. Repository Structure

```text
EMI/
├── AGENTS.md
├── Docs/
│   ├── current-project-handover.md
│   ├── progressbar.md
│   ├── ai-workflow-protocol.md
│   ├── backend-api-mobile-readiness-handover.md
│   ├── api-v1-route-inventory.md
│   └── speaking-ai-integration.md
├── Emi-Backend/
│   ├── app/Http/Controllers/Api
│   ├── app/Http/Requests
│   ├── app/Models
│   ├── app/Services
│   ├── database/migrations
│   ├── database/seeders
│   └── routes/api.php
├── Emi-Frontend/
│   ├── src/app
│   ├── src/features
│   └── src/lib
└── Emi-Speaking-AI/
    ├── main.py
    └── README.md
```

## 6. Local Development Services

Python Speaking AI:

```cmd
cd /d "D:\!Kerjaan\EMI\Emi-Speaking-AI"
.venv\Scripts\activate
python -m uvicorn main:app --host 127.0.0.1 --port 8001
```

Laravel backend:

```cmd
cd /d "D:\!Kerjaan\EMI\Emi-Backend"
php artisan serve --host=127.0.0.1 --port=8000
```

Queue worker when `QUEUE_CONNECTION=database`:

```cmd
cd /d "D:\!Kerjaan\EMI\Emi-Backend"
php artisan queue:work
```

Next frontend:

```cmd
cd /d "D:\!Kerjaan\EMI\Emi-Frontend"
npm.cmd run dev
```

## 7. Authentication and Demo Accounts

Auth uses Laravel Sanctum bearer tokens.

Common demo accounts, if seeded:

```text
admin@emi.test / password123
guru@emi.test / password123
siswa@emi.test / password123
```

Seeder:

```cmd
cd /d "D:\!Kerjaan\EMI\Emi-Backend"
php artisan db:seed --class=DevDemoDataSeeder
```

## 8. Role-Based Feature Summary

| Role | Feature | Status | Notes |
|---|---|---|---|
| Admin | Dashboard | Mostly Done | Web route and API summary exist. |
| Admin | User management | Mostly Done | Includes approvals and status management. |
| Admin | Class management | Mostly Done | School/class plus teacher/student assignment. |
| Admin | Module/lesson management | Mostly Done | Template CRUD and apply-to-class flow. |
| Admin | Quiz management | Mostly Done | Template/question CRUD and apply-to-class flow. |
| Admin | Dictionary management/import | Mostly Done | CSV preview/confirm, ZIP audio, duplicate strategies. |
| Admin | Culture templates/global culture | Mostly Done | Template/global content routes and web pages exist. |
| Admin | Basis AI knowledge base | Mostly Done | Manual/link/PDF knowledge and publish/archive. |
| Admin | PDF RAG import | Mostly Done | Page-aware ingestion and source pages/chunks exist. |
| Admin | Source extraction | Mostly Done | Link and PDF extraction endpoints exist. |
| Admin | Media handling | Mostly Done | Public/private media, avatar, signed/private URLs. |
| Admin | Reports | Mostly Done | Progress and quiz reports plus CSV exports. |
| Teacher | Dashboard | Mostly Done | Web and API exist. |
| Teacher | Assigned classes/students | Mostly Done | Scoped class/student pages and API exist. |
| Teacher | Modules/lessons | Mostly Done | Teacher can manage class modules/lessons. |
| Teacher | Quizzes | Mostly Done | Teacher can manage class quizzes and results. |
| Teacher | Culture class content | Mostly Done | Class culture management exists. |
| Teacher | Speaking results/review | Needs Manual QA | API and web page exist; verify end-to-end with real audio. |
| Teacher | Profile | Mostly Done | Web profile exists. |
| Student | Dashboard | Mostly Done | Web and API exist. |
| Student | Modules | Mostly Done | Student module list/detail and start flow. |
| Student | Lesson detail | Mostly Done | Lesson/progress flows exist. |
| Student | Dictionary | Mostly Done | List/search and detail pages. |
| Student | Dictionary detail | Mostly Done | Detail route exists. |
| Student | Speaking practice | Needs Manual QA | Web recording/upload integrated; browser MIME fix exists in latest local HEAD. |
| Student | Speaking results | Needs Manual QA | Results page and polling exist; verify after real submissions. |
| Student | Quizzes | Mostly Done | List/detail/attempt/result pages. |
| Student | Quiz attempt | Mostly Done | Attempt lifecycle exists. |
| Student | Quiz result | Mostly Done | Result page exists. |
| Student | Culture | Mostly Done | Student culture feed exists. |
| Student | Basis AI Chatbot | Mostly Done | Demo-ready with RAG fallback. |
| Student | Progress | Mostly Done | Progress page/report exists. |
| Student | Profile | Mostly Done | Profile page exists. |
| Future Mobile | Student app | Not Started | Should use Laravel API; no separate backend. |

## 9. Admin Features

Admin web is mostly OK. It includes dashboard, approvals, school/class management, users, module templates, quiz templates, dictionary, dictionary import, culture templates/global culture, Basis AI knowledge base, PDF RAG import, settings, and progress/report pages.

## 10. Teacher Features

Teacher web is mostly OK. It includes dashboard, classes, class students, class modules/lessons, class quizzes, quiz results, class culture, media, progress reports, speaking results/review, and profile.

## 11. Student Features

Student web is mostly OK. It includes dashboard, modules, lessons, dictionary, dictionary detail, quizzes, quiz attempts, quiz results, culture, chatbot, progress, profile, speaking practice, and speaking results.

## 12. Basis AI / RAG Current State

Basis AI/RAG is demo-ready.

Current capabilities:

- Manual knowledge items.
- Link extraction.
- PDF extraction.
- Page-aware PDF ingestion.
- Source pages.
- Knowledge chunks.
- Embedding persistence.
- pgvector readiness diagnostics.
- Vector retrieval fallback.
- Keyword fallback.
- Dictionary priority for dictionary-like questions.
- PDF retrieval quality filtering for TOC, front matter, bibliography, low-quality/OCR noise, and non-searchable pages.
- Optional AI answer provider.
- Default extractive fallback when no provider is configured or usable.

Useful commands:

```cmd
php artisan ai:vector:doctor
php artisan ai:knowledge:reindex
php artisan ai:knowledge:embed
php artisan ai:knowledge:embed --force
```

Do not include real API keys in docs, prompts, commits, or logs.

## 13. Dictionary Current State

Dictionary is mostly done:

- Category and entry management.
- Indonesian/English/Mekongga vocabulary fields.
- Search/list/detail API and web pages.
- Public audio media support for entries.
- CSV import template, preview, confirm, history, row errors.
- ZIP audio matching by exact filename.
- Duplicate handling strategies.
- Dictionary retriever is prioritized in chatbot flow.

## 14. Module/Lesson/Quiz Current State

Modules and lessons are mostly done:

- Admin templates and teacher class copies.
- Publish/archive and ordering.
- Lesson content supports text and media/link types through the media/content flow.
- Student module detail and progress update flows.

Quizzes are mostly done:

- Admin templates and teacher class quizzes.
- Questions/options.
- Student quiz list/detail/attempt/result flow.
- Auto grading and reports.
- Result visibility rules.

## 15. Culture Content Current State

Culture content is mostly done:

- Admin global culture items.
- Admin culture templates.
- Apply template to class.
- Teacher class culture management.
- Student culture feed.
- Media-backed culture content.

## 16. Speaking Current State

Speaking is recently integrated end-to-end and needs manual QA.

Model:

```text
Student records/submits audio
→ Laravel validates and stores private media
→ Laravel creates speaking attempt
→ Queue job calls internal Python AI
→ Python returns transcription/score/alignment
→ Laravel stores AI result/status
→ Teacher reviews and can add manual score/feedback
```

Important notes:

- Speaking is AI-assisted initial scoring plus teacher manual review.
- Python is the internal analysis engine only.
- Frontend and mobile should call Laravel, never Python directly.
- Current scoring uses Indonesian Wav2Vec2 transcription plus Levenshtein-style similarity, not final Mekongga phonetic assessment.
- Teacher review remains important and should be treated as authoritative correction.
- Audio is stored as private media; raw binary is not stored in DB.
- Latest local HEAD contains a browser audio upload validation fix accepting safe WebM/audio MIME variants.

Local speaking QA checklist:

```text
1. Run Python Speaking AI on 127.0.0.1:8001.
2. Run Laravel backend on 127.0.0.1:8000.
3. Run queue worker if QUEUE_CONNECTION=database.
4. Run Next frontend.
5. Login siswa.
6. Open Latihan Speaking.
7. Record audio.
8. Submit.
9. Confirm no validation.mimetypes error.
10. Confirm attempt progresses pending/processing/completed or failed with clear AI error.
11. Login guru.
12. Open speaking results.
13. Review attempt and submit teacher feedback.
14. Confirm student can see status/feedback/result.
```

## 17. Mobile Readiness Summary

Laravel API is the backend for future mobile. A separate backend is not needed now.

Mobile recommendation:

- Build student-first.
- Use `/api/v1` Laravel endpoints.
- Store Sanctum token securely.
- Implement auth, dashboard, modules, lessons, dictionary, quizzes, culture, progress, and chatbot first.
- Add speaking only after web/manual QA is stable.
- Do not call Python directly from mobile.

See also:

- `Docs/backend-api-mobile-readiness-handover.md`
- `Docs/api-v1-route-inventory.md`

## 18. Current Known Issues

- Speaking requires manual QA with real browser recording, queue worker, Laravel, and Python service.
- Python Speaking AI is approximate because it uses Indonesian STT, not a dedicated Mekongga phonetic model.
- Production process management for queue worker and Python AI service still needs setup.
- Composer audit currently reports known advisories in `guzzlehttp/guzzle` and `guzzlehttp/psr7` in recent checks.
- Some older docs are stale and may describe pre-Next/pre-speaking state; prefer this handover plus source code for current state.

The earlier `validation.mimetypes` speaking issue should not be listed as unresolved when local HEAD includes `79bbbe9 fix: accept browser speaking audio uploads` or a later equivalent fix.

## 19. Current Verification Status

Recent known verification:

- Full backend test suite passed after speaking MIME fix: 177 tests.
- Frontend lint passed with existing `<img>` warnings.
- Frontend build passed.
- Required route inventory should be regenerated with `php artisan route:list --path=api/v1` when API docs are updated.

Always trust current command output over this section if it differs.

## 20. Safe Development Rules

- Run `git status --short` before every task.
- Stop if unrelated dirty source files exist.
- Do not touch `D:\!Kerjaan\EMI2`.
- Do not push, merge, tag, switch branch, or add remotes unless explicitly asked.
- Never use `git add .`.
- Never use `git clean`.
- Do not delete `Emi-Speaking-AI/.venv`.
- Do not commit secrets, `.env` values, API keys, tokens, or private credentials.
- Keep Laravel as the canonical API/data source.
- Do not change behavior during documentation-only tasks.
- If task changes project status, update `Docs/progressbar.md` in the same commit when safe.

## 21. Recommended Next Steps

1. Run manual QA for speaking end-to-end with real browser recording.
2. Confirm teacher speaking review and student result visibility.
3. Update `Docs/api-v1-route-inventory.md` speaking section if route inventory docs are needed for mobile planning.
4. Polish Basis AI citation display and admin embedding workflow if required by user/client.
5. Plan student-first mobile app against Laravel `/api/v1` after web QA is stable.
6. Prepare production process management for queue worker and Python Speaking AI.

## 22. How To Continue From A New GPT Chat

In a new GPT chat or AI session:

1. State that this is the original EMI project at `D:\!Kerjaan\EMI`.
2. Ask the AI to read:
   - `Docs/current-project-handover.md`
   - `Docs/progressbar.md`
   - `Docs/ai-workflow-protocol.md`
   - any domain-specific docs for the task.
3. Ask GPT Chat to plan and write an exact OpenCode prompt.
4. Paste the prompt into OpenCode.
5. OpenCode executes in the repository and commits only requested exact files.
6. Copy OpenCode final report back to GPT Chat.
7. GPT Chat evaluates and decides the next step.
