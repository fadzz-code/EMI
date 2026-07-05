# EMI Progressbar

## 1. Progress Rules

- GPT Chat is used for planning and evaluation.
- OpenCode is used for repository execution.
- Every new OpenCode task must read `Docs/progressbar.md` and relevant Docs first.
- If a task completes an item, update its checkbox to `[x]`.
- If a task partially completes an item, leave unchecked and add a short note.
- If user changes a feature concept, update the related todo item instead of blindly following the old wording.
- If a new task discovers a missing feature/bug, add it to the appropriate section.
- If task scope changes, update `progressbar.md` in the same commit when safe.
- Do not mark manual QA as done unless user or executor actually performed it.
- Do not mark deployment as done unless deployed and verified.
- Documentation can lag behind source code; source code and verified command output win.
- Never include secrets or real `.env` values.

## 2. Current Snapshot

Current focus: Mobile MVP planning after full speaking siswa + guru manual QA passed.

Last known local HEAD before this task: `cb0ea23 docs: record speaking qa ffmpeg setup`.
Remote may be behind local if user has not pushed.

High-level status:

- Admin web: mostly OK.
- Teacher web: mostly OK.
- Student web: mostly OK.
- Basis AI/RAG: demo-ready.
- Speaking: integrated end-to-end and passed full siswa + guru manual QA.
- Mobile: not started; should consume Laravel API, not a separate backend.

## 3. Global Setup / Repository

- [x] Verify git status before every task.
- [x] Keep Python `.venv` ignored and do not delete it.
- [x] Avoid `git add .`.
- [x] Avoid `git clean`.
- [x] Push only when user explicitly asks.
- [x] Keep Laravel backend as canonical API and data source.
- [x] Keep Next.js web as frontend client, not a business-rule source of truth.
- [x] Keep Python Speaking AI private/internal.
- [ ] Keep older docs aligned with current source when they are used for planning.
- [ ] Add/update route inventory when API surface changes.

## 4. Backend Core

- [x] Auth API with register/login/logout/me/profile/password.
- [x] Laravel Sanctum token auth.
- [x] Role access for admin, teacher, student.
- [x] Public school/class lookup.
- [x] Admin approval flow for teacher/student registration.
- [x] School and class management.
- [x] Teacher assignment and student membership management.
- [x] User management and status handling.
- [x] Media/private URL handling.
- [x] Avatar upload/remove.
- [x] Audit logs for important administrative actions.
- [x] Queue worker notes for async jobs.
- [x] Route inventory documentation exists.
- [x] Standard API response shape.
- [x] IDOR/scoping tests across core domains.
- [ ] Production queue worker supervision setup.
- [ ] Production storage/link/S3 review.

## 5. Admin Web

- [x] Dashboard.
- [x] Registration approval pages.
- [x] User management.
- [x] School/class management.
- [x] Module/lesson template management.
- [x] Quiz template management.
- [x] Dictionary management.
- [x] Dictionary CSV/ZIP import.
- [x] Culture templates.
- [x] Global culture management.
- [x] Basis AI knowledge base.
- [x] PDF extraction/import.
- [x] PDF RAG import.
- [x] Progress/reports pages.
- [x] Settings page.
- [ ] PDF source/page citation display polish if client requests it.
- [ ] Admin embedding workflow UI if client requests it.
- [x] Admin dashboard UI/data polish before demo: placeholder/static values replaced with real `/admin/dashboard/summary` data, honest loading/error/empty states, and Figma-aligned hero/stats/actions layout.
- [x] Batch 4B admin table/form/content polish completed for approvals, user/class management, dictionary/import, Basis AI, modules/quizzes, culture, progress, and settings without backend/API logic changes.
- [x] Batch 4C admin detail/editor polish completed for demo-visible admin editors: user/class detail, module editor, quiz builder, dictionary detail, Basis AI form/detail fallback, and Budaya Mekongga global/template editor wording/layout without backend/API logic changes.
- [ ] Admin detail/editor follow-up if client requests deeper polish: approval detail, progress class/student detail, modal accessibility/focus behavior, and browser responsive QA across edited admin detail screens.
- [ ] Admin broad manual QA pass after latest changes.

## 6. Teacher Web

- [x] Dashboard.
- [x] Class access.
- [x] Student list/detail access.
- [x] Class module/lesson management.
- [x] Class quiz management.
- [x] Quiz result view.
- [x] Culture management.
- [x] Speaking result review page.
- [x] Teacher speaking manual feedback API/UI.
- [x] Profile.
- [x] Media page.
- [x] Verify teacher speaking review with real student attempt.
- [x] Batch 5 guru screens polish completed for dashboard, class/student/progress views, modules/quizzes/results, culture/media/profile copy, and speaking review hierarchy without backend/API/Python changes.
- [ ] Teacher follow-up polish if requested: deeper module/lesson editor form layout, shared confirm dialogs for destructive quiz/culture actions, and browser responsive QA across edited guru screens.
- [ ] Remaining teacher QA pass.

## 7. Student Web

- [x] Dashboard.
- [x] Modules.
- [x] Lessons.
- [x] Dictionary.
- [x] Dictionary detail.
- [x] Quizzes.
- [x] Quiz attempt.
- [x] Quiz result.
- [x] Culture.
- [x] Basis AI chatbot.
- [x] Progress.
- [x] Profile.
- [x] Speaking practice UI.
- [x] Speaking results UI.
- [x] Browser recording upload sends named WebM file.
- [x] Friendly speaking upload validation message in frontend.
- [x] Speaking practice real-browser student submit and AI-analysis QA.
- [x] Speaking results show AI score/transcription for real student attempt.
- [x] Batch 6 siswa screens polish completed for dashboard, module/lesson learning flow, quiz list/detail/result, dictionary list/detail, culture feed readability, and light chatbot/speaking entry cards from dashboard without backend/API/Python changes.
- [ ] Student follow-up polish if requested: progress/profile visual hierarchy, quiz attempt custom confirmation/status polish, detailed chatbot/speaking UI polish in Batch 7, and browser responsive QA across edited siswa screens.
- [ ] Remaining student QA pass.

## 8. Basis AI / RAG

- [x] Manual knowledge CRUD.
- [x] Link/source extraction.
- [x] Uploaded PDF extraction.
- [x] Page-aware PDF import.
- [x] Source page storage.
- [x] Knowledge chunk generation.
- [x] Dictionary retriever priority.
- [x] Embedding provider abstraction.
- [x] pgvector doctor command.
- [x] Embedding persistence.
- [x] Vector retrieval fallback.
- [x] Keyword fallback.
- [x] Default extractive fallback.
- [x] PDF source library/page-aware chunks.
- [x] TOC/OCR/front-matter retrieval quality filtering.
- [x] Optional AI provider polish path.
- [ ] Citation display polish.
- [ ] Admin embedding workflow UI.
- [ ] Quota/rate limit if desired.
- [ ] Production AI provider key setup using secrets manager or environment only.

## 9. Dictionary

- [x] Dictionary categories.
- [x] Dictionary entries.
- [x] Search/list/detail API.
- [x] Student dictionary web pages.
- [x] Admin dictionary web pages.
- [x] Public audio media validation for entries.
- [x] CSV template.
- [x] Import preview.
- [x] Import confirm/job processing.
- [x] ZIP audio exact filename matching.
- [x] Duplicate strategies.
- [x] Import history/errors.
- [x] Dictionary retriever for chatbot.
- [ ] Final content/data QA with real dictionary dataset.

## 10. Speaking

- [x] Python service initial implementation.
- [x] Python service validates file size/type.
- [x] Python service exposes `/health` and `/predict`.
- [x] Laravel speaking exercises/attempts.
- [x] Student speaking API.
- [x] Teacher speaking API.
- [x] Private media storage for recordings.
- [x] Queue job for AI analysis.
- [x] AI result persistence.
- [x] Teacher manual review/feedback.
- [x] Web student recording/upload.
- [x] Web teacher review.
- [x] Fix `validation.mimetypes` browser upload issue.
- [x] Audio upload MIME acceptance for safe browser formats.
- [x] Python accepts safe browser WebM/Opus MIME variants.
- [x] Python validates ffmpeg conversion output before transcription.
- [x] No frontend direct call to Python service.
- [x] Manual QA end-to-end passed for siswa record/submit, AI analysis, guru playback/review, and siswa feedback display. Local run used WinGet FFmpeg with `SPEAKING_AI_FFMPEG_PATH` when PATH lookup failed.
- [x] Status polling reaches completed in manual QA.
- [x] Teacher feedback verify from student side.
- [ ] Python service hardening for production.
- [ ] Server-side duration probing if needed.
- [ ] Mobile speaking later after web QA stable.
- [ ] Production worker/service setup later.

## 11. Mobile Preparation

- [x] Decide mobile should use Laravel API.
- [x] Document that no separate backend is needed now.
- [x] Auth/token flow documented.
- [x] Student-first build order recommended.
- [x] API route inventory exists.
- [ ] Update route inventory speaking section to reflect latest dedicated routes if using it for mobile planning.
- [ ] Mobile UI/UX implementation.
- [ ] Secure token storage implementation.
- [ ] Student dashboard mobile.
- [ ] Student modules/lessons mobile.
- [ ] Student dictionary mobile.
- [ ] Student quizzes mobile.
- [ ] Student culture mobile.
- [ ] Student chatbot mobile.
- [ ] Speaking mobile only after QA stable.

## 12. Documentation / Handover

- [x] Legacy project handover exists.
- [x] Backend API mobile readiness handover exists.
- [x] API v1 route inventory exists.
- [x] Speaking AI integration doc exists.
- [x] Current reusable project handover exists.
- [x] Reusable progressbar exists.
- [x] AI workflow protocol exists.
- [x] `Docs/Progress.md` replaced by `Docs/progressbar.md`.
- [x] Batch 1 UI/UX audit existing web vs Figma MCP completed in `Docs/ui-ux-figma-audit.md`.
- [x] UI polish guardrail documented: preserve existing app-only features even when Figma frames are missing/inaccessible, including Budaya Mekongga, Basis AI/RAG, speaking teacher review, dictionary detail/import, and PDF/link/manual knowledge ingestion.
- [x] Batch 1.5 Figma MCP visual mapping completed in `Docs/ui-ux-figma-audit.md`; Figma file was accessible and 104 top-level frames were inventoried/mapped.
- [x] Batch 2 global web design system foundation completed in Next.js: semantic tokens, Figma-aligned typography, shared UI primitives, shell primitives, and state components normalized without changing logic/API behavior.
- [x] Batch 3 layout shell/sidebar/header responsive base completed in Next.js: sticky role topbar, desktop sidebar panel, mobile full menu, mobile bottom nav, active navigation states, and stale implemented-feature `Next` badges cleaned without changing routes/API behavior.
- [x] Batch 4 admin dashboard P0 polish completed in Next.js: dashboard now uses existing Laravel summary API data, demo-safe copy, loading/error/empty states, quick admin actions, and operational signals without backend/API changes.
- [x] Batch 5 guru screens polish completed in Next.js: Figma-aligned dashboard hero/stats, speaking review status hierarchy, progress mobile cards, student search, non-technical guru copy, and media-route clarification without changing API contracts.
- [x] Batch 6 siswa screens polish completed in Next.js: visible dashboard hero/quick actions, module progress bars, lesson journey cards, quiz/result hierarchy, dictionary detail readability, and culture content cards without changing API contracts.
- [ ] Keep route inventory current after speaking route additions.
- [ ] Refresh stale legacy docs if they become active planning references.

## 13. Deployment / Production Readiness

- [ ] Storage link/public disk production verification.
- [ ] Private storage access verification.
- [ ] Queue worker supervisor/systemd setup.
- [ ] Python Speaking AI process management.
- [ ] Python Speaking AI private network/firewall setup.
- [ ] Environment example review.
- [ ] Backup strategy.
- [ ] Security headers/CORS production review.
- [ ] Composer audit advisories reviewed.
- [ ] NPM audit/dependency review if required.
- [ ] Monitoring/logging plan.

## 14. Known Bugs / QA Issues

- [x] Full siswa + guru speaking manual QA completed: student submit, AI analysis, teacher playback/review, and student feedback display passed.
- [x] Confirm speaking status progression reaches completed with `QUEUE_CONNECTION=database` and real queue worker for student AI-analysis flow.
- [x] Confirm teacher feedback appears correctly for student after review.
- [x] Confirm no `validation.mimetypes` error after `79bbbe9` in real browsers.
- [x] Confirm no Python `Jenis audio tidak didukung.` error after browser WebM/Opus MIME fix.
- [x] Confirm no Python 500 decode/conversion error after ffmpeg conversion hardening when `SPEAKING_AI_FFMPEG_PATH` points to WinGet FFmpeg.
- [ ] Confirm Python model first-download behavior is acceptable for local/prod setup.
- [x] UI audit found `/admin/dashboard` still uses placeholder/static values and stale implementation copy; addressed by Batch 4 dashboard polish using real `/admin/dashboard/summary` data.
- [ ] UI mapping found Figma `TEACHER-12 - Media Kelas`, while current `/teacher/media` does not have a standalone gallery endpoint; Batch 5 clarified copy/upload behavior, but a true media library remains deferred.
- [ ] Review known composer audit advisories for `guzzlehttp/guzzle` and `guzzlehttp/psr7`; do not modify dependencies unless user asks.

## 15. Deferred / Future Enhancements

- [ ] Dedicated Mekongga phonetic/pronunciation model or scoring approach.
- [ ] Offline mobile sync.
- [ ] Push notifications.
- [ ] ESP32/IoT integration.
- [ ] Advanced analytics.
- [ ] Rate limits/quotas for AI usage.
- [ ] Richer citation UI and source viewer for Basis AI.
- [ ] Background embedding management UI.
- [ ] Production-grade speech inference scaling.

## 16. Completed Log

- `cb0ea23` — Documented speaking QA FFmpeg setup.
- `a2fceb9` — Stabilized speaking audio conversion with ffmpeg.
- `7f2eddd` — Supported browser WebM speaking audio in Python service.
- `79bbbe9` — Fixed browser speaking audio upload validation.
- `da68f90` — Connected speaking practice web UI.
- `55056a3` — Added speaking AI integration foundation.
- `41cbfcf` — Added backend API mobile readiness handover.
- `b4d9e77` — Improved PDF RAG retrieval quality.
- `9db03b9` — Separated PDF RAG import from manual content.
- `493d7ba` — Added page-aware PDF knowledge ingestion.
- `11ead5c` — Added vector retrieval fallback path.
- `f37e73a` — Added knowledge chunk embedding persistence.
- `e498e32` — Added embedding provider foundation.
- `698bdbf` — Added vector RAG readiness diagnostics.
- `2c79d1c` — Added dictionary retriever for chatbot.
