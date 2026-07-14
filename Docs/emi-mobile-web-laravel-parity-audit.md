# EMI Mobile Web-Laravel Parity Audit

Tanggal: 2026-07-14  
Branch target: `feature/flutter-mobile`  
Scope: EMI Web (`Emi-Frontend`), Laravel API (`Emi-Backend`), Flutter Mobile (`Emi-Mobile`)  
Status: audit only; tidak ada CRUD/fitur besar baru.

## Source evidence utama

- Web routes/navigation: `Emi-Frontend/src/lib/routes.ts`, `Emi-Frontend/src/app/**`, `Emi-Frontend/src/features/**`
- Web API client: `Emi-Frontend/src/lib/api-client.ts`, feature services under `Emi-Frontend/src/features/**/**/*service.ts`
- Laravel routes: `Emi-Backend/routes/api.php`
- Laravel response envelope: `Emi-Backend/app/Helpers/ApiResponse.php`
- Laravel middleware/errors: `Emi-Backend/bootstrap/app.php`, `Emi-Backend/app/Http/Middleware/RoleMiddleware.php`
- Laravel policies: `Emi-Backend/app/Providers/AppServiceProvider.php`, `Emi-Backend/app/Policies/**`
- Flutter router/auth/network: `Emi-Mobile/lib/app/router/app_router.dart`, `Emi-Mobile/lib/features/auth/**`, `Emi-Mobile/lib/core/network/dio_provider.dart`, `Emi-Mobile/lib/core/storage/secure_token_storage.dart`
- Flutter tests: `Emi-Mobile/test/**`

## Status taxonomy

Only these statuses are used: `PARITY_COMPLETE`, `PARTIAL`, `READ_ONLY`, `UI_ONLY`, `PLACEHOLDER`, `MISSING`, `BROKEN`, `BLOCKED_BY_BACKEND`, `WEB_ONLY_BY_DESIGN`, `NOT_TESTED`.

---

# A. Audit Autentikasi

## Auth feature matrix

| Fitur Auth | Web Route/UI | Endpoint Laravel | Method | Request | Response | Middleware/Policy | Flutter Status | Test | Gap |
|---|---|---|---|---|---|---|---|---|---|
| Login | `/login`, `LoginForm` | `/auth/login` | POST | `email`, `password`, `device_name` | `token`, `token_type`, `user` | `throttle:emi-login` | PARTIAL | UNIT/WIDGET | Mobile login real API, distinguishes admin/teacher/student and account states; device name still static. |
| Register role selection | `/register` | `/auth/register` | POST | `requested_role` teacher/student | pending user/request | `throttle:emi-register` | PARTIAL | UNIT/WIDGET | Mobile `/register` supports teacher/student, public school/class lookup, pending result. |
| Register Guru | `/register/teacher` | `/auth/register` | POST | `full_name`, `email`, password confirmed, `school_id`, `class_id`, role teacher | pending request | `RegisterRequest` | PARTIAL | UNIT/WIDGET | Mobile uses shared register screen with role Guru. |
| Register Siswa | `/register/student` | `/auth/register` | POST | same, role student | pending request | `RegisterRequest` | PARTIAL | UNIT/WIDGET | Mobile uses shared register screen with role Siswa. |
| Pending registration | `/pending-approval` | login/me status | GET/POST | n/a | user/status | AuthService blocks unapproved login | PARTIAL | auth repo/widget | Mobile has dedicated account status UX. |
| Admin approval | `/admin/approvals` | `/admin/registration-requests/{id}/approve` | POST | approve payload | request/user updated | auth + role admin + policy | PARTIAL | admin tests | Mobile has approval screens/API; parity not proven for all fields. |
| Rejected registration | `/admin/approvals`, `/pending-approval` | `/admin/registration-requests/{id}/reject` | POST | reason | request rejected | auth + role admin + policy | PARTIAL | admin/auth tests | Mobile has dedicated rejected account UX after login/status error. |
| Account activation | Admin users/status | `/users/{id}/status` | PATCH | status | user | auth + UserPolicy | PARTIAL | admin tests | Mobile admin users module still missing; auth state handles status. |
| Disabled account | Web auth/user status checks | `/auth/login`, `/auth/me` | POST/GET | token/login | user/status or forbidden | AuthService/status | PARTIAL | auth repo | Mobile has dedicated disabled account UX; backend rejects inactive login. |
| Forgot password | Not found in web auth routes | `/auth/forgot-password` | POST | `email` | safe generic success | `throttle:emi-login` | PARITY_COMPLETE | backend + mobile unit | Backend and mobile implemented; Web remains absent but mobile no longer blocked. |
| Reset password | Not found | `/auth/reset-password` | POST | `email`, `token`, `password`, `password_confirmation` | success or safe expired-link error | `throttle:emi-login` | PARITY_COMPLETE | backend + mobile unit | Backend resets password and revokes tokens; Web remains absent. |
| Session restore | `AuthProvider` calls `/auth/me` | `/auth/me` | GET | bearer token | `UserResource` | auth:sanctum | PARTIAL | auth repo | Real restore exists; no refresh token; 401 clears token. |
| Token expiration | API client handles 401 | any | n/a | expired token | 401 envelope | auth:sanctum | PARTIAL | session invalidation | Mobile clears token on 401; no refresh. |
| Unauthorized 401 | ProtectedRoute/API client | any auth endpoint | n/a | no/invalid token | `UNAUTHENTICATED` | auth:sanctum | PARTIAL | dio mapper/session | Covered by mapper; no full integration test. |
| Forbidden 403 | `/unauthorized` | role/policy endpoints | n/a | wrong role | `FORBIDDEN` | role/policy | PARTIAL | role guard | Router blocks role paths; backend 403 handling not fully widget-tested. |
| Logout | layout logout | `/auth/logout` | POST | bearer token | success empty data | auth:sanctum | PARITY_COMPLETE | auth repo | Server + local clear covered. |
| Profile | role profile pages | `/auth/me` | GET | bearer token | `UserResource` | auth:sanctum | PARTIAL | profile/auth tests | Student profile present; teacher/admin profile partial via settings/auth. |
| Update profile | Admin/Guru/Siswa profile | `/auth/me` | PATCH | profile fields | `UserResource` | auth:sanctum | PARTIAL | auth tests | Mobile has repository methods, UI coverage partial. |
| Change password | settings/profile | `/auth/password` | PUT | current/new/confirmation | user/success | auth:sanctum | PARTIAL | auth tests | Mobile method exists; screen parity partial. |
| Avatar upload | settings/profile | `/auth/me/avatar` | POST | multipart avatar | `UserResource`/media | auth:sanctum | PARTIAL | avatar validator | Mobile method exists; UX coverage partial. |
| Avatar delete | profile | `/auth/me/avatar` | DELETE | none | success | auth:sanctum | PARTIAL | auth tests | API wired; UI parity partial. |
| Delete account | Web absent | `/auth/account` | DELETE | `current_password` | success empty data | auth:sanctum + own user + last-admin guard | PARTIAL | backend + mobile unit | This is self-deactivation, not hard deletion. Mobile clears token only after successful backend deactivation; request/anonymization policy still future. |
| Account deletion request | Not found | not implemented | n/a | n/a | n/a | n/a | BLOCKED_BY_BACKEND | none | Request-based retention workflow not designed; direct self-deactivation implemented instead. |

## Role mapping and guards

| Area | Web | Backend | Flutter | Gap |
|---|---|---|---|---|
| Role values | `admin`, `teacher`, `student` in `roles.ts` | `UserResource.role`; `RoleMiddleware` checks `user()->role` | `SessionUserRole.admin/teacher/student/unknown` | Good baseline. |
| Approved status | Web rejects unknown or `status !== approved` | login/me expose status; approval workflow | repo saves token only after approved | Disabled/pending/rejected copy not complete. |
| Redirect awal | role dashboard helper | n/a | GoRouter redirects to role home | Good baseline; unsupported copy stale. |
| Token storage | localStorage `emi.auth.token` | Sanctum bearer token | `flutter_secure_storage` key `emi_access_token` | Mobile stronger than web. |
| 401 handling | API client error | `UNAUTHENTICATED` envelope | Dio clears token + invalidates session | No refresh-token design. |
| 403 handling | `/unauthorized` | `FORBIDDEN` envelope | router role guard, mapper | Full backend 403 UX not E2E tested. |

## Auth/shared security table

| Endpoint Auth/Shared | auth:sanctum | Role Middleware | Policy | Ownership Check | Risiko |
|---|---:|---:|---:|---:|---|
| `/auth/login` | No | No | No | status checked by service | Low; throttled. |
| `/auth/register` | No | No | No | role limited teacher/student; active school/class validation | Low; approval required. |
| `/auth/forgot-password` | No | No | No | generic response, no account enumeration | Low; throttled. |
| `/auth/reset-password` | No | No | No | password broker token + expiry, revokes tokens after reset | Low; throttled. |
| `/auth/logout` | Yes | No | No | current token only | Low. |
| `/auth/me` | Yes | No | No | current user | Low. |
| `/auth/me` PATCH | Yes | No | No | current user | Low. |
| `/auth/password` | Yes | No | No | current user + current password | Low. |
| `/auth/me/avatar` | Yes | No | Media/avatar service | current user | Low. |
| `/schools`, `/classes`, `/users` shared | Yes | mixed | Yes | policy/admin/teacher scope | Medium if policy regression; mobile must not trust client filters. |
| `/dictionary` | Yes | No | `DictionaryEntryPolicy` | active entries only | Low. |
| `/media/{id}/download` | No | No | signed URL | signed URL bearer secret | Medium; leaked temporary URL grants access until expiry. |

Phase 3 re-check found no clear P0 backend data leak in shared users/schools/classes/media/quiz paths. Added explicit student quiz cross-user denial tests and `/auth/account` self-deactivation with current password, token revocation, membership/assignment closure, and last-admin guard. Signed media URLs remain bearer-style temporary secrets by design.

## Auth P0 update 2026-07-14

| Area | Status | Evidence | Note |
|---|---|---|---|
| Forgot password | PARITY_COMPLETE | Laravel `/auth/forgot-password`; Flutter `/forgot-password`; tests pass | Safe response: no email enumeration. |
| Reset password | PARITY_COMPLETE | Laravel `/auth/reset-password`; Flutter `/reset-password`; tests pass | Password broker token expiry follows Laravel config; all tokens revoked after reset. |
| Account states | PARITY_COMPLETE | Flutter `pendingApproval`, `registrationRejected`, `accountDisabled`, router status gate | Manual pending/rejected/inactive accounts remain NOT_TESTED if no test accounts. |
| Profile all roles | PARTIAL | Shared `/auth/me`, `/auth/password`, `/auth/me/avatar`; teacher route reuses profile screen; admin profile in settings | Manual three-role profile smoke required. |
| Account deletion | PARTIAL | DELETE `/auth/account`; mobile calls it as `Nonaktifkan Akun` behavior | It is deactivation, not hard deletion. |
| Privacy decision | PARTIAL | Backend keeps user row and learning records; status set inactive; class links ended; tokens revoked | Privacy Policy, Data Safety, and public account deletion URL still MISSING. |
| Backend security | PARITY_COMPLETE | Sanctum on protected endpoints; password current check; reset safe response; reset token via broker | Rate limiting uses `emi-login` for forgot/reset. |
| Emulator three-role smoke | NOT_TESTED | Pending current session run | Must be updated after emulator attempt. |
| Test coverage | PARTIAL | Backend auth test 25 pass; Flutter targeted auth test 11 pass | Full test suite pending. |

Privacy technical decision: current mobile feature must be named as deactivation/nonactivation behavior. Backend does not hard-delete profile, quiz results, learning progress, speaking audio, transcripts, AI-related records, PDFs/knowledge uploaded by Admin, or audit-relevant school/class records. Tokens are revoked and active teacher/student assignments are ended. Separate legal Privacy Policy, Data Safety declarations, and account deletion request URL are required before Google Play release.

---

# B. Audit Admin

## Admin module matrix

| Modul | Subfitur Web | Route Web | Endpoint Laravel | Method | Permission | Flutter Screen/Route | Status | Test | Gap |
|---|---|---|---|---|---|---|---|---|---|
| Dashboard | metrics schools/classes/users/content/learning/quiz/speaking | `/admin/dashboard` | `/admin/dashboard/summary` | GET | admin | `/admin/dashboard` | PARTIAL | admin test | Mobile has dashboard foundation; field-by-field parity not proven for all web widgets. |
| Persetujuan pendaftaran | list/detail/approve/reject/filter | `/admin/approvals`, `/admin/approvals/{id}` | `/admin/registration-requests*` | GET/POST | admin + policy | `/admin/approvals`, detail | PARTIAL | admin test | Mobile present; needs full validation/error parity. |
| Pengguna | list/detail/edit/status/search/filter | `/admin/users`, `/admin/users/{id}` | `/users*`, `/users/{id}/status` | GET/PUT/PATCH | UserPolicy | MISSING | none | No mobile users module. |
| Sekolah | CRUD/search/filter/pagination | `/admin/schools-classes` | `/schools*` | GET/POST/PUT/DELETE | SchoolPolicy | MISSING | none | No mobile schools CRUD. |
| Kelas | CRUD/detail/students | `/admin/schools-classes`, `/admin/classes/{id}` | `/classes*`, `/classes/{id}/students` | GET/POST/PUT/DELETE | SchoolClassPolicy | MISSING | none | No mobile classes CRUD. |
| Guru kelas | assign teacher | class detail | `/classes/{id}/assign-teacher` | POST | policy | MISSING | none | No mobile assignment. |
| Siswa kelas | assign student/list | class detail | `/classes/{id}/assign-student`, `/classes/{id}/students` | GET/POST | policy | MISSING | none | No mobile enrollment. |
| Kamus | category/entry CRUD/detail/search/filter | `/admin/dictionary`, detail | `/admin/dictionary/categories*`, `/admin/dictionary/entries*` | GET/POST/PUT/DELETE | dictionary policies | PARTIAL | admin/dictionary tests | Mobile admin dictionary exists; import/detail parity incomplete. |
| Import kamus | template/preview/errors/confirm | `/admin/dictionary/import` | `/admin/dictionary/imports*` | GET/POST | admin + import policy | MISSING | none | No mobile import. |
| Modul template | list/detail/create/edit/delete | `/admin/modules`, edit | `/admin/module-templates*` | GET/POST/PUT/DELETE | ModuleTemplatePolicy | MISSING | none | No mobile admin module templates. |
| Lesson | CRUD/reorder/publish/archive | module editor | `/admin/module-templates/{id}/lessons*`, `/admin/lesson-templates*` | GET/POST/PATCH/PUT/DELETE | LessonTemplatePolicy | MISSING | none | No mobile lesson builder. |
| Media pembelajaran | upload/content URL | module/culture/speaking forms | `/media*` | POST/GET/DELETE | MediaPolicy | PARTIAL | speaking/profile validators | Upload helpers exist in some features; admin media library absent. |
| Apply module | apply template to class | module actions | `/admin/module-templates/{id}/apply` | POST | admin | MISSING | none | No mobile apply module. |
| Publish/status module | publish/archive | module actions | `/admin/module-templates/{id}/publish|archive` | POST | policy | MISSING | none | No mobile status actions. |
| Kuis template | list/create/edit/delete | `/admin/quizzes` | `/admin/quiz-templates*` | GET/POST/PUT/DELETE | QuizTemplatePolicy | PARTIAL | admin quiz tests | Mobile quiz templates exist, builder partial. |
| Pertanyaan | CRUD | quiz builder | `/admin/quiz-templates/{id}/questions`, `/admin/quiz-template-questions/{id}` | GET/POST/PUT/DELETE | question policy | PARTIAL | admin quiz tests | Basic mobile question routes; reorder/options parity unclear. |
| Pilihan jawaban | within question form | quiz builder | same question endpoints | mixed | policy | PARTIAL | admin quiz tests | Need field validation parity. |
| Reorder pertanyaan | drag/reorder | quiz builder | `/admin/quiz-templates/{id}/questions/reorder` | PATCH | policy | MISSING | none | No mobile reorder proven. |
| Apply quiz | apply template | quiz action | `/admin/quiz-templates/{id}/apply` | POST | admin | MISSING | none | No mobile apply. |
| Publish/status quiz | publish/archive | quiz action | `/admin/quiz-templates/{id}/publish|archive` | POST | policy | PARTIAL | admin quiz tests | Some actions exist; parity not proven. |
| Budaya | global culture item CRUD/status | `/admin/culture/templates` and culture services | `/admin/culture/items*` | GET/POST/PUT/DELETE | culture policy | MISSING | none | No mobile admin culture. |
| Culture item | template item CRUD | edit template | `/admin/culture-templates*`, `/admin/culture-template-items*` | mixed | culture policy | MISSING | none | No mobile culture template editor. |
| Speaking exercise | template/list/create/edit/archive/media | `/admin/speaking/exercises` | `/admin/speaking/exercises*`, `/media` | GET/POST/PATCH | admin | MISSING | none | No mobile admin speaking templates. |
| Laporan progress | school/class/student reports | `/admin/progress*` | `/admin/reports/progress/*` | GET | admin scope | `/admin/reports` | READ_ONLY | admin tests | Mobile reports are basic/read-only; export absent. |
| Laporan kuis | quiz reports | progress/reports | `/admin/reports/quiz-results` | GET | admin | `/admin/reports` | READ_ONLY | admin tests | Basic list only. |
| Export laporan | CSV export | report actions | `/admin/reports/*/export` | GET | admin | MISSING | none | No mobile export/download. |
| Media | upload/show/temp/delete/public | various | `/media*` | mixed | MediaPolicy | PARTIAL | limited | No admin media management screen. |
| Knowledge base/RAG | list/create/update/delete/publish/archive/extract/import | `/admin/knowledge-base` | `/admin/ai/knowledge*` | GET/POST/PUT/DELETE | admin + AiKnowledge policy | MISSING | none | No mobile knowledge base. |
| PDF knowledge | extract/upload/import | knowledge form | `/admin/ai/knowledge/extract-pdf-upload`, `/import-pdf` | POST | admin | MISSING | none | No mobile PDF flow. |
| Link knowledge | extract source | knowledge form | `/admin/ai/knowledge/extract-source` | POST | admin | MISSING | none | No mobile link extraction. |
| Manual knowledge | create/update | knowledge form | `/admin/ai/knowledge` | POST/PUT | admin | MISSING | none | No mobile manual KB. |
| Status processing | knowledge/import job status | knowledge/import screens | import/knowledge resources | GET | admin | MISSING | none | No mobile status UI. |
| Settings application | read/update | `/admin/settings` | `/admin/settings`, `/admin/settings/application` | GET/PUT | admin | `/admin/settings` | PARTIAL | admin settings test | Mobile application settings partial. |
| Settings banner | read/update/upload | settings | `/admin/settings/banner`, `/public/login-branding` | POST/GET | admin/public | `/admin/settings` | PARTIAL | admin settings test | Mobile says upload banner unavailable. |
| Settings security | read/update | settings | `/admin/settings/security` | PUT | admin | `/admin/settings` | PARTIAL | admin settings test | Partial. |
| Activity logs | recent logs | settings | `/admin/settings` response `activity_logs` | GET | admin | `/admin/settings` | PLACEHOLDER | none | Mobile says activity unavailable. |
| Profile Admin | profile/password/avatar | settings | `/auth/me`, `/auth/password`, avatar | GET/PATCH/PUT/POST/DELETE | auth | PARTIAL | auth tests | Profile mixed into settings; no full admin profile parity. |

## Admin dashboard response vs widgets

Endpoint `GET /admin/dashboard/summary` returns:

```text
overview.active_schools
overview.active_classes
overview.active_teachers
overview.active_students
overview.pending_registration_requests
content.active_dictionary_entries
content.published_module_templates
content.published_class_modules
content.published_quiz_templates
content.published_class_quizzes
learning.students_with_learning_activity
learning.completed_modules
learning.average_learning_progress_percent
quizzes.final_attempts
quizzes.submitted_attempts
quizzes.expired_attempts
quizzes.in_progress_attempts
quizzes.average_score_percent
quizzes.participation_rate_percent
trends
capabilities.speaking_reports
speaking_summary
generated_at
```

Web dashboard is source of widgets in `features/admin/dashboard/admin-dashboard.tsx`. Flutter admin dashboard foundation exists, but audit does not prove every response field above is rendered and tested. Status: `PARTIAL`.

## Admin settings response categories

`GET /admin/settings` returns:

```text
application.name
application.subtitle
application.active_academic_year
application.timezone
banner.enabled
banner.title
banner.subtitle
banner.image_media_id
banner.image_url
security.new_login_alert
security.weekly_report_email
activity_logs[].id
activity_logs[].created_at
activity_logs[].admin
activity_logs[].action
activity_logs[].title
activity_logs[].status
```

Mobile settings status: `PARTIAL`; banner upload and activity logs are explicit placeholders.

---

# C. Audit Guru

## Guru module matrix

| Modul Guru | Subfitur Web | Route Web | Endpoint Laravel | Method | Permission/Ownership | Flutter Status | Test | Gap |
|---|---|---|---|---|---|---|---|---|
| Dashboard | class/student/learning/quiz/activity/speaking metrics | `/teacher/dashboard` | `/teacher/dashboard/summary` | GET | teacher assigned active class | PARTIAL | teacher test | Mobile only dashboard foundation; activity placeholder. |
| Kelas | list classes | `/teacher/classes` | `/classes` | GET | teacher scoped classes | MISSING | none | No mobile class list. |
| Detail kelas | detail | `/teacher/classes/{id}` | `/classes/{id}` | GET | assigned class | MISSING | none | No mobile detail. |
| Daftar siswa | list class students | `/teacher/classes/{id}/students`, `/teacher/students` | `/classes/{id}/students` | GET | assigned class | MISSING | none | No mobile students list. |
| Progress siswa | detail/progress | `/teacher/students/{id}`, reports | `/teacher/reports/progress/students` | GET | assigned class/student | MISSING | none | No mobile progress. |
| Modul kelas | list | `/teacher/modules`, `/teacher/classes/{id}/modules` | `/classes/{id}/modules`, `/class-modules/{id}` | GET | assigned class | MISSING | none | No mobile teacher modules. |
| Lesson | edit/publish | lesson edit route | `/class-lessons*` | GET/PUT/POST | assigned class | MISSING | none | No mobile lesson edit. |
| Media | upload/temp URL | `/teacher/media` | `/media*` | mixed | MediaPolicy | MISSING | none | No mobile teacher media. |
| Create/update module | update class module | module edit | `/class-modules/{id}` | PUT | assigned class | MISSING | none | No mobile update. |
| Publish module | publish/archive | module edit | `/class-modules/{id}/publish|archive` | POST | assigned class | MISSING | none | No mobile status. |
| Kuis kelas | list/create | `/teacher/quizzes`, class quizzes | `/class-quizzes*` | GET/POST | assigned class | MISSING | none | No mobile teacher quizzes. |
| Quiz builder | create/edit questions | `/teacher/quizzes/{id}/builder` | `/class-quizzes/{id}/questions*`, `/quiz-questions*` | mixed | assigned class | MISSING | none | No mobile builder. |
| Pertanyaan | CRUD | builder | same | mixed | assigned class | MISSING | none | No mobile. |
| Pilihan jawaban | within questions | builder | same | mixed | assigned class | MISSING | none | No mobile. |
| Publish quiz | status | quiz list/builder | `/class-quizzes/{id}/publish` | POST | assigned class | MISSING | none | No mobile. |
| Hasil kuis | attempts/report | `/teacher/quizzes/{id}/results` | `/class-quizzes/{id}/attempts`, `/report` | GET | assigned class | MISSING | none | No mobile. |
| Detail jawaban siswa | attempt detail | results | `/quiz-attempts/{id}` | GET | assigned class | MISSING | none | No mobile. |
| Statistik | dashboard/report | dashboard/reports | `/teacher/dashboard/summary`, quiz report | GET | assigned class | PARTIAL | teacher test | Dashboard only. |
| Laporan | progress/quiz reports | `/teacher/reports/progress` | `/teacher/reports/progress/students`, `/teacher/reports/quiz-results` | GET | assigned class | MISSING | none | No mobile reports. |
| Filter periode | reports | reports | report requests | GET | assigned class | MISSING | none | No mobile filters. |
| Export | reports export | reports | `/teacher/reports/*/export` | GET | assigned class | MISSING | none | No mobile export. |
| Speaking submissions | list/detail | `/teacher/speaking/results` | `/teacher/speaking/attempts*` | GET | assigned class | MISSING | none | No mobile. |
| Audio playback | result detail | speaking results | media temp URL | GET/POST | policy | MISSING | none | No mobile. |
| Nilai | feedback score | speaking results | `/teacher/speaking/attempts/{id}/feedback` | PATCH | assigned class | MISSING | none | No mobile. |
| Feedback | review comments | speaking results | same | PATCH | assigned class | MISSING | none | No mobile. |
| Review status | pending/completed | speaking results | same/resource | PATCH/GET | assigned class | MISSING | none | No mobile. |
| Profile Guru | profile | `/teacher/profile` | `/auth/me` | GET/PATCH | own user | MISSING | none | No mobile teacher profile route. |
| Change password | profile | `/auth/password` | PUT | own user | MISSING | none | No mobile UI. |
| Avatar | profile | avatar endpoints | POST/DELETE | own user | MISSING | none | No mobile UI. |

## Guru security matrix

| Endpoint Guru | Role Check | Class Ownership | Student Ownership | Policy | Risiko |
|---|---|---|---|---|---|
| `/teacher/dashboard/summary` | `role:teacher` | active assigned class via report scope | n/a | scope service | Low. |
| `/classes*` shared | auth only + policy | teacher scoped to assigned classes | class students scoped | SchoolClassPolicy | Medium if policy regression. |
| `/classes/{id}/students` | auth + policy | assigned class | students in class | SchoolClassPolicy | Low. |
| `/class-modules*`, `/class-lessons*` | auth + policy | assigned class | n/a | ClassModule/ClassLessonPolicy | Low. |
| `/class-quizzes*`, `/quiz-questions*` | auth + policy | assigned class | attempts scoped by quiz class | Quiz policies | Low. |
| `/teacher/reports/*` | `role:teacher` | assigned active class | students in assigned class | report scope | Low. |
| `/teacher/speaking/*` | `role:teacher` | assigned active class | attempts in assigned class | controller/service scope | Low. |
| `/media*` | auth | via media owner/visibility | n/a | MediaFilePolicy | Medium for leaked signed URLs. |

---

# D. Audit Siswa

## Siswa module matrix

| Modul Siswa | Subfitur Web | Route Web | Endpoint Laravel | Method | Ownership | Flutter Status | Test | Gap |
|---|---|---|---|---|---|---|---|---|
| Dashboard | class/learning/quiz/deadlines/activity/speaking | `/student/dashboard` | `/student/dashboard/summary` | GET | own active class | PARTIAL | dashboard test | Mobile exists; active class placeholder when absent; full widget parity not proven. |
| Kelas | active class info | dashboard/profile | dashboard/me | GET | own membership | PARTIAL | auth/dashboard | No standalone class screen. |
| Modul | list/filter/search | `/student/modules` | `/student/modules` | GET | own active class, published | PARTIAL | module tests | Mobile list exists; web parity for all filters not proven. |
| Lesson | detail/content URL | `/student/lessons/{id}` | `/class-lessons/{id}`, `/content-url` | GET | published/own class | PARTIAL | module tests | Text content fallback says unavailable; content types need parity. |
| Media | lesson media/content URL | lesson detail | `/class-lessons/{id}/content-url`, `/media*` | GET | policy/signed URL | PARTIAL | module tests | Download/playback coverage partial. |
| Progress lesson | mark progress | lesson detail | `/student/lessons/{id}/progress` | PATCH | own progress | PARTIAL | module/progress tests | Real API; UI parity partial. |
| Resume learning | module/start/dashboard | module detail | `/student/modules/{id}/start` | POST | own progress | PARTIAL | module tests | Resume behavior not fully E2E tested. |
| Kamus | list/detail/search/filter | `/student/dictionary`, detail | `/dictionary`, `/dictionary/{id}` | GET | active authenticated entries | PARTIAL | dictionary tests | Mobile exists; full filter parity needs check. |
| Kuis | list/detail | `/student/quizzes` | `/student/quizzes*` | GET | own class/published | PARTIAL | quiz tests | Mobile exists. |
| Mulai kuis | start attempt | `/student/quizzes/{id}` | `/class-quizzes/{id}/attempts` | POST | own attempt | PARTIAL | quiz tests | Real API; timer/E2E not complete. |
| Attempt | attempt screen | `/student/quizzes/{id}/attempt` | `/quiz-attempts/{id}` | GET | own attempt | PARTIAL | quiz tests | Exists. |
| Submit | submit attempt | attempt | `/quiz-attempts/{id}/submit` | POST | own attempt; idempotency web uses key | PARTIAL | quiz tests | Need confirm mobile idempotency key parity. |
| Timer | quiz attempt | attempt | quiz resource/attempt rules | n/a | own attempt | PARTIAL | quiz tests | Timer behavior not fully device-tested. |
| Hasil | result | `/student/quizzes/{id}/result` | `/student/reports/quiz-results`, attempt | GET | own visible results | PARTIAL | quiz tests | Result route in web; mobile result folded/detail unclear. |
| Review jawaban | result review | result/detail | `/quiz-attempts/{id}` | GET | own visible attempt | PARTIAL | quiz tests | Visibility/hidden result parity not proven. |
| Attempt history | history | quizzes/results | `/student/reports/quiz-results` | GET | own attempts | PARTIAL | quiz tests | Needs UI parity. |
| Progress | report | `/student/progress` | `/student/reports/progress`, `/student/progress/modules` | GET | own progress | PARTIAL | progress tests | Mobile exists. |
| Budaya | list/detail | `/student/culture` | `/student/culture` | GET | published for class/global | PARTIAL | culture tests | Detail route exists; response/detail parity partial. |
| Speaking exercise | list/detail | `/student/speaking` | `/student/speaking/exercises*` | GET | published own class/global | PARTIAL | speaking tests | Mobile exists. |
| Record audio | recorder | speaking detail | local audio then upload | n/a | own device | PARTIAL | speaking tests | Device permission/smoke not proven. |
| Upload audio | submit attempt | speaking detail | `/student/speaking/exercises/{id}/attempts` | POST | own attempt | PARTIAL | speaking tests | Real endpoint; device upload not smoke-tested. |
| Submission status | attempts/results | `/student/speaking/results` | `/student/speaking/attempts*` | GET | own attempts | PARTIAL | speaking tests | Mobile route list/detail exists; web results route absent in mobile router. |
| Feedback Guru | attempt feedback | speaking results | attempt resource | GET | own attempt | PARTIAL | speaking tests | UI parity partial. |
| Profile | profile | `/student/profile` | `/auth/me` | GET/PATCH | own user | PARTIAL | profile/auth tests | Mobile exists. |
| Change password | profile | `/auth/password` | PUT | own user | PARTIAL | auth tests | Method exists; UI parity partial. |
| Avatar | profile | avatar endpoints | POST/DELETE | own user | PARTIAL | avatar validator | Upload validation only; device test absent. |

Siswa ownership: backend scopes to current student active class, own progress, own quiz attempts, own speaking attempts. Main remaining risk is mobile UI/contract coverage, not obvious backend P0.

---

# E. Katalog Endpoint Laravel Relevan Mobile

| Role | Method | Endpoint | Controller | Service | Request | Resource | Middleware | Policy | Digunakan Web | Digunakan Flutter |
|---|---|---|---|---|---|---|---|---|---|---|
| Public/Auth | GET | `/public/schools` | PublicLookupController | lookup | PublicSchoolIndexRequest | SchoolPublicResource | none | n/a | yes | no register missing |
| Public/Auth | GET | `/public/schools/{id}/classes` | PublicLookupController | lookup | PublicSchoolClassesRequest | SchoolClassPublicResource | none | n/a | yes | no |
| Public/Auth | GET | `/public/login-branding` | AdminSettingsController | settings | none | public branding object | none | n/a | yes | partial settings |
| Auth | POST | `/auth/register` | AuthController | RegistrationService | RegisterRequest | request/user | throttle | n/a | yes | no |
| Auth | POST | `/auth/login` | AuthController | AuthService | LoginRequest | UserResource + token | throttle | n/a | yes | yes |
| Auth | POST | `/auth/logout` | AuthController | AuthService | none | success | auth:sanctum | n/a | yes | yes |
| Auth | GET | `/auth/me` | AuthController | AuthService | none | UserResource | auth:sanctum | n/a | yes | yes |
| Auth | PATCH | `/auth/me` | AuthController | AuthService | UpdateProfileRequest | UserResource | auth:sanctum | own | yes | yes |
| Auth | PUT | `/auth/password` | AuthController | AuthService | UpdatePasswordRequest | UserResource/success | auth:sanctum | own | yes | yes |
| Auth | POST/DELETE | `/auth/me/avatar` | AvatarController | AvatarService | UploadAvatarRequest | UserResource/media | auth:sanctum | own/media | yes | yes |
| Admin | GET | `/admin/dashboard/summary` | AdminDashboardController | ReportScopeService | DashboardSummaryRequest | object | admin | admin scope | yes | yes |
| Admin | GET/POST | `/admin/registration-requests*` | AdminRegistrationRequestController | RegistrationService | list/approve/reject requests | RegistrationRequestResource | admin | RegistrationRequestPolicy | yes | yes |
| Admin | GET/POST/PUT/DELETE | `/admin/dictionary/categories*` | AdminDictionaryCategoryController | dictionary | category requests | DictionaryCategoryResource | admin | DictionaryCategoryPolicy | yes | yes |
| Admin | GET/POST/PUT/DELETE | `/admin/dictionary/entries*` | AdminDictionaryEntryController | dictionary | entry requests | DictionaryEntryResource | admin | DictionaryEntryPolicy | yes | yes |
| Admin | GET/POST | `/admin/dictionary/imports*` | DictionaryImportController | import | preview/confirm/list requests | Import resources | admin | DictionaryImportJobPolicy | yes | no |
| Admin | GET/POST/PUT/DELETE | `/admin/module-templates*` | AdminModuleTemplateController | modules | module requests | ModuleTemplateResource | admin | ModuleTemplatePolicy | yes | no |
| Admin | mixed | `/admin/lesson-templates*` | AdminLessonTemplateController | lessons | lesson/reorder requests | LessonTemplateResource | admin | LessonTemplatePolicy | yes | no |
| Admin | GET/POST/PUT/DELETE | `/admin/quiz-templates*` | AdminQuizTemplateController | quizzes | quiz requests | QuizTemplateResource | admin | QuizTemplatePolicy | yes | partial |
| Admin | mixed | `/admin/quiz-template-questions*` | AdminQuizTemplateQuestionController | quizzes | question/reorder requests | QuizTemplateQuestionResource | admin | QuestionPolicy | yes | partial |
| Admin | mixed | `/admin/culture*` | AdminCulture controllers | culture | culture requests | culture resources | admin | culture policies | yes | no |
| Admin | mixed | `/admin/speaking/exercises*` | AdminSpeakingExerciseController | speaking | speaking requests | SpeakingExerciseResource | admin | policy/scope | yes | no |
| Admin | GET | `/admin/reports/*` | AdminReport controllers | reports | report requests | arrays/resources | admin | scope | yes | read-only partial |
| Admin | GET | `/admin/reports/*/export` | ReportExportController | reports | report filters | CSV | admin | scope | yes | no |
| Admin/AI | mixed | `/admin/ai/knowledge*` | AdminAiKnowledgeController | AI/RAG | AI knowledge requests | AiKnowledgeItemResource | admin | AiKnowledgeItemPolicy | yes | no |
| Settings | GET/PUT/POST | `/admin/settings*` | AdminSettingsController | settings | settings requests | settings object | admin | role | yes | partial |
| Shared | mixed | `/schools*` | SchoolController | school | school requests | SchoolResource | auth:sanctum | SchoolPolicy | yes | no |
| Shared | mixed | `/classes*` | SchoolClassController/ClassAssignment | class | class/assign requests | class resources | auth:sanctum | SchoolClassPolicy | yes | no |
| Shared | mixed | `/users*` | UserController | users | user requests | UserManagementResource | auth:sanctum | UserPolicy | yes | no |
| Shared | GET | `/dictionary*` | DictionaryController | dictionary | ListDictionaryRequest | DictionaryEntryResource | auth:sanctum | DictionaryEntryPolicy | yes | yes |
| Shared learning | mixed | `/class-modules*`, `/class-lessons*` | ClassModule/Lesson controllers | learning | learning requests | resources | auth:sanctum | learning policies | yes | student partial |
| Shared quiz | mixed | `/class-quizzes*`, `/quiz-*` | quiz controllers | quiz | quiz requests | quiz resources | auth/role for attempts | quiz policies | yes | student/admin partial |
| Student | GET/POST/PATCH | `/student/*` | Student controllers | student services | student requests | resources | student | own scope | yes | yes |
| Teacher | GET/POST/PATCH | `/teacher/*` | Teacher controllers | teacher services | teacher requests | resources | teacher | assigned class | yes | dashboard only |
| Upload/Media | mixed | `/media*` | MediaController | MediaUploadService | media requests | MediaFileResource/binary | auth or signed/public | MediaFilePolicy | yes | partial |

Endpoint concerns:
- Duplicate class/quiz/module routes are shared by admin/teacher/student contexts; mobile must use role-appropriate repositories, not generic unrestricted calls.
- Pagination envelope is consistent via `ApiResponse::paginated`, but Flutter models often parse raw strings and custom structures.
- Validation errors use `VALIDATION_ERROR` envelope; UI parity for form errors incomplete.
- `AiKnowledgeItemPolicy`, culture policies exist but explicit registration not seen in provider; Laravel auto-discovery may apply. Verify before production.

---

# F. Audit Struktur Response

Global envelope:

```text
success: boolean
message: string
data: object|array|null
meta.current_page
meta.per_page
meta.total
meta.last_page
code: string on error
errors: object on validation/error
```

Key response structures:

```text
Endpoint: GET /admin/registration-requests
Response: data[] RegistrationRequestResource, meta pagination
Nullable/status: pending|approved|rejected; rejection reason may be nullable
```

```text
Endpoint: GET /admin/dashboard/summary
Response: overview, content, learning, quizzes, trends, capabilities, speaking_summary, generated_at
Flutter model needed: typed AdminDashboardSummary
```

```text
Endpoint: GET /teacher/dashboard/summary
Response: class?, empty_state, students, learning, quizzes, recent_activity[], capabilities, speaking_summary, generated_at
Nullable: class may be absent/empty_state true
```

```text
Endpoint: GET /student/dashboard/summary
Response: class?, empty_state, learning, quizzes, upcoming_deadlines[], recent_activity, capabilities, speaking_summary, generated_at
Nullable: class may be absent
```

```text
Endpoint: GET /admin/settings
Response: application, banner, security, activity_logs[]
Nullable: banner image_media_id/image_url
Secret fields: none returned in audited response
```

```text
Endpoint: GET /student/modules
Response: data[] StudentModuleResource, possible meta pagination
Nested: lessons/progress/class/school depending resource
Status: published/progress statuses raw string
```

```text
Endpoint: GET /student/quizzes
Response: data[] StudentQuizResource, availability/status/attempt info
Enum/status: open|locked|closed|finished; attempts in_progress|submitted|expired
```

```text
Endpoint: GET /quiz-attempts/{id}
Response: QuizAttemptResource with questions/answers/result visibility
Ownership: own attempt for student; class scope for teacher/admin
```

```text
Endpoint: GET /student/speaking/attempts
Response: SpeakingAttemptResource[]
Status: pending|processing|completed|failed
Media URL: private/signed/temporary where applicable
```

```text
Endpoint: POST /media
Response: MediaFileResource
Fields: id, URL/metadata/visibility/purpose expected from resource
Access: public content or temporary signed URL
```

Models requiring dedicated Flutter types: dashboard summaries per role, registration request, user management, school/class/assignment, dictionary category/entry/import job, module template/lesson template, class module/lesson, quiz template/question/class quiz/attempt/report, culture template/item/class culture, speaking exercise/attempt, AI knowledge item, settings, media file.

Reusable mobile components possible: paginated list state, API error mapper, status chip, empty/loading/error, media picker/upload, date filters. Do not make one generic CRUD repository for business-rule-heavy modules.

---

# G. Audit Flutter Architecture

| Area Flutter | Kondisi | Masalah | Risiko | Keputusan |
|---|---|---|---|---|
| Router | GoRouter, role redirects, admin/teacher/student guards | lesson route casts `state.extra as String?`; unsupported copy stale | crash on wrong extra; confusing UX | KEEP_AND_EXTEND |
| Auth controller | restore/login/logout/profile/password/avatar methods | pending/rejected/disabled UX generic | auth status copy incomplete | KEEP_AND_EXTEND |
| Dio provider | bearer interceptor, 401 clears token | no refresh token | forced logout on expiry | KEEP |
| Token storage | `flutter_secure_storage` token only | no refresh/session metadata | acceptable for Sanctum token | KEEP |
| Environment | dev/prod URLs, prod HTTPS validation | hardcoded default prod domain | release config must verify | KEEP_AND_EXTEND |
| Admin repositories | real endpoints, some generic `list(String endpoint)` | weak type boundary | wrong parser/endpoint drift | REFACTOR_LATER |
| Admin screens | dashboard/approvals/dictionary/quiz/reports/settings | many modules missing; settings placeholders | parity low | KEEP_AND_EXTEND |
| Teacher feature | shell/dashboard only | most teacher web features missing | teacher unusable beyond dashboard | KEEP_AND_EXTEND |
| Student features | broad real backend coverage | partial parity, raw statuses | regressions with enum drift | KEEP_AND_EXTEND |
| Status handling | raw strings in many models | no central taxonomy | UI mismatch/crash labels | REFACTOR_LATER |
| Upload handling | avatar/speaking/media helpers | no shared upload UX for admin/teacher | duplicated future work | KEEP_AND_EXTEND |
| Pagination | present in repositories/models selectively | inconsistent across modules | list bugs | REFACTOR_LATER |
| Tests | 23 files, 63 last known tests | few widget/integration/device tests | parity unproven | KEEP_AND_EXTEND |

Notable placeholders/hardcoded:
- `unsupported_role_screen.dart`: stale “non-student use web” copy.
- `admin_settings_screen.dart`: banner upload/activity unavailable.
- `teacher_dashboard_screen.dart`: activity unavailable.
- `student_lesson_detail_screen.dart`: text content unavailable fallback.
- `student_dashboard_screen.dart`: active class unavailable fallback.
- `auth_remote_data_source.dart`: `device_name = emi-flutter-android`.

---

# H. Audit Test Coverage

| Role | Modul | Unit Test | Repository Test | Provider Test | Widget Test | Integration Test | Device Test | Gap |
|---|---|---|---|---|---|---|---|---|
| Auth | login/session/profile/avatar | yes | yes | partial | login screen | no | no | register/forgot/reset/account states missing. |
| Admin | dashboard/approvals/dictionary/quiz/settings | partial | yes | partial | limited | no | no | users/schools/classes/modules/culture/speaking/knowledge missing. |
| Guru | dashboard | partial | yes | partial | limited | no | no | almost all guru modules untested/missing. |
| Siswa | dashboard/modules/dictionary/quizzes/progress/culture/speaking/chatbot/profile | yes | partial | partial | navigation/login | no | no | no E2E, device audio/upload/timer not proven. |
| Shared | router/role guard/network/config/storage/errors | yes | partial | partial | role guard | no | no | Dio auth header/401 only partial. |

Test classes present: `UNIT_TEST`, `WIDGET_TEST`, repository-like contract tests. Missing: `INTEGRATION_TEST`, `DEVICE_SMOKE_TEST`, `WEB_MOBILE_SYNC_TEST`. Contract tests are mostly mocked/fake HTTP, not backend E2E.

P0/P1 coverage gaps:
- Auth register/pending/rejected/disabled/deletion flows.
- Admin users/schools/classes/assignment.
- Teacher ownership flows.
- Student quiz attempt idempotency/timer/visibility.
- Speaking record/upload permissions/device behavior.
- Media temporary URL access.

---

# I. Production dan Google Play Readiness

| Area Release | Status | Risiko | Prioritas | Tindakan |
|---|---|---|---|---|
| application ID/package | PARTIAL | Need release verification | P1 | Inspect Android manifest/Gradle before release. |
| app name | PARTIAL | Store branding mismatch | P2 | Verify label/icons. |
| version name/code | PARTIAL | Release blocked if unset | P1 | Verify Gradle/pubspec. |
| min/target/compile SDK | PARTIAL | Play policy mismatch | P1 | Verify Android config. |
| flavors/base URL | PARTIAL | prod/dev mix risk | P0 | Add release config check for HTTPS production URL. |
| signing config | MISSING | AAB cannot be released | P0 | Configure secure signing outside repo. |
| AAB readiness | BLOCKED | signing/config unverified | P0 | Run release build in release phase. |
| HTTPS production | PARTIAL | prod URL default HTTPS and validation exists | P0 | Confirm real API domain/cert. |
| cleartext traffic | NOT_AUDITED | dev HTTP may leak if enabled release | P0 | Inspect network security manifest. |
| secrets/API keys | PARTIAL | no obvious mobile secret from audit | P0 | Run secret scan before release. |
| token storage | READY | secure storage used | P0 | Keep no logs. |
| release logging | NOT_AUDITED | PII/token logs risk | P1 | Audit logs. |
| Android exported components | NOT_AUDITED | Play/security risk | P1 | Inspect manifest. |
| permissions | PARTIAL | microphone/storage needed for speaking/avatar | P1 | Verify minimal permissions. |
| file provider | NOT_AUDITED | upload/camera risk | P2 | Verify if used. |
| backup settings | NOT_AUDITED | token/PII backup risk | P0 | Disable sensitive backup if needed. |
| student/teacher data privacy | PARTIAL | minors/education data | P0 | Data Safety + privacy policy. |
| avatar/audio/PDF uploads | PARTIAL | sensitive media | P0 | Document retention/deletion/access. |
| account deletion | MISSING | Google Play privacy blocker | P0 | Add account deletion/request flow. |
| analytics/crash reporting | NOT_AUDITED | Data Safety unknown | P1 | Declare if added. |
| app icon/adaptive/splash | NOT_AUDITED | Store readiness | P2 | Verify assets. |
| review accounts | MISSING | Play review blocked | P1 | Prepare non-production review accounts. |
| privacy policy URL/support email | MISSING | Play listing blocked | P0 | Provide policy URL/support email. |
| screenshots/feature graphic/content rating | MISSING | Store listing blocked | P2 | Prepare assets. |
| internal/closed testing | BLOCKED | not ready without release config/tests | P1 | After P0 parity/security. |

---

# J. Dependency Map

```text
Auth dan role guard
→ Admin approvals/users/schools/classes
→ Teacher assignment/student enrollment
→ Shared media upload
→ Dictionary
→ Modules/lessons
→ Quizzes/questions/attempts
→ Culture
→ Speaking
→ Reports/export
→ Knowledge base/RAG
→ Settings/profile/security
→ Cross-role integration
→ Production hardening
→ Google Play readiness
```

| Fitur | Bergantung pada | Dibutuhkan oleh | Urutan |
|---|---|---|---:|
| Auth finalization | existing auth API | all roles | 1 |
| Admin approvals/users | auth/admin guard | account activation, role access | 2 |
| Schools/classes | users | assignment, all class-scoped features | 3 |
| Teacher/student assignment | schools/classes/users | teacher/student scoped content | 4 |
| Dictionary | auth | student dictionary/chatbot context | 5 |
| Media upload | auth/policy | modules/culture/speaking/avatar/knowledge | 6 |
| Modules/lessons | classes/media | progress/reports | 7 |
| Quizzes/questions | classes | attempts/reports | 8 |
| Culture | classes/media | student culture | 9 |
| Speaking | classes/media | audio feedback/reports | 10 |
| Reports/export | modules/quizzes/progress/speaking | admin/teacher overview | 11 |
| Knowledge base/RAG | media/settings | chatbot quality | 12 |
| Settings/profile | auth/media | branding/security/release | 13 |
| Teacher parity | classes/modules/quizzes/speaking | classroom operations | 14 |
| Student fixes | modules/quizzes/speaking | learning flow | 15 |
| Production hardening | all P0/P1 | release | 16 |
| Google Play readiness | production hardening | publication | 17 |

---

# K. Backlog Implementasi

| ID | Role | Modul | Task | Status Saat Ini | Target | Dependency | Priority | Estimasi Kompleksitas | Definition of Done |
|---|---|---|---|---|---|---|---|---|---|
| AUTH-01 | All | Auth | Add mobile register teacher/student + pending/rejected/disabled UX | MISSING/PARTIAL | Web parity | Auth API/public lookups | P0 | M | Register, pending, rejected, disabled flows tested. |
| AUTH-02 | All | Auth | Complete account deletion retention/anonymization policy and Play disclosure | PARTIAL | Play compliant | `/auth/account` self-deactivation | P0 | M | Direct delete/deactivate exists with tests; retention policy documented and Play disclosure ready. |
| AUTH-03 | All | Auth | Harden role/status copy and unsupported-role screen | PARTIAL | Clear UX | router/auth | P1 | XS | Admin/teacher/student copy accurate. |
| ADM-01 | Admin | Users | Implement admin users list/detail/edit/status | MISSING | Web parity | auth/users API | P1 | M | User management mobile tested. |
| ADM-02 | Admin | Schools | Implement schools CRUD | MISSING | Web parity | admin guard | P1 | M | CRUD/search/pagination validation tested. |
| ADM-03 | Admin | Classes | Implement classes CRUD/detail/students | MISSING | Web parity | schools/users | P1 | L | Class detail and students tested. |
| ADM-04 | Admin | Assignment | Implement assign teacher/student | MISSING | Web parity | users/classes | P1 | M | Ownership/status errors handled. |
| ADM-05 | Admin | Dictionary | Complete import/detail/status parity | PARTIAL | Web parity | dictionary API | P1 | M | Preview/errors/confirm covered. |
| ADM-06 | Admin | Modules | Implement module templates/lessons/reorder/apply/status | MISSING | Web parity | classes/media | P1 | XL | Builder + apply tested. |
| ADM-07 | Admin | Quizzes | Complete questions/options/reorder/apply/status | PARTIAL | Web parity | classes | P1 | L | Builder + reorder + apply tested. |
| ADM-08 | Admin | Culture | Implement culture templates/items/status/apply | MISSING | Web parity | classes/media | P1 | L | CRUD/apply tested. |
| ADM-09 | Admin | Speaking | Implement speaking templates CRUD/archive/media | MISSING | Web parity | media | P1 | M | Template actions tested. |
| ADM-10 | Admin | Reports | Complete progress/quiz reports + export | READ_ONLY | Web parity | modules/quizzes | P1 | M | Filters/export tested. |
| ADM-11 | Admin | Knowledge | Implement AI knowledge manual/link/PDF/status | MISSING | Web parity | media | P1 | XL | Extract/import/publish tested. |
| ADM-12 | Admin | Settings | Complete banner upload/activity/security/profile | PARTIAL | Web parity | media/auth | P1 | M | Settings categories tested. |
| TCH-01 | Guru | Classes | Implement class list/detail/students | MISSING | Web parity | assignment/classes | P1 | M | Assigned-class scoping tested. |
| TCH-02 | Guru | Modules | Implement class modules/lessons edit/publish | MISSING | Web parity | classes/media | P1 | L | Teacher ownership tests. |
| TCH-03 | Guru | Quizzes | Implement class quiz builder/results | MISSING | Web parity | classes | P1 | XL | Attempts/results scoped tests. |
| TCH-04 | Guru | Reports | Implement progress/quiz filters/export | MISSING | Web parity | modules/quizzes | P1 | M | Filters/export tested. |
| TCH-05 | Guru | Speaking | Implement exercises/submissions/audio/feedback | MISSING | Web parity | media/classes | P1 | L | Audio/feedback tested. |
| TCH-06 | Guru | Profile | Implement profile/password/avatar | MISSING | Web parity | auth/media | P1 | S | Profile tests pass. |
| STD-01 | Siswa | Quiz | Complete timer/result visibility device parity | PARTIAL | Robust parity | quiz API | P0 | M | Backend cross-user attempt denial/idempotency tested; mobile timer/result UX still needs parity. |
| STD-02 | Siswa | Speaking | Device smoke for record/upload/feedback | PARTIAL | Robust parity | media/speaking | P1 | M | Device smoke documented. |
| STD-03 | Siswa | Modules | Complete lesson content/media/resume parity | PARTIAL | Web parity | modules/media | P1 | M | Content URL/media/progress tests. |
| REL-01 | Release | Config | Audit Android package/version/SDK/manifest/cleartext/signing | PARTIAL | Release ready | all P0 | P0 | M | Release config documented; no secrets committed. |
| REL-02 | Release | Privacy | Privacy policy/Data Safety/account deletion/support/review accounts | MISSING | Play ready | account deletion | P0 | L | Play checklist complete. |

---

# L. Urutan Implementasi Rekomendasi Final

1. Auth finalization — semua modul butuh role/status/session benar.
2. Account deletion/privacy P0 — Google Play blocker; jangan tunggu akhir.
3. Admin Users — dasar aktivasi/status role.
4. Admin Schools — dasar kelas.
5. Admin Classes dan assignment — unlock teacher/student scope.
6. Shared Media upload hardening — dipakai modules/culture/speaking/avatar/knowledge.
7. Admin Dictionary parity — relatif terisolasi dan dipakai siswa/chatbot.
8. Admin Modules — depend kelas/media; unlock learning/progress.
9. Admin Quizzes — depend kelas; unlock attempts/reports.
10. Admin Culture — depend kelas/media.
11. Admin Speaking — depend kelas/media.
12. Admin Reports/export — butuh modules/quizzes/progress data.
13. Admin Knowledge base — kompleks RAG/PDF; setelah media stabil.
14. Admin Settings parity — branding/security/profile; sebagian bisa paralel, tapi banner butuh media.
15. Teacher Classes dan Students — depend assignment.
16. Teacher Modules — depend modules/classes.
17. Teacher Quizzes — depend quizzes/classes.
18. Teacher Reports — depend teacher modules/quizzes.
19. Teacher Speaking — depend speaking/media/classes.
20. Teacher Profile — auth/media; kecil, bisa paralel.
21. Student parity audit fixes — existing broad fitur perlu hardening quiz/speaking/modules.
22. Cross-role integration — prove admin-created content appears for teacher/student.
23. Production hardening — manifest/build/logging/secrets/release config.
24. Google Play readiness — store assets, privacy policy, review accounts, internal testing.

Perubahan dari urutan awal: account deletion/privacy naik ke awal karena Play P0; shared media naik sebelum modules/culture/speaking/knowledge karena dipakai lintas fitur.

---

# Baseline verification log

Isi aktual diisi setelah command verifikasi akhir sesi.

```text
dart format: PASS — Formatted 113 files (0 changed)
flutter analyze: PASS — No issues found (7.0s)
flutter test: PASS — 63 tests
git diff --check: PASS
flutter devices: PASS — emulator-5554, Windows, Chrome, Edge detected
adb devices: PASS — emulator-5554 device
app launch smoke: PASS — debug APK built/installed/launched on emulator; no login performed; no fatal startup error in captured log
```
