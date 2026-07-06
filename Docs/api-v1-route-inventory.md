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

## Teacher

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET | `/teacher/dashboard/summary` | `TeacherDashboardController@summary` | Teacher | Teacher dashboard | Later | Teacher app optional. |
| GET | `/teacher/reports/progress/students` | `TeacherProgressReportController@students` | Teacher | Student progress report | Later |  |
| GET | `/teacher/reports/progress/students/export` | `ReportExportController@teacherStudents` | Teacher | CSV export | Low | Less mobile relevant. |
| GET | `/teacher/reports/quiz-results` | `TeacherQuizResultReportController@index` | Teacher | Quiz result report | Later |  |
| GET | `/teacher/reports/quiz-results/export` | `ReportExportController@teacherQuizResults` | Teacher | CSV export | Low | Less mobile relevant. |
| GET | `/classes` | `SchoolClassController@index` | Auth + scoped | Teacher class list | Later | Teacher sees assigned classes. |
| GET | `/classes/{id}` | `SchoolClassController@show` | Auth + scoped | Class detail | Later |  |
| GET | `/classes/{id}/students` | `SchoolClassController@students` | Auth + scoped | Class students | Later |  |

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
| GET | `/classes/{class_id}/modules` | `ClassModuleController@index` | Auth + scoped | Class modules | Later | Teacher/admin management. |
| POST | `/classes/{class_id}/modules` | `ClassModuleController@store` | Auth + scoped | Create class module | Low | Teacher/admin. |
| PATCH | `/classes/{class_id}/modules/reorder` | `ClassModuleController@reorder` | Auth + scoped | Reorder modules | Low |  |
| GET/PUT/DELETE | `/class-modules/{id}` | `ClassModuleController` | Auth + scoped | Module detail/update/delete | Later |  |
| POST | `/class-modules/{id}/publish` | `ClassModuleController@publish` | Auth + scoped | Publish module | Low |  |
| POST | `/class-modules/{id}/archive` | `ClassModuleController@archive` | Auth + scoped | Archive module | Low |  |
| GET/POST | `/class-modules/{class_module_id}/lessons` | `ClassLessonController@index/store` | Auth + scoped | Lesson list/create | Later |  |
| GET/PUT/DELETE | `/class-lessons/{id}` | `ClassLessonController` | Auth + scoped | Lesson detail/update/delete | Later |  |
| GET | `/class-lessons/{id}/content-url` | `ClassLessonController@contentUrl` | Auth + scoped | Lesson media/content URL | High | Mobile should use for protected content. |
| POST | `/class-lessons/{id}/publish` | `ClassLessonController@publish` | Auth + scoped | Publish lesson | Low |  |
| POST | `/class-lessons/{id}/archive` | `ClassLessonController@archive` | Auth + scoped | Archive lesson | Low |  |
| PATCH | `/class-modules/{id}/lessons/reorder` | `ClassLessonController@reorder` | Auth + scoped | Reorder lessons | Low |  |
| `/admin/module-templates*` | `AdminModuleTemplateController`, `AdminLessonTemplateController`, `ModuleTemplateApplyController` | Admin | Template CRUD/apply | Low | Web admin primary. |

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
| `/admin/quiz-templates*` | `AdminQuizTemplateController`, `AdminQuizTemplateQuestionController`, `QuizTemplateApplyController` | Admin | Quiz template CRUD/apply | Low | Web admin primary. |

## Culture

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET | `/student/culture` | `StudentCultureItemController@index` | Student | Student culture feed | High |  |
| GET | `/classes/{class_id}/culture` | `ClassCultureItemController@index` | Auth + scoped | Class culture list | Later | Teacher/admin. |
| POST | `/classes/{class_id}/culture` | `ClassCultureItemController@store` | Auth + scoped | Create class culture | Low |  |
| GET/PUT/DELETE | `/class-culture-items/{id}` | `ClassCultureItemController` | Auth + scoped | Class culture detail/update/delete | Later |  |
| POST | `/class-culture-items/{id}/publish` | `ClassCultureItemController@publish` | Auth + scoped | Publish culture item | Low |  |
| POST | `/class-culture-items/{id}/archive` | `ClassCultureItemController@archive` | Auth + scoped | Archive culture item | Low |  |
| GET/POST | `/admin/culture/items` | `AdminCultureItemController@index/store` | Admin | Global culture CRUD | Low |  |
| GET/PUT/DELETE | `/admin/culture/items/{group_id}` | `AdminCultureItemController` | Admin | Global culture detail/update/delete | Low |  |
| POST | `/admin/culture/items/{group_id}/publish` | `AdminCultureItemController@publish` | Admin | Publish global culture | Low |  |
| POST | `/admin/culture/items/{group_id}/archive` | `AdminCultureItemController@archive` | Admin | Archive global culture | Low |  |
| `/admin/culture-templates*` | `AdminCultureTemplateController`, `AdminCultureTemplateItemController`, `CultureTemplateApplyController` | Admin | Culture template CRUD/apply | Low | Web admin primary. |

## Speaking

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET | `/student/speaking/exercises` | `StudentSpeakingController@exercises` | Student | List published global + assigned class speaking targets | High | Student visibility remains global published plus assigned class published. |
| GET | `/student/speaking/exercises/{exercise}` | `StudentSpeakingController@showExercise` | Student | Speaking target detail | High | Scoped by student class/global visibility. |
| GET | `/student/speaking/attempts` | `StudentSpeakingController@attempts` | Student | Student speaking attempt history | High | Own attempts only. |
| GET | `/student/speaking/attempts/{attempt}` | `StudentSpeakingController@showAttempt` | Student | Speaking attempt detail | High | Own attempt only. |
| POST | `/student/speaking/exercises/{exercise}/attempts` | `StudentSpeakingController@storeAttempt` | Student | Submit speaking recording | High | Stores private audio, triggers AI-assisted initial scoring. |
| GET | `/teacher/speaking/exercises` | `TeacherSpeakingExerciseController@index` | Teacher | Teacher speaking target list | Later | Class-scoped to active teacher assignments. |
| POST | `/teacher/speaking/exercises` | `TeacherSpeakingExerciseController@store` | Teacher | Create class speaking target | Later | `created_by_id` is server-side; teacher cannot create global targets. |
| GET | `/teacher/speaking/exercises/{exercise}` | `TeacherSpeakingExerciseController@show` | Teacher | Speaking target detail | Later | Assigned active class only. |
| PUT/PATCH | `/teacher/speaking/exercises/{exercise}` | `TeacherSpeakingExerciseController@update` | Teacher | Update speaking target | Later | New `classroom_id`, if changed, must be assigned active class. |
| PATCH | `/teacher/speaking/exercises/{exercise}/archive` | `TeacherSpeakingExerciseController@archive` | Teacher | Archive speaking target | Later | No hard delete; status becomes `archived`. |
| GET | `/teacher/speaking/attempts` | `TeacherSpeakingController@attempts` | Teacher | Review speaking attempts | Later | Attempts for active assigned classes. |
| GET | `/teacher/speaking/attempts/{attempt}` | `TeacherSpeakingController@showAttempt` | Teacher | Speaking attempt detail | Later | Scoped by active class assignment. |
| PATCH | `/teacher/speaking/attempts/{attempt}/feedback` | `TeacherSpeakingController@feedback` | Teacher | Save teacher review | Later | Teacher final feedback remains separate from AI initial score. |
| GET | `/admin/speaking/exercises` | `AdminSpeakingExerciseController@index` | Admin | Admin speaking global target list | Later | `classroom_id` forced null. |
| POST | `/admin/speaking/exercises` | `AdminSpeakingExerciseController@store` | Admin | Create global speaking target | Later | `created_by_id` is server-side. Reference audio nullable. |
| GET | `/admin/speaking/exercises/{exercise}` | `AdminSpeakingExerciseController@show` | Admin | Global speaking target detail | Later | Scoped to global exercises only. |
| PUT/PATCH | `/admin/speaking/exercises/{exercise}` | `AdminSpeakingExerciseController@update` | Admin | Update global speaking target | Later | `classroom_id` remains null. |
| PATCH | `/admin/speaking/exercises/{exercise}/archive` | `AdminSpeakingExerciseController@archive` | Admin | Archive global speaking target | Later | No hard delete; status becomes `archived`. |
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
| GET | `/admin/reports/progress/schools` | `AdminProgressReportController@schools` | Admin | Admin school progress report | Low |  |
| GET | `/admin/reports/progress/classes` | `AdminProgressReportController@classes` | Admin | Admin class progress report | Low |  |
| GET | `/admin/reports/progress/students` | `AdminProgressReportController@students` | Admin | Admin student progress report | Low |  |
| GET | `/admin/reports/quiz-results` | `AdminQuizResultReportController@index` | Admin | Admin quiz results | Low |  |
| GET | `*/export` report routes | `ReportExportController` | Admin/Teacher | CSV export | Low | Usually not needed in student mobile. |

## Other Shared Management Routes

| Method | Path | Controller/action | Auth/role | Purpose | Mobile relevance | Notes |
|---|---|---|---|---|---|---|
| GET/POST/PUT/DELETE | `/schools*` | `SchoolController` | Auth + scoped | School CRUD | Low | Primarily admin web. |
| GET/POST/PUT/DELETE | `/classes*` | `SchoolClassController` | Auth + scoped | Class CRUD/detail | Later | Teacher reads assigned classes; admin manages. |
| GET/PUT/PATCH | `/users*` | `UserController` | Auth + scoped | User management | Low | Admin web primary. |
