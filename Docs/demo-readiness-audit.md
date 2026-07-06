# EMI Demo Readiness Audit

Date: 2026-07-07
Branch: `feature/nextjs-web`
Scope: audit + docs only after Speaking Template + Reference Audio + Teacher Customization + Student Practice E2E passed.

## 1. Current Demo Readiness Score

**Score: 8.5 / 10 — demo-ready with operational checklist.**

EMI is ready for a guided web demo if the required local services are running and seeded demo accounts/data are available. The strongest demo path is admin → teacher → student speaking template/reference-audio E2E, plus student chatbot and core role navigation.

Do not present the Speaking AI score as authoritative Mekongga phonetic assessment. It is AI-assisted initial scoring only; teacher review is the final feedback path.

## 2. Passed Automated Checks

Latest audit run:

- Frontend `npm.cmd run lint`: passed with 4 existing `<img>` warnings.
- Frontend `npm.cmd run build`: passed.
- Backend `php artisan test`: passed, 186 tests / 1209 assertions.
- Backend `composer audit`: reports 3 known medium advisories affecting `guzzlehttp/guzzle` and `guzzlehttp/psr7`.
- Root `git diff --check`: to run after this docs update before commit.

## 3. Manual QA Already Passed

Confirmed by user/project docs:

1. Admin creates and publishes global speaking template with Suara Asli reference audio.
2. Teacher selects admin template, form auto-fills, teacher customizes fields, and publishes to own assigned class.
3. Student sees class target, plays Suara Asli, records audio, and submits.
4. AI-assisted analysis appears.
5. Teacher reviews attempt and submits manual feedback.
6. Student sees teacher feedback.

Earlier speaking QA also passed for student submit, AI analysis, teacher playback/review, and student feedback display.

Unknown browser flows are not marked passed unless listed above.

## 4. Must-Run Services for Demo

Run in separate terminals:

```cmd
cd /d "D:\!Kerjaan\EMI\Emi-Speaking-AI"
.venv\Scripts\activate
python -m uvicorn main:app --host 127.0.0.1 --port 8001
```

```cmd
cd /d "D:\!Kerjaan\EMI\Emi-Backend"
php artisan serve --host=127.0.0.1 --port=8000
```

```cmd
cd /d "D:\!Kerjaan\EMI\Emi-Backend"
php artisan queue:work
```

```cmd
cd /d "D:\!Kerjaan\EMI\Emi-Frontend"
npm.cmd run dev
```

If Python cannot find FFmpeg, set `SPEAKING_AI_FFMPEG_PATH` to the local `ffmpeg.exe` path before running Uvicorn.

Seed demo data if needed:

```cmd
cd /d "D:\!Kerjaan\EMI\Emi-Backend"
php artisan db:seed --class=DevDemoDataSeeder
```

Demo accounts:

```text
admin@emi.test / password123
guru@emi.test / password123
siswa@emi.test / password123
```

## 5. Recommended Demo Script Order

1. Login as admin.
2. Open admin dashboard to show real summary/cards.
3. Open Admin Speaking Template page.
4. Create/publish a global speaking template and upload Suara Asli audio.
5. Logout, then login as guru.
6. Open Guru Target Speaking page.
7. Select admin template, confirm auto-fill and Suara Asli preview, customize title/prompt/difficulty/status, publish to assigned class.
8. Logout, then login as siswa.
9. Open Latihan Speaking.
10. Select class target, play Suara Asli, record, submit.
11. Wait for AI-assisted result/status.
12. Logout, then login as guru.
13. Open Hasil Speaking, play student audio if needed, submit teacher score/feedback.
14. Logout, then login as siswa.
15. Open Speaking results and show teacher feedback.
16. Open student chatbot and ask one dictionary/Basis AI question.
17. Briefly show admin/guru/siswa navigation menus.

## 6. P0 Blockers

No confirmed P0 blockers for guided demo.

Operational P0 risks if environment is not prepared:

- Python Speaking AI not running → submitted attempts may remain pending or fail.
- Queue worker not running with database queue → AI analysis may not progress.
- FFmpeg unavailable for browser WebM/Opus conversion → Python analysis can fail.
- Demo database not seeded or demo accounts missing → login/demo script blocked.
- Public media/storage URL setup broken → Suara Asli playback blocked.

## 7. P1 Polish

Recommended before a more polished client demo, but not blockers for guided demo:

- Admin/teacher broad manual QA pass across non-speaking management screens.
- Browser responsive QA at Chrome laptop 100% zoom and common mobile widths.
- Shared modal accessibility polish: focus trap, escape handling, body scroll lock.
- Dense admin/teacher tables and editor forms can be hard on small screens.
- Teacher module/lesson editor layout and quiz/culture destructive confirm dialogs.
- Student quiz attempt custom confirmation/status polish.
- Progress/profile visual hierarchy polish for student and teacher.
- Clarify or implement `/teacher/media` standalone gallery later; current behavior is intentionally deferred/redirected.

## 8. P2 Optional Improvements

- Basis AI citation display polish and source viewer.
- Admin embedding workflow UI.
- Student culture detail route if desired.
- Production worker/service supervision docs or scripts.
- Production media storage/S3 review.
- Dedicated Mekongga phonetic/pronunciation model later.
- Mobile app implementation after web demo stability.

## 9. Known Non-Blocking Issues

- `composer audit` reports known medium advisories in `guzzlehttp/guzzle` and `guzzlehttp/psr7`; report only unless dependency work is explicitly requested.
- Frontend lint reports existing `<img>` warnings in auth/culture/student quiz/teacher culture files.
- Untracked `figma_doc.json`, `figma_temp.json`, and `opencode.json` are local/uncommitted and should remain uncommitted.
- Python first model download/load may be slow on first run.
- Speaking AI uses Indonesian Wav2Vec2 + similarity scoring, not authoritative Mekongga phonetic assessment.
- Queue/Python process management is local/manual, not production-supervised.
- Backend API mobile readiness doc has stale speaking-gap language; source/API route inventory now show speaking API exists. Use current route inventory and speaking docs for speaking status.

## 10. Technical Readiness Notes

- Laravel `/api/v1` route inventory covers auth, admin, teacher, student, media, dictionary, modules, quizzes, culture, reports, Basis AI, and speaking.
- Speaking routes cover admin global templates with reference audio, teacher class-scoped targets/template clone, student exercise/attempt submission, and teacher attempt feedback.
- API auth/role scoping is enforced by Sanctum role middleware plus scoped controllers/services/policies.
- Media behavior supports public Suara Asli reference audio and private speaking recordings.
- Student chatbot is demo-ready with dictionary priority, RAG keyword/vector fallback, and default extractive fallback when provider is absent.
- Mobile should consume Laravel only; do not call Python directly. Mobile speaking is possible from current API shape but still needs mobile implementation and device recording/storage work.

## 11. UI Readiness Notes

- Main role navigation is present with desktop sidebar and mobile navigation foundation.
- Dashboard and main student/teacher/admin flows are mostly OK for guided demo.
- Empty/loading/error states exist, but some screens vary in polish.
- Chrome laptop 100% zoom has not been newly re-verified in this audit; do not claim full browser QA beyond documented speaking E2E.
- Mobile responsiveness has known risks on dense tables, modals, quiz attempts, chatbot, and speaking review layouts.

## 12. Recommended Next Implementation Batch

**Batch 8: Demo hardening and responsive/manual QA pass.**

Suggested scope:

1. Run guided demo script on Chrome laptop 100% zoom with seeded data.
2. Verify admin/guru/siswa login/logout and top navigation.
3. Verify speaking template E2E once more with fresh data.
4. Check student chatbot fallback/dictionary answer.
5. Capture P0/P1 UI issues found during real browser QA.
6. Fix only the highest-impact demo issues before any deeper feature work.

Avoid new product features until demo QA confirms no blockers.
