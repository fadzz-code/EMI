# API v1 Route Inventory

Source: `php artisan route:list --path=api/v1` and `Emi-Backend/routes/api.php`.

Base path: `/api/v1`

Auth notation:

- Public: no token required.
- Auth: `auth:sanctum` bearer token required.
- Admin/Teacher/Student: bearer token plus role middleware.
- Scoped: route is authenticated and controller/policy/service limits access by role/ownership.

## Auth

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| POST | `/auth/register` | `AuthController@register` | Public | Student/teacher registration | Medium | Account remains pending until admin approval. |
| POST | `/auth/login` | `AuthController@login` | Public | Login and token issue | High | Requires `email`, `password`, `device_name`; returns Bearer token. |
| POST | `/auth/logout` | `AuthController@logout` | Auth | Revoke current token | High | Use on mobile logout. |
| GET | `/auth/me` | `AuthController@me` | Auth | Current profile | High | Includes role and active class/school relationships. |
| PATCH | `/auth/me` | `AuthController@updateProfile` | Auth | Update profile | High | Profile editing. |
| PUT | `/auth/password` | `AuthController@updatePassword` | Auth | Change password | Medium | Requires current password. |
| POST | `/auth/me/avatar` | `AvatarController@store` | Auth | Upload avatar | Medium | Multipart upload. |
| DELETE | `/auth/me/avatar` | `AvatarController@destroy` | Auth | Remove avatar | Medium |  |

## Public Lookup

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET | `/public/schools` | `PublicLookupController@schools` | Public | Active school lookup | Medium | Used during registration. |
| GET | `/public/schools/{school_id}/classes` | `PublicLookupController@classes` | Public | Active class lookup | Medium | Used during registration. |
| GET | `/public/media/{id}/content` | `MediaController@publicContent` | Public | Public media content | High | Only public media; private media forbidden. |
| GET | `/public/login-branding` | `AdminSettingsController@publicBranding` | Public | Active login banner branding | Medium | Returns only `enabled` and conditional public `image_url`; no security settings or internal media ID. |

## Admin

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET | `/admin/dashboard/summary` | `AdminDashboardController@summary` | Admin | Admin dashboard | Low | Web admin is primary. |
| GET | `/admin/registration-requests` | `AdminRegistrationRequestController@index` | Admin | List pending registrations | Low |  |
| GET | `/admin/registration-requests/{id}` | `AdminRegistrationRequestController@show` | Admin | Registration detail | Low |  |
| POST | `/admin/registration-requests/{id}/approve` | `AdminRegistrationRequestController@approve` | Admin | Approve account | Low |  |
| POST | `/admin/registration-requests/{id}/reject` | `AdminRegistrationRequestController@reject` | Admin | Reject account | Low |  |
| GET | `/schools`, `/classes`, `/users` | `SchoolController`, `SchoolClassController`, `UserController` | Auth + scoped | Admin management lists | Low | Shared routes; admin has broad access. |
| POST/PUT/DELETE | `/schools*`, `/classes*`, `/users*` | Same controllers | Auth + scoped | Manage schools/classes/users | Low | Mobile admin not v1 priority. |
| POST | `/classes/{id}/assign-teacher` | `ClassAssignmentController@assignTeacher` | Auth + scoped | Assign teacher | Low | Admin management. |
| POST | `/classes/{id}/assign-student` | `ClassAssignmentController@assignStudent` | Auth + scoped | Assign student | Low | Admin management. |
| GET | `/admin/settings` | `AdminSettingsController@index` | Admin | Read application, banner, security, and recent activity settings | High | Typed mobile settings source. |
| PUT | `/admin/settings/application` | `AdminSettingsController@updateApplication` | Admin | Update name, subtitle, academic year, and timezone | High | Full validated application payload. |
| POST | `/admin/settings/banner` | `AdminSettingsController@updateBanner` | Admin | Enable/disable and optionally replace login banner | High | Multipart image; omitted file retains current banner. |
| PUT | `/admin/settings/security` | `AdminSettingsController@updateSecurity` | Admin | Update login-alert and weekly-report preferences | High | Preferences are persisted booleans. |

## Teacher

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET | `/teacher/dashboard/summary` | `TeacherDashboardController@summary` | Teacher | Teacher dashboard | High | Metrics aktual: `active_classes`, `active_students`, `published_modules`, `published_quizzes` untuk Kelas Aktif, Siswa Aktif, Modul Terbit, dan Kuis Terbit; scope hanya assignment Guru yang aktif. |
| GET | `/teacher/reports/progress/students` | `TeacherProgressReportController@students` | Teacher | Student progress report | Later |  |
| GET | `/teacher/reports/progress/students/export` | `ReportExportController@teacherStudents` | Teacher | CSV export | Low | Less mobile relevant. |
| GET | `/teacher/reports/quiz-results` | `TeacherQuizResultReportController@index` | Teacher | Quiz result report | Later |  |
| GET | `/teacher/reports/quiz-results/export` | `ReportExportController@teacherQuizResults` | Teacher | CSV export | Low | Less mobile relevant. |
| GET | `/classes` | `SchoolClassController@index` | Auth + scoped | Teacher class list | High | Guru hanya melihat kelas dalam single active assignment scope. |
| GET | `/classes/{id}` | `SchoolClassController@show` | Auth + scoped | Class detail | High | Detail kelas assignment sendiri; kelas asing menghasilkan 403. Resource boleh memuat email Guru, tetapi phone, password, dan field sensitif lain tidak diekspos. |
| GET | `/classes/{id}/students` | `SchoolClassController@students` | Auth + scoped | Active class memberships | High | Daftar/search hanya membership Siswa aktif pada kelas assignment sendiri; kelas asing menghasilkan 403. Resource boleh memuat email Siswa, tetapi phone, password, dan field sensitif lain tidak diekspos. |

## Student

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET | `/student/dashboard/summary` | `StudentDashboardController@summary` | Student | Student dashboard | High | Recommended first mobile screen. |
| GET | `/student/reports/progress` | `StudentProgressReportController@show` | Student | Progress report | High |  |
| GET | `/student/reports/quiz-results` | `StudentQuizResultReportController@index` | Student | Quiz result history | High |  |
| GET | `/student/modules` | `StudentModuleController@index` | Student | Assigned modules | High |  |
| GET | `/student/modules/{id}` | `StudentModuleController@show` | Student | Module detail | High | Includes lessons/progress. |
| POST | `/student/modules/{id}/start` | `StudentModuleController@start` | Student | Start module | High |  |
| PATCH | `/student/lessons/{id}/progress` | `StudentProgressController@updateLesson` | Student | Mark/update lesson progress | High |  |
| GET | `/student/progress/modules` | `StudentProgressController@modules` | Student | Module progress list | High |  |
| GET | `/student/culture` | `StudentCultureItemController@index` | Student | Culture content | High |  |
| POST | `/student/chatbot/messages` | `StudentChatbotController@store` | Student | Basis AI chatbot | High | Returns answer, source(s), provider/mode metadata. |
| GET | `/student/quizzes` | `StudentQuizController@index` | Student | Assigned quizzes | High |  |
| GET | `/student/quizzes/{id}` | `StudentQuizController@show` | Student | Quiz detail | High |  |

## Dictionary

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET | `/dictionary` | `DictionaryController@index` | Auth | Dictionary search/list | High | Student mobile core feature. |
| GET | `/dictionary/{id}` | `DictionaryController@show` | Auth | Dictionary detail | High | May include audio/media. |
| GET | `/admin/dictionary/categories` | `AdminDictionaryCategoryController@index` | Admin | Category admin list | Low | Admin web primary. |
| POST | `/admin/dictionary/categories` | `AdminDictionaryCategoryController@store` | Admin | Create category | Low |  |
| GET/PUT/DELETE | `/admin/dictionary/categories/{id}` | `AdminDictionaryCategoryController` | Admin | Category detail/update/delete | Low |  |
| GET | `/admin/dictionary/entries` | `AdminDictionaryEntryController@index` | Admin | Entry admin list | Low |  |
| POST | `/admin/dictionary/entries` | `AdminDictionaryEntryController@store` | Admin | Create entry | Low |  |
| GET/PUT/DELETE | `/admin/dictionary/entries/{id}` | `AdminDictionaryEntryController` | Admin | Entry detail/update/delete | Low |  |
| GET | `/admin/dictionary/imports/template` | `DictionaryImportController@template` | Admin | CSV template | Low |  |
| POST | `/admin/dictionary/imports/preview` | `DictionaryImportController@preview` | Admin | Import preview | Low | Multipart. |
| GET | `/admin/dictionary/imports` | `DictionaryImportController@index` | Admin | Import jobs | Low |  |
| GET | `/admin/dictionary/imports/{id}` | `DictionaryImportController@show` | Admin | Import job detail | Low |  |
| GET | `/admin/dictionary/imports/{id}/errors` | `DictionaryImportController@errors` | Admin | Import errors | Low |  |
| POST | `/admin/dictionary/imports/{id}/confirm` | `DictionaryImportController@confirm` | Admin | Confirm import | Low |  |

## Modules/Lessons

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET | `/student/modules` | `StudentModuleController@index` | Student | Student modules | High | Primary mobile path. |
| GET | `/student/modules/{id}` | `StudentModuleController@show` | Student | Student module detail | High |  |
| POST | `/student/modules/{id}/start` | `StudentModuleController@start` | Student | Start module | High |  |
| PATCH | `/student/lessons/{id}/progress` | `StudentProgressController@updateLesson` | Student | Lesson progress | High |  |
| GET | `/classes/{class_id}/modules` | `ClassModuleController@index` | Auth + scoped | Class modules | High | Guru memakai kelas assignment aktif; Web meminta `per_page=100`, `sort_by=sort_order`, `sort_direction=asc`. Kelas Guru, bukan Admin Template. |
| POST | `/classes/{class_id}/modules` | `ClassModuleController@store` | Auth + scoped | Create class module | Low | Tersedia API, tetapi Web Guru tidak menyediakan create/template apply. Tidak ditampilkan mobile. |
| PATCH | `/classes/{class_id}/modules/reorder` | `ClassModuleController@reorder` | Auth + scoped | Reorder modules | Low | Tersedia API, tetapi Web Guru tidak menyediakan reorder. Tidak ditampilkan mobile. |
| GET/PUT/DELETE | `/class-modules/{id}` | `ClassModuleController` | Auth + scoped | Module detail/update/delete | High | Mobile Web parity memakai GET/PUT; delete tersedia API tetapi tidak tersedia Web Guru. |
| POST | `/class-modules/{id}/publish` | `ClassModuleController@publish` | Auth + scoped | Publish module | High | Dipakai Web Guru dan mobile; status `published` menjadi Terbit. |
| POST | `/class-modules/{id}/archive` | `ClassModuleController@archive` | Auth + scoped | Archive module | Low | API tersedia, tidak ada aksi Web Guru; tidak ditampilkan mobile. |
| GET/POST | `/class-modules/{class_module_id}/lessons` | `ClassLessonController@index/store` | Auth + scoped | Lesson list/create | High | Mobile membaca lesson dari detail modul; create lesson tersedia API, tetapi Web Guru tidak menyediakan. |
| GET/PUT/DELETE | `/class-lessons/{id}` | `ClassLessonController` | Auth + scoped | Lesson detail/update/delete | High | Mobile memakai GET/PUT; delete tersedia API tetapi tidak tersedia Web Guru. |
| GET | `/class-lessons/{id}/content-url` | `ClassLessonController@contentUrl` | Auth + scoped | Lesson media/content URL | High | Protected media/content endpoint; path storage tidak ditampilkan. |
| POST | `/class-lessons/{id}/publish` | `ClassLessonController@publish` | Auth + scoped | Publish lesson | High | Dipakai Web Guru dan mobile; status `published` menjadi Terbit. |
| POST | `/class-lessons/{id}/archive` | `ClassLessonController@archive` | Auth + scoped | Archive lesson | Low | API tersedia, tidak ada aksi Web Guru; tidak ditampilkan mobile. |
| PATCH | `/class-modules/{id}/lessons/reorder` | `ClassLessonController@reorder` | Auth + scoped | Reorder lessons | Low | API tersedia, tetapi Web Guru tidak menyediakan reorder. Tidak ditampilkan mobile. |
| GET | `/admin/module-templates` | `AdminModuleTemplateController@index` | Admin | Admin module template list | Medium | Query: `search`, `status`, `created_by`, `page`, `per_page`, `sort_by`, `sort_direction`. |
| POST | `/admin/module-templates` | `AdminModuleTemplateController@store` | Admin | Create admin module template | Medium | Body: `title`, `description`, `status` draft/published. |
| GET | `/admin/module-templates/{id}` | `AdminModuleTemplateController@show` | Admin | Admin module template detail | Medium | Includes lessons when loaded. |
| PUT | `/admin/module-templates/{id}` | `AdminModuleTemplateController@update` | Admin | Update admin module template | Medium | Status can be draft/published/archived. |
| DELETE | `/admin/module-templates/{id}` | `AdminModuleTemplateController@destroy` | Admin | Soft delete admin module template | Medium |  |
| POST | `/admin/module-templates/{id}/publish` | `AdminModuleTemplateController@publish` | Admin | Publish admin module template | Medium | Requires at least one published lesson. |
| POST | `/admin/module-templates/{id}/archive` | `AdminModuleTemplateController@archive` | Admin | Archive admin module template | Medium |  |
| POST | `/admin/module-templates/{id}/apply` | `ModuleTemplateApplyController` | Admin | Apply template to class modules | Low | Creates Class Module snapshots. |
| GET | `/admin/module-templates/{module_template_id}/lessons` | `AdminLessonTemplateController@index` | Admin | List lesson templates | Medium | Ordered by `sort_order`. |
| POST | `/admin/module-templates/{module_template_id}/lessons` | `AdminLessonTemplateController@store` | Admin | Create lesson template | Medium | Content types: text/image/audio/pdf/video/link. |
| PATCH | `/admin/module-templates/{id}/lessons/reorder` | `AdminLessonTemplateController@reorder` | Admin | Reorder lesson templates | Medium | Payload: `lesson_ids`; must exactly match active lessons in template. |
| GET | `/admin/lesson-templates/{id}` | `AdminLessonTemplateController@show` | Admin | Lesson template detail | Medium |  |
| PUT | `/admin/lesson-templates/{id}` | `AdminLessonTemplateController@update` | Admin | Update lesson template | Medium | Media replace by new `media_id`; old media not deleted. |
| DELETE | `/admin/lesson-templates/{id}` | `AdminLessonTemplateController@destroy` | Admin | Delete lesson template | Medium |  |
| POST | `/admin/lesson-templates/{id}/publish` | `AdminLessonTemplateController@publish` | Admin | Publish lesson template | Medium | Validates content. |
| POST | `/admin/lesson-templates/{id}/archive` | `AdminLessonTemplateController@archive` | Admin | Archive lesson template | Medium |  |

## Quizzes

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET | `/student/quizzes` | `StudentQuizController@index` | Student | Quiz list | High |  |
| GET | `/student/quizzes/{id}` | `StudentQuizController@show` | Student | Quiz detail | High |  |
| POST | `/class-quizzes/{id}/attempts` | `QuizAttemptController@start` | Student | Start attempt | High | Shared path with student role middleware. |
| GET | `/quiz-attempts/{id}` | `QuizAttemptController@show` | Auth + scoped | Attempt detail/result | High | Student result after submit. |
| PUT | `/quiz-attempts/{id}/answers/{question_id}` | `QuizAttemptController@saveAnswer` | Student | Save answer | High |  |
| POST | `/quiz-attempts/{id}/submit` | `QuizAttemptController@submit` | Student | Submit quiz | High |  |
| GET | `/class-quizzes` | `ClassQuizController@index` | Auth + scoped | Class quiz list | Later | Teacher/admin management. |
| POST | `/class-quizzes` | `ClassQuizController@store` | Auth + scoped | Create class quiz | Low |  |
| GET/PUT/DELETE | `/class-quizzes/{id}` | `ClassQuizController` | Auth + scoped | Class quiz detail/update/delete | Later |  |
| POST | `/class-quizzes/{id}/publish` | `ClassQuizController@publish` | Auth + scoped | Publish quiz | Low |  |
| POST | `/class-quizzes/{id}/archive` | `ClassQuizController@archive` | Auth + scoped | Archive quiz | Low |  |
| GET/POST | `/class-quizzes/{class_quiz_id}/questions` | `QuizQuestionController@index/store` | Auth + scoped | Question list/create | Later |  |
| GET/PUT/DELETE | `/quiz-questions/{id}` | `QuizQuestionController` | Auth + scoped | Question detail/update/delete | Later |  |
| PATCH | `/class-quizzes/{id}/questions/reorder` | `QuizQuestionController@reorder` | Auth + scoped | Reorder questions | Low |  |
| GET | `/class-quizzes/{id}/attempts` | `QuizAttemptController@indexForQuiz` | Auth + scoped | Attempts for quiz | Later | Teacher/admin reporting. |
| GET | `/class-quizzes/{id}/report` | `QuizReportController@show` | Auth + scoped | Quiz report | Later |  |
| GET | `/admin/quiz-templates` | `AdminQuizTemplateController@index` | Admin | Admin quiz template list | Medium | Query: `search`, `status`, `created_by`, `page`, `per_page`, `sort_by`, `sort_direction`. |
| POST | `/admin/quiz-templates` | `AdminQuizTemplateController@store` | Admin | Create admin quiz template | Medium | Body: `title`, `description`, `instructions`, `duration_minutes`, `max_attempts`, `show_result`, `status=draft`. |
| GET | `/admin/quiz-templates/{id}` | `AdminQuizTemplateController@show` | Admin | Admin quiz template detail | Medium | Includes questions/options when loaded. |
| PUT | `/admin/quiz-templates/{id}` | `AdminQuizTemplateController@update` | Admin | Update admin quiz template | Medium | Published templates are content-locked. |
| DELETE | `/admin/quiz-templates/{id}` | `AdminQuizTemplateController@destroy` | Admin | Delete admin quiz template | Medium | Soft delete. |
| POST | `/admin/quiz-templates/{id}/publish` | `AdminQuizTemplateController@publish` | Admin | Publish admin quiz template | Medium | Requires valid questions. |
| POST | `/admin/quiz-templates/{id}/archive` | `AdminQuizTemplateController@archive` | Admin | Archive admin quiz template | Medium |  |
| POST | `/admin/quiz-templates/{id}/apply` | `QuizTemplateApplyController` | Admin | Apply quiz template to classes | Medium | Creates draft Class Quiz snapshots. |
| GET | `/admin/quiz-templates/{quiz_template_id}/questions` | `AdminQuizTemplateQuestionController@index` | Admin | List template questions | Medium | Ordered by `order_number`. |
| POST | `/admin/quiz-templates/{quiz_template_id}/questions` | `AdminQuizTemplateQuestionController@store` | Admin | Create template question | Medium | Types: `multiple_choice`, `short_answer`. |
| PATCH | `/admin/quiz-templates/{id}/questions/reorder` | `AdminQuizTemplateQuestionController@reorder` | Admin | Reorder template questions | Medium | Payload: `question_ids`; exact active template question IDs. |
| GET | `/admin/quiz-template-questions/{id}` | `AdminQuizTemplateQuestionController@show` | Admin | Question detail | Medium |  |
| PUT | `/admin/quiz-template-questions/{id}` | `AdminQuizTemplateQuestionController@update` | Admin | Update template question | Medium | Options replace only when sent. |
| DELETE | `/admin/quiz-template-questions/{id}` | `AdminQuizTemplateQuestionController@destroy` | Admin | Delete template question | Medium |  |

## Culture

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET | `/student/culture` | `StudentCultureItemController@index` | Student | Student culture feed | High |  |
| GET | `/classes/{class_id}/culture` | `ClassCultureItemController@index` | Auth + scoped | Class culture list | Later | Teacher/admin. |
| POST | `/classes/{class_id}/culture` | `ClassCultureItemController@store` | Auth + scoped | Create class culture | Low |  |
| GET/PUT/DELETE | `/class-culture-items/{id}` | `ClassCultureItemController` | Auth + scoped | Class culture detail/update/delete | Later |  |
| POST | `/class-culture-items/{id}/publish` | `ClassCultureItemController@publish` | Auth + scoped | Publish culture item | Low |  |
| POST | `/class-culture-items/{id}/archive` | `ClassCultureItemController@archive` | Auth + scoped | Archive culture item | Low |  |
| GET | `/admin/culture/items` | `AdminCultureItemController@index` | Admin | Global culture list | Medium | Query: `search`, `status`, `content_type`, `page`, `per_page`; response paginated dan tidak mengekspos ID teknis. |
| POST | `/admin/culture/items` | `AdminCultureItemController@store` | Admin | Create global culture | Medium | Field: `title`, `description`, `content_type`, `media_id` atau `external_url`, `display_order`, `status`; disalin ke kelas aktif. |
| GET/PUT/DELETE | `/admin/culture/items/{group_id}` | `AdminCultureItemController` | Admin | Global culture detail/update/soft-delete | Medium | Path memakai group ID sebagai `id` publik; bukan Class Culture. |
| POST | `/admin/culture/items/{group_id}/publish` | `AdminCultureItemController@publish` | Admin | Publish global culture | Medium | Memvalidasi judul dan sumber konten; propagasi ke salinan kelas yang masih terhubung. |
| POST | `/admin/culture/items/{group_id}/archive` | `AdminCultureItemController@archive` | Admin | Archive global culture | Medium | Data tetap tersimpan; status salinan terhubung ikut berubah. |
| `/admin/culture-templates*` | `AdminCultureTemplateController`, `AdminCultureTemplateItemController`, `CultureTemplateApplyController` | Admin | Culture template CRUD/apply | Low | Web admin primary. |

## Speaking

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET | `/student/speaking/exercises` | `StudentSpeakingController@exercises` | Student | List published global + assigned class speaking targets | High | Student visibility remains global published plus assigned class published. |
| GET | `/student/speaking/exercises/{exercise}` | `StudentSpeakingController@showExercise` | Student | Speaking target detail | High | Scoped by student class/global visibility. |
| GET | `/student/speaking/attempts` | `StudentSpeakingController@attempts` | Student | Student speaking attempt history | High | Own attempts only. |
| GET | `/student/speaking/attempts/{attempt}` | `StudentSpeakingController@showAttempt` | Student | Speaking attempt detail | High | Own attempt only. |
| POST | `/student/speaking/exercises/{exercise}/attempts` | `StudentSpeakingController@storeAttempt` | Student | Submit speaking recording | High | Stores private audio, triggers AI-assisted initial scoring. |
| GET | `/teacher/speaking/templates` | `TeacherSpeakingExerciseController@templates` | Teacher | Published admin/global speaking template list | Later | Published global exercises only; includes reference audio metadata. |
| GET | `/teacher/speaking/exercises` | `TeacherSpeakingExerciseController@index` | Teacher | Teacher speaking target list | Later | Class-scoped to active teacher assignments. |
| POST | `/teacher/speaking/exercises` | `TeacherSpeakingExerciseController@store` | Teacher | Create class speaking target | Later | `created_by_id` is server-side; teacher cannot create global targets. Optional `template_exercise_id` copies published global template fields and `reference_audio_media_id`; teacher cannot directly set/upload reference audio. |
| GET | `/teacher/speaking/exercises/{exercise}` | `TeacherSpeakingExerciseController@show` | Teacher | Speaking target detail | Later | Assigned active class only. |
| PUT/PATCH | `/teacher/speaking/exercises/{exercise}` | `TeacherSpeakingExerciseController@update` | Teacher | Update speaking target | Later | New `classroom_id`, if changed, must be assigned active class. |
| PATCH | `/teacher/speaking/exercises/{exercise}/archive` | `TeacherSpeakingExerciseController@archive` | Teacher | Archive speaking target | Later | No hard delete; status becomes `archived`. |
| GET | `/teacher/speaking/attempts` | `TeacherSpeakingController@attempts` | Teacher | Review speaking attempts | Later | Attempts for active assigned classes. |
| GET | `/teacher/speaking/attempts/{attempt}` | `TeacherSpeakingController@showAttempt` | Teacher | Speaking attempt detail | Later | Scoped by active class assignment. |
| PATCH | `/teacher/speaking/attempts/{attempt}/feedback` | `TeacherSpeakingController@feedback` | Teacher | Save teacher review | Later | Teacher final feedback remains separate from AI initial score. |
| GET | `/admin/speaking/exercises` | `AdminSpeakingExerciseController@index` | Admin | Admin speaking global template list | Medium | Query tervalidasi: `search`, `status`, `page`, `per_page`; hanya `classroom_id=null`. |
| POST | `/admin/speaking/exercises` | `AdminSpeakingExerciseController@store` | Admin | Create global speaking template | Medium | Field: `title`, `prompt_text`, `target_text`, `target_translation`, `reference_audio_media_id`, `difficulty`, `status`, `metadata`; `created_by_id` server-side. |
| GET | `/admin/speaking/exercises/{exercise}` | `AdminSpeakingExerciseController@show` | Admin | Global speaking template detail | Medium | Scoped ke template global; response tidak mengekspos storage path. |
| PUT/PATCH | `/admin/speaking/exercises/{exercise}` | `AdminSpeakingExerciseController@update` | Admin | Update/publish global speaking template | Medium | Publish melalui `status=published`; audio yang tidak dikirim tetap dipertahankan. |
| PATCH | `/admin/speaking/exercises/{exercise}/archive` | `AdminSpeakingExerciseController@archive` | Admin | Archive global speaking template | Medium | Tidak ada hard delete; status menjadi `archived`. |
| POST | `/media` | `MediaController@store` | Auth | Upload media, including `speaking_recording` | Partial | Generic private media upload. |
| GET | `/media/{id}` | `MediaController@show` | Auth | Media metadata | Partial | Protected by policy. |
| POST | `/media/{id}/temporary-url` | `MediaController@temporaryUrl` | Auth | Private media access URL | Partial | Useful for playback if authorized. |

## Basis AI / Knowledge

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| POST | `/student/chatbot/messages` | `StudentChatbotController@store` | Student | Chatbot question/answer | High | Uses dictionary, vector/keyword RAG, default fallback. |
| GET | `/admin/ai/knowledge` | `AdminAiKnowledgeController@index` | Admin | Knowledge list | Low | Web admin primary. |
| POST | `/admin/ai/knowledge` | `AdminAiKnowledgeController@store` | Admin | Manual/link/PDF-to-content knowledge create | Low | Requires content. |
| GET | `/admin/ai/knowledge/{id}` | `AdminAiKnowledgeController@show` | Admin | Knowledge detail | Low |  |
| PUT | `/admin/ai/knowledge/{id}` | `AdminAiKnowledgeController@update` | Admin | Update knowledge | Low | Rebuilds chunks. |
| DELETE | `/admin/ai/knowledge/{id}` | `AdminAiKnowledgeController@destroy` | Admin | Delete knowledge | Low |  |
| POST | `/admin/ai/knowledge/{id}/publish` | `AdminAiKnowledgeController@publish` | Admin | Publish knowledge | Low | Published items used by chatbot. |
| POST | `/admin/ai/knowledge/{id}/archive` | `AdminAiKnowledgeController@archive` | Admin | Archive knowledge | Low | Archived ignored by chatbot. |
| POST | `/admin/ai/knowledge/extract-source` | `AdminAiKnowledgeController@extractSource` | Admin | Extract public link/PDF URL into content | Low | Short/manual edit flow. |
| POST | `/admin/ai/knowledge/extract-pdf-upload` | `AdminAiKnowledgeController@extractPdfUpload` | Admin | Extract uploaded PDF into content | Low | Short PDF flow. |
| POST | `/admin/ai/knowledge/import-pdf` | `AdminAiKnowledgeController@importPdf` | Admin | Page-aware PDF RAG import | Low | Stores PDF source pages and chunks; preferred for long PDFs. |

## Media / Files

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| POST | `/media` | `MediaController@store` | Auth | Upload file/media | High | Multipart; purpose/visibility rules apply. |
| GET | `/media/{id}` | `MediaController@show` | Auth | Media metadata | High |  |
| POST | `/media/{id}/temporary-url` | `MediaController@temporaryUrl` | Auth | Temporary private access URL | High | Use for private lesson/audio/recording playback. |
| DELETE | `/media/{id}` | `MediaController@destroy` | Auth | Delete media | Medium | Owner/role policy applies. |
| GET | `/media/{id}/download` | Signed | Signed download | Medium | Relative signed URL. |
| GET | `/public/media/{id}/content` | `MediaController@publicContent` | Public | Public media content | High | For public images/audio/documents. |

## Reports / Progress

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET | `/student/reports/progress` | `StudentProgressReportController@show` | Student | Student progress report | High |  |
| GET | `/student/progress/modules` | `StudentProgressController@modules` | Student | Module progress | High |  |
| GET | `/student/reports/quiz-results` | `StudentQuizResultReportController@index` | Student | Student quiz results | High |  |
| GET | `/teacher/reports/progress/students` | `TeacherProgressReportController@students` | Teacher | Teacher progress report | Later |  |
| GET | `/teacher/reports/quiz-results` | `TeacherQuizResultReportController@index` | Teacher | Teacher quiz report | Later |  |
| GET | `/admin/reports/progress/overview` | `AdminProgressReportController@overview` | Admin | ADMIN-17 Progress overview | High | Ringkasan global, siswa dan kelas dengan filter bersama serta pagination independen. |
| GET | `/admin/reports/progress/students/{student}` | `AdminProgressReportController@student` | Admin | ADMIN-18 student progress detail | High | Identitas/status, progress, quiz summary/history paginated, speaking capability. |
| GET | `/admin/reports/progress/classes/{class}` | `AdminProgressReportController@class` | Admin | ADMIN-18 class progress detail | High | Identitas/Guru, aggregate kelas, status counts, aktivitas terakhir, siswa paginated. |
| GET | `/admin/reports/progress/pdf` | `AdminProgressReportController@pdf` | Admin | Global Progress PDF | Medium | `application/pdf`, authenticated attachment, private no-store. |
| GET | `/admin/reports/progress/students/{student}/pdf` | `AdminProgressReportController@studentPdf` | Admin | Student Progress PDF | Medium | Menggunakan report service dan scope siswa yang sama. |
| GET | `/admin/reports/progress/classes/{class}/pdf` | `AdminProgressReportController@classPdf` | Admin | Class Progress PDF | Medium | Menggunakan report service dan scope kelas yang sama. |
| GET | `/admin/reports/progress/schools` | `AdminProgressReportController@schools` | Admin | Admin school progress report | Medium | Search/status/date/sort/page/per_page; aggregate sekolah, hanya data pembelajaran sesuai scope. |
| GET | `/admin/reports/progress/classes` | `AdminProgressReportController@classes` | Admin | Admin class progress report | Medium | Filter sekolah, search/status/date/sort/page/per_page. |
| GET | `/admin/reports/progress/students` | `AdminProgressReportController@students` | Admin | Admin student progress report | Medium | Filter sekolah/kelas/siswa, search, status belajar/kuis, tanggal, sort, pagination. |
| GET | `/admin/reports/quiz-results` | `AdminQuizResultReportController@index` | Admin | Admin quiz results | Medium | Filter sekolah/kelas/kuis/siswa/status attempt/tanggal; response summary + rows paginated. |
| GET | `/admin/reports/progress/{schools|classes|students}/export`, `/admin/reports/quiz-results/export` | `ReportExportController` | Admin | CSV report export | Low | CSV attachment mengikuti filter; mobile download ditunda sampai flow save/share Android aman tersedia. |

## Other Shared Management Routes

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET/POST/PUT/DELETE | `/schools*` | `SchoolController` | Auth + scoped | School CRUD | Low | Primarily admin web. |
| GET/POST/PUT/DELETE | `/classes*` | `SchoolClassController` | Auth + scoped | Class CRUD/detail | Later | Teacher reads assigned classes; admin manages. |
| GET/PUT/PATCH | `/users*` | `UserController` | Auth + scoped | User management | Low | Admin web primary. |
