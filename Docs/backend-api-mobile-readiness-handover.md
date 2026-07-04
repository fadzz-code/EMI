# Backend/API Mobile Readiness Handover

Last audit scope: Laravel API, Next.js API usage, seeders, config, tests, and current route list under `/api/v1`.

## 1. Executive Summary

EMI already has a Laravel API backend that is suitable as the main backend for a future mobile app. The current Next.js web frontend consumes this same API through bearer-token requests. A separate mobile backend is not needed at this stage.

Recommended mobile direction:

- Laravel Backend = canonical API and data source.
- Next.js Web = existing web frontend.
- Mobile App = new frontend consuming Laravel `/api/v1`.
- First mobile release should focus on the student experience.
- Speaking practice/result flow remains the largest backend/product gap before full mobile production.

## 2. Current Architecture

- Backend: Laravel 12 API in `Emi-Backend`.
- Auth: Laravel Sanctum personal access tokens.
- Web frontend: Next.js in `Emi-Frontend`, configured with `NEXT_PUBLIC_API_BASE_URL` and a shared `apiClient` wrapper.
- Database: PostgreSQL with UUID domain models; pgvector is supported for optional Basis AI vector retrieval.
- Storage: Laravel disks for public/private media and imported sources.
- API version prefix: `/api/v1`.

Mobile should use the same API paths and response shapes as web.

## 3. Authentication Flow

Actual auth routes:

- `POST /api/v1/auth/register` - public registration for student/teacher, pending approval.
- `POST /api/v1/auth/login` - returns Sanctum bearer token.
- `POST /api/v1/auth/logout` - revokes current token.
- `GET /api/v1/auth/me` - current authenticated profile.
- `PATCH /api/v1/auth/me` - update profile fields.
- `PUT /api/v1/auth/password` - update password.
- `POST /api/v1/auth/me/avatar` - upload avatar.
- `DELETE /api/v1/auth/me/avatar` - remove avatar.

Login payload requires:

```json
{
  "email": "siswa@emi.test",
  "password": "password123",
  "device_name": "android-phone"
}
```

Login response includes:

```json
{
  "success": true,
  "message": "Login berhasil.",
  "data": {
    "token": "...",
    "token_type": "Bearer",
    "user": { }
  }
}
```

Mobile must store the token securely and send:

```http
Authorization: Bearer <token>
Accept: application/json
```

## 4. Role Model and Access

Roles found in API behavior:

- `admin`
- `teacher`
- `student`

Route access patterns:

- `/api/v1/admin/*` requires `auth:sanctum` and `role:admin`.
- `/api/v1/teacher/*` requires `auth:sanctum` and `role:teacher`.
- `/api/v1/student/*` requires `auth:sanctum` and `role:student`.
- Several shared class/module/quiz/media/dictionary routes require `auth:sanctum`; policies/services enforce scope by role.
- Public lookup/media routes are under `/api/v1/public/*`.

## 5. API Base URL and Headers

Web default API base URL:

```text
http://localhost:8000/api/v1
```

Frontend environment key:

```text
NEXT_PUBLIC_API_BASE_URL
```

Mobile should configure equivalent per environment.

Required common headers:

```http
Accept: application/json
Authorization: Bearer <token>
Content-Type: application/json
```

For uploads, use `multipart/form-data` and let the client library set the boundary.

## 6. Standard Response Shapes

Success:

```json
{
  "success": true,
  "message": "...",
  "data": {}
}
```

Paginated success:

```json
{
  "success": true,
  "message": "...",
  "data": [],
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 100,
    "last_page": 7
  }
}
```

Error:

```json
{
  "success": false,
  "message": "...",
  "code": "ERROR_CODE",
  "errors": {
    "field": ["..."]
  }
}
```

Validation errors are typically HTTP 422 with `errors` keyed by field.

## 7. Error Handling Pattern

Mobile should handle:

- `401`: token invalid/expired; clear token and show login.
- `403`: role/status/ownership denied.
- `404`: missing entity or scoped data not visible.
- `422`: validation/domain error; show first field error.
- `429`: throttled login/register.
- `5xx`: server error; show generic retry message.

The web client already follows this pattern in `src/lib/api-client.ts`.

## 8. File/Media Storage Flow

Main media routes:

- `POST /api/v1/media` - upload authenticated media.
- `GET /api/v1/media/{id}` - metadata.
- `POST /api/v1/media/{id}/temporary-url` - private temporary URL.
- `DELETE /api/v1/media/{id}` - delete if authorized.
- `GET /api/v1/media/{id}/download` - signed download URL.
- `GET /api/v1/public/media/{id}/content` - public content route.

Media purposes include avatar, question image, lesson image, culture media, document, audio, and speaking recording. Speaking recordings are supported as private media objects, but the higher-level speaking practice/result workflow is not complete.

Relevant `.env.example` keys:

- `MEDIA_PUBLIC_DISK`
- `MEDIA_PRIVATE_DISK`
- `MEDIA_SIGNED_URL_TTL_MINUTES`
- `MEDIA_MAX_IMAGE_KB`
- `MEDIA_MAX_DOCUMENT_KB`
- `MEDIA_MAX_AUDIO_KB`

## 9. Admin Feature Coverage

Backend coverage is broad:

- Registration approval/rejection.
- Dashboard summary.
- Schools/classes/users management.
- Teacher/student class assignment.
- Dictionary categories/entries/import.
- Module/lesson templates and apply-to-class.
- Quiz templates/questions and apply-to-class.
- Culture items/templates and apply-to-class.
- Progress/quiz reports and CSV exports.
- Basis AI knowledge CRUD, publish/archive/delete.
- Link/PDF extraction and page-aware PDF RAG import.

Admin mobile is not recommended for v1 unless explicitly required.

## 10. Teacher Feature Coverage

Backend supports:

- Teacher dashboard summary.
- Teacher scoped class list/details via shared class routes.
- Class students.
- Class modules/lessons CRUD/publish/archive.
- Class culture CRUD/publish/archive.
- Class quizzes/questions CRUD/publish/archive.
- Quiz attempts/report visibility.
- Progress and quiz result reports plus exports.

Teacher speaking result view is not implemented as a dedicated feature.

## 11. Student Feature Coverage

Backend supports:

- Student dashboard.
- Assigned modules and module detail.
- Module start and lesson progress update.
- Progress report and module progress.
- Culture content.
- Dictionary list/detail via shared dictionary routes.
- Student quiz list/detail and quiz attempt lifecycle.
- Basis AI chatbot.
- Profile/avatar/password through auth routes.

Student speaking practice/result flow still needs product/API completion.

## 12. Basis AI / RAG Architecture

Current actual flow:

1. Admin creates manual knowledge, imports link/PDF-to-content, or imports a large PDF as a page-aware RAG source.
2. Page-aware PDF import stores the file and creates an `ai_knowledge_item` with safe placeholder content.
3. Extracted PDF pages are stored separately in `ai_knowledge_source_pages`.
4. Pages are classified as body/table of contents/front matter/copyright/bibliography/empty/low quality.
5. Chunking builds `ai_knowledge_chunks` from searchable body pages, not TOC/front matter pages.
6. Chunks retain metadata such as source URL, source type, page number, page start/end, and page type.
7. Embeddings can be generated later and stored on chunks.
8. Chatbot retrieval order includes dictionary intent first, optional vector retrieval, then keyword fallback.
9. AI provider can polish selected chunks if configured.
10. Default extractive answer exists if no AI provider is available.

Relevant commands:

```cmd
php artisan ai:vector:doctor
php artisan ai:knowledge:reindex
php artisan ai:knowledge:reindex --embed
php artisan ai:knowledge:embed
php artisan ai:knowledge:embed --force
```

Relevant `.env.example` keys:

- `AI_FREE_PROVIDER`
- `AI_FREE_API_KEY`
- `AI_FREE_MODEL`
- `AI_FREE_TIMEOUT_SECONDS`
- `AI_EMBEDDING_PROVIDER`
- `AI_EMBEDDING_API_KEY`
- `AI_EMBEDDING_MODEL`
- `AI_EMBEDDING_BASE_URL`
- `AI_EMBEDDING_DIMENSIONS`
- `AI_EMBEDDING_TIMEOUT_SECONDS`
- `AI_VECTOR_RETRIEVAL_ENABLED`
- `AI_VECTOR_TOP_K`
- `AI_KEYWORD_TOP_K`

Do not ship mobile with any AI secret embedded in the app.

## 13. Dictionary / Vocabulary Architecture

- Admin manages dictionary categories and entries.
- Admin can import CSV/audio ZIP through dictionary import endpoints.
- Students and teachers use `GET /api/v1/dictionary` and `GET /api/v1/dictionary/{id}`.
- Chatbot dictionary retriever has priority for direct dictionary/translation-style questions.
- Dictionary entries may include audio media references.

## 14. Module / Lesson / Quiz Architecture

Admin creates templates, then applies them to classes. Teachers can manage class-scoped modules, lessons, quizzes, and questions. Students consume assigned modules and quizzes through student endpoints.

Key student quiz flow:

1. `GET /api/v1/student/quizzes`
2. `GET /api/v1/student/quizzes/{id}`
3. `POST /api/v1/class-quizzes/{id}/attempts`
4. `GET /api/v1/quiz-attempts/{id}`
5. `PUT /api/v1/quiz-attempts/{id}/answers/{question_id}`
6. `POST /api/v1/quiz-attempts/{id}/submit`

## 15. Culture Content Architecture

- Admin manages global culture items and templates.
- Admin/teacher can apply or manage class culture items.
- Student reads culture through `GET /api/v1/student/culture`.
- Culture media uses the media system and `culture_media` purpose.

## 16. Speaking Feature Current Gap

What exists:

- `speaking_recording` is a valid media purpose.
- Student can upload private media with purpose `speaking_recording` through generic media upload.
- Private speaking recordings are protected from other students and teachers by media authorization tests.
- Dashboards expose `capabilities.speaking_reports = false` and `speaking_summary = null`.

What is missing/not visible in routes:

- No dedicated speaking practice route group.
- No speaking prompt/attempt/result model API found in route list.
- No student speaking attempt final submission/result endpoint found.
- No teacher speaking results endpoint found.

Conclusion: speaking media storage foundation exists, but the actual speaking practice and result workflow is not mobile-ready.

## 17. Mobile Readiness Matrix

| Feature | Role | Backend/API Status | Web Status | Mobile Ready? | Notes / Missing Work |
|---|---|---|---|---|---|
| Auth/Login | All | Ready | Ready | Yes | Use Sanctum bearer token and required `device_name`. |
| Admin Dashboard | Admin | Ready | Mostly OK | Not v1 priority | Admin mobile not recommended first. |
| Teacher Dashboard | Teacher | Ready | Mostly OK | Later | Useful if teacher app is required. |
| Student Dashboard | Student | Ready | Mostly OK | Yes | Recommended first screen after login. |
| Modules | Student/Teacher/Admin | Ready | Mostly OK | Yes for student | Student module consumption is ready. |
| Lessons | Student/Teacher/Admin | Ready | Mostly OK | Yes for student | Include content URL handling. |
| Dictionary | All auth roles | Ready | Mostly OK | Yes | Good early mobile feature. |
| Dictionary Detail | All auth roles | Ready | Mostly OK | Yes | Include audio playback if media exists. |
| Quiz List | Student | Ready | Mostly OK | Yes | Student endpoints ready. |
| Quiz Attempt | Student | Ready | Mostly OK | Yes | Start/save/submit endpoints exist. |
| Quiz Result | Student/Teacher/Admin | Ready | Mostly OK | Yes | Student report endpoints exist. |
| Culture | Student/Teacher/Admin | Ready | Mostly OK | Yes | Student read path ready. |
| Basis AI Chatbot | Student | Ready | Mostly OK | Yes | RAG/dictionary/keyword fallback ready for demo. |
| Progress | Student/Teacher/Admin | Ready | Mostly OK | Yes | Reports available; CSV exports less relevant to mobile. |
| Profile | All | Ready | Ready | Yes | Includes avatar/password update. |
| Speaking Practice | Student | Partial | Gap remains | No | Generic upload exists, no dedicated attempt/result flow. |
| Speaking Results | Student | Missing/partial | Gap remains | No | Needs backend/API completion. |
| Teacher Speaking Results | Teacher | Missing | Gap remains | No | Dashboard explicitly reports unavailable. |
| Admin Basis AI | Admin | Ready | Mostly OK | Not v1 priority | Keep web-first unless required. |
| Admin PDF RAG Import | Admin | Ready | OK | Not v1 priority | Web admin handles this. |
| Admin User/Class Management | Admin | Ready | Mostly OK | Not v1 priority | Web admin sufficient. |

## 18. Mobile API Risks

- Speaking feature is not complete.
- Some shared authenticated routes rely on policy/service scoping; mobile should not infer visibility from path alone.
- File/media playback needs careful handling of public vs temporary URLs.
- AI endpoints can be slower for large RAG contexts; mobile should show loading states and retry messaging.
- Token storage must be secure on device.
- API errors are Indonesian; mobile should preserve or map messages consistently.
- Vector/AI behavior depends on backend env and server commands, not mobile.

## 19. Recommended Mobile Build Order

1. Auth/Login + secure token storage.
2. Student dashboard.
3. Modules and lessons.
4. Dictionary and dictionary detail.
5. Quizzes and results.
6. Culture.
7. Basis AI chatbot.
8. Progress/profile.
9. Speaking practice after backend gap is resolved.
10. Teacher mobile features if required later.
11. Admin mobile only if explicitly needed.

First mobile version should be a student app, not full admin.

## 20. Backend Gaps Before Mobile Production

Highest priority gaps:

- Dedicated speaking practice API: prompt/list, attempt create, recording attach, scoring/result, retry/history.
- Teacher speaking result visibility and reports.
- Mobile-specific API contract examples for uploads and quiz answers.
- Production media URL strategy confirmation for private files.
- Push notification strategy if needed later.

## 21. Demo Accounts and Local Setup Notes

Known demo accounts from current project convention:

```text
admin@emi.test / password123
guru@emi.test / password123
siswa@emi.test / password123
```

Seeder:

```cmd
php artisan db:seed --class=DevDemoDataSeeder
```

Useful local commands:

```cmd
php artisan migrate
php artisan test
php artisan ai:vector:doctor
php artisan ai:knowledge:reindex
```

Do not copy local `.env` secrets into mobile or docs. Use `.env.example` keys only.

## 22. Verification Status

For this audit batch, required verification commands are:

```cmd
php artisan route:list --path=api/v1
php artisan test
composer audit
php artisan ai:vector:doctor
```

Known dependency advisories may remain for `guzzlehttp/guzzle` and `guzzlehttp/psr7`.

## 23. Recommended Next Backend Batches

1. Speaking practice/result backend completion.
2. Teacher speaking results API and report views.
3. Mobile API examples/OpenAPI-style contract for student app.
4. Media URL/mobile playback hardening.
5. Optional mobile-focused smoke tests for auth, modules, quiz, dictionary, chatbot.
