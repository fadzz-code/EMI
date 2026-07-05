# EMI UI/UX Figma Audit

## 1. Scope

- Figma source via MCP: Figma MCP tools are available in Codex, but no Figma file URL, file key, or node-specific frame URL is present in the active prompt or repository docs. The repository search found legacy frame names in `Docs/06-Figma-Screen-Map.md`, but those entries still use `TODO: tempel link frame Figma`; therefore no visual frame was opened or compared through MCP in this batch.
- Existing frontend inspected: `Emi-Frontend/src/app`, `src/components`, `src/components/layout`, `src/components/ui`, `src/lib`, `src/features/admin`, `src/features/teacher`, `src/features/student`, auth screens, chatbot, speaking, global CSS, routes, API client, and role layout shell.
- No large UI implementation performed. This batch only creates audit/planning documentation and a light progressbar update.

## 2. Design Principles for EMI

- Figma is the visual reference for layout, spacing, typography, color, button style, card style, table/list structure, modal/dialog style, responsive intent, and information hierarchy when actual frames are accessible.
- Existing frontend is the source of functionality and route coverage.
- Laravel backend/API contracts must be preserved; polish must not alter endpoint paths, auth behavior, role guards, payloads, or error handling.
- Features missing from Figma must be preserved when they already exist in the product and are required by project status.
- Speaking remains AI-assisted initial scoring plus teacher manual review. Do not present it as final authoritative Mekongga phonetic assessment.
- Do not copy code from Figma/Weblify exports. Use Figma only as visual reference.

## 3. Global UI/UX Findings

- **P0: Admin dashboard is still a static placeholder.** `/admin/dashboard` shows dash values and stale text about future integration/speaking, while other admin modules are active. This is demo-visible and should be corrected before final UI polish or demo.
- **P1: Visual system is inconsistent across old and newer screens.** Shared UI uses a bold bordered/brutalist style, but auth screens and some feature screens hardcode colors, borders, radii, and shadows separately. Batch 2 should normalize tokens without changing behavior.
- **P1: Navigation status labels are stale.** Routes for Basis AI, Chatbot AI, Latihan Speaking, and Hasil Speaking still use `status: "next"` badges in `src/lib/routes.ts` even though several are implemented and QA-backed.
- **P1: Layout shell is serviceable but not final.** `RoleLayoutShell` uses a topbar plus sticky sidebar in a `max-w-7xl` grid. It lacks a mobile drawer/collapsible navigation pattern, so long role menus risk pushing content down on small screens.
- **P1: Tables are protected with horizontal overflow but dense actions can still be hard on mobile.** Admin dictionary, users, modules, knowledge base, progress, quiz reports, and class pages use wide tables or many action buttons. Responsive polish should convert the highest-risk tables to card/list views under small breakpoints.
- **P1: Modals are visually consistent but basic.** The shared `Modal` lacks escape-key handling, focus trap, body scroll lock, and size variants for complex forms. This is a polish/accessibility risk, not a logic rewrite request.
- **P1: Empty/loading/error states exist but vary by screen.** Shared states are available, but some speaking/chatbot/dashboard screens still use inline loading text. Batch 2 should standardize state components and wording.
- **P2: Wording hierarchy needs cleanup.** Some pages include implementation notes ("endpoint", "backend", "fase") that are helpful for development but too internal for demo users.
- **P2: Color semantics need token alignment.** Current palette mixes `#2563eb`, yellow/orange accents, `slate-*`, and hardcoded auth colors. Keep the warm EMI identity if it matches Figma, but centralize tokens.
- **P2: Card density varies.** Many screens use repeated bordered cards with heavy shadows. This is clear and functional, but a full Figma comparison may require lighter hierarchy, tighter spacing, or different card grouping.

## 4. Role-Based Audit

### Admin

- Existing screens found: dashboard, approvals, approval detail, schools/classes, class detail, users, user detail, dictionary, dictionary import, dictionary detail, knowledge base, knowledge detail, modules, module editor, quizzes, quiz builder, culture/global culture templates, progress overview, class/student progress detail, settings/profile.
- Matching Figma screens: not verifiable via MCP because no file key/frame URLs were available. Legacy docs list Admin frame names, but visual comparison is blocked.
- Missing Figma screens but existing required features: global Budaya Mekongga management, active Basis AI/RAG knowledge management, PDF/link/manual knowledge ingestion, dictionary CSV/ZIP import, progress print/export-style reporting, class assignment details.
- Major UX gaps: static admin dashboard, stale "next/placeholder" labels in some nav/docs wording, dense table/action layouts, modal accessibility, some internal/backend wording.
- Responsive risks: management tables, filter panels with many columns, modal forms for school/class/user/module/dictionary/knowledge flows.
- Priority polish list: reconnect admin dashboard summary and copy; standardize filter/table/action patterns; align knowledge/dictionary/module/culture forms to design tokens; preserve all admin-only features absent from Figma.

### Guru

- Existing screens found: dashboard, classes, class detail, class students, students, student detail, modules, module edit, lesson edit, quizzes, quiz builder, quiz results, culture, progress report, speaking results/review, profile. `/teacher/media` currently redirects to culture.
- Matching Figma screens: not verifiable via MCP because no file key/frame URLs were available. Legacy docs list Teacher frame names, but visual comparison is blocked.
- Major UX gaps: speaking review is functional but dense; class/module/quiz management uses repeated card grids that need hierarchy; media route redirect should be documented or polished if it remains.
- Responsive risks: two-column speaking review, quiz result detail, module/lesson editor, quiz builder option rows.
- Priority polish list: teacher dashboard and class shell consistency; speaking review usability; quiz result detail readability; editor forms; clarify or remove visible "backend/capability" language.

### Siswa

- Existing screens found: dashboard, modules, module detail, lesson detail, dictionary, dictionary detail, quizzes, quiz detail, quiz attempt, quiz result, culture, chatbot, progress, profile, speaking practice, speaking results.
- Matching Figma screens: not verifiable via MCP because no file key/frame URLs were available. Legacy docs list Student frame names, but visual comparison is blocked.
- Major UX gaps: chatbot is functional but looks like a general card stack instead of a focused chat surface; speaking practice works but recording/status feedback can be clearer; quiz attempt confirmation uses native browser confirm; dashboard includes internal "speaking report" capability wording.
- Responsive risks: quiz attempt image/options, chatbot conversation width, speaking two-column layout, dictionary/detail media playback, module lesson content.
- Priority polish list: student dashboard learning-first hierarchy; chatbot conversation surface; speaking recorder/status states; quiz attempt flow; mobile-friendly module/dictionary cards.

## 5. AI/RAG and Speaking Audit

- Chatbot UI findings: `StudentChatbot` supports suggested questions, pending/error state, source reference expansion, fallback answer, and source URL display. Polish should make the chat area visually primary, keep source/citation controls, and avoid implying unsourced free-form AI when RAG has no match.
- Speaking student UI findings: `StudentSpeaking` supports exercise selection, browser recording, WebM file submission, polling attempt status, AI score/transcription/error, teacher feedback, and link to results. Polish should clarify recording permission, active recording state, queue/analysis status, retry guidance, and teacher-review positioning.
- Speaking teacher review UI findings: `TeacherSpeakingResults` supports attempt list, search, detail fetch, temporary private audio URL, audio playback, AI alignment summary, teacher score, and feedback submission. Polish should improve list/detail hierarchy and keep teacher review as the authoritative correction path.
- Error/loading/status state findings: speaking and chatbot use a mix of shared `Alert` and inline text. Standardize loading/error/empty/status components without changing API calls.
- Guardrail: never call Python Speaking AI directly from frontend/mobile; keep all speaking calls routed through Laravel.

## 6. Feature Preservation List

These features must be preserved even if Figma has no explicit screen or the frame cannot be accessed:

- Budaya Mekongga admin/global content management.
- Budaya Mekongga teacher class content management.
- Budaya Mekongga student feed.
- Basis AI/RAG knowledge management.
- Manual knowledge CRUD.
- Link/source extraction.
- Uploaded PDF extraction.
- Page-aware PDF RAG import and source/page/chunk metadata.
- Chatbot AI student UI with source/reference display.
- Speaking AI student practice.
- Speaking AI student results.
- Speaking AI teacher review and manual feedback.
- Private speaking audio playback via Laravel media temporary URLs.
- Dictionary detail.
- Dictionary CSV import, ZIP audio matching, import history/errors.
- Module template apply-to-class flow.
- Quiz template/class quiz builder, result visibility rules, idempotent quiz submit.
- Admin progress detail pages and print/report views.
- Settings/profile/avatar/password flows.

## 7. Recommended Batch Plan

- **Batch 2: Design system global.** Normalize tokens, shared components, color/radius/shadow/typography, state components, and button/link styles across auth and role screens.
- **Batch 3: Layout shell/sidebar/header.** Polish role shell, responsive navigation, topbar, active states, and route status badges.
- **Batch 4: Admin polish.** Start with admin dashboard placeholder, then approvals, user/class management, dictionary/import, Basis AI, modules/quizzes, culture, progress/settings.
- **Batch 5: Guru polish.** Dashboard/classes/students, modules/lessons, quizzes/results, culture, profile, speaking review.
- **Batch 6: Siswa polish.** Dashboard, modules/lessons, dictionary/detail, quizzes/attempt/result, culture, progress/profile.
- **Batch 7: AI chatbot + Speaking polish.** Focused chat surface, citations/source display, speaking recorder/status, teacher review layout, accessible audio/status feedback.
- **Batch 8: Responsive QA.** Desktop/tablet/mobile pass across high-risk tables, forms, modals, chatbot, quiz attempt, and speaking.

## 8. Priority Matrix

| Priority | Item | Reason | Recommended Batch |
|---|---|---|---|
| P0 | Admin dashboard placeholder/static data | Demo-visible and contradicts current "mostly done" status | Batch 4 or a tiny pre-Batch 4 admin dashboard fix |
| P1 | Design token inconsistency | Blocks safe visual polish across 40+ screens | Batch 2 |
| P1 | Stale navigation `Next` badges | Misleads users for implemented Basis AI/chatbot/speaking features | Batch 3 |
| P1 | Mobile navigation lacks drawer/collapse | Role menus are long and can dominate small screens | Batch 3 |
| P1 | Dense table/form action layouts | Admin/teacher workflows are hard on small screens | Batch 4/5/8 |
| P1 | Modal accessibility gaps | Many admin workflows depend on modals | Batch 2/4 |
| P1 | Speaking/chatbot state hierarchy | Important AI-assisted flows need clearer trust/status messaging | Batch 7 |
| P2 | Internal/backend wording visible to users | Looks unfinished in demo | Batch 2 onward |
| P2 | Card/shadow density | Visual consistency and hierarchy polish | Batch 2 onward |
| P2 | Native confirm usage in quiz/culture areas | Replace with shared confirm dialog for consistency | Relevant role batch |

## 9. Risks and Guardrails

- Risk of removing existing features because they are not visible in Figma. Guardrail: frontend existing is functionality source; preserve app-only features.
- Risk of over-following stale Figma/legacy screen maps. Guardrail: compare actual MCP frames when links are available, but do not regress current product status.
- Risk of touching API/state behavior during visual polish. Guardrail: keep services, payloads, role guards, and backend error patterns unchanged unless a later prompt explicitly requests logic work.
- Risk of hiding speaking teacher review behind AI polish. Guardrail: teacher manual review remains central and must stay visible.
- Risk of mobile breakage from desktop-first grids/tables. Guardrail: each polish batch should include small-screen layout checks for affected screens.
- Risk of stale docs causing incorrect planning. Guardrail: update audit/progressbar when new Figma links or source changes are introduced.

## 10. Next Recommended Batch

Recommend **Batch 2: Design system global** first. The audit found a P0 admin dashboard placeholder, but it is a demo/content integration issue rather than a global layout blocker. Batch 2 should establish safe shared UI tokens/components, then Batch 3/4 can fix shell and admin dashboard without one-off styling drift.

## Mapping Table

| Role | Existing Route/Page | Existing Feature | Figma Frame/Reference | Match Level | Gap | Priority | Notes |
|---|---|---|---|---|---|---|---|
| Public | `/login` | Login/auth redirect | MCP not accessible; legacy docs name `AUTH-01 - Login` | Low | Visual comparison blocked; hardcoded auth styling differs from shared tokens | P1 | Keep Sanctum login and role redirect. |
| Public | `/register`, `/register/teacher`, `/register/student`, `/pending-approval` | Role registration and pending approval | MCP not accessible; legacy docs name `AUTH-02` to `AUTH-05` | Low | Visual comparison blocked; auth screens use separate hardcoded palette | P1 | Preserve public school/class lookup and pending status behavior. |
| Admin | `/admin/dashboard` | Admin landing/dashboard | MCP not accessible; legacy docs name `ADMIN-01 - Beranda Admin` | Low | Static placeholder data and stale copy | P0 | Fix before demo-facing admin polish. |
| Admin | `/admin/approvals`, `/admin/approvals/[requestId]` | Registration request list/detail/approve/reject | MCP not accessible; legacy docs name `ADMIN-02`, `ADMIN-03` | Low | Dense cards/dialogs need visual alignment | P1 | Preserve confirm/review note behavior. |
| Admin | `/admin/schools-classes`, `/admin/classes/[classId]` | School/class CRUD, teacher/student assignment | MCP not accessible; legacy docs name `ADMIN-04`, `ADMIN-05` | Low | Complex modal forms and two-column management need responsive polish | P1 | Do not alter class assignment API flow. |
| Admin | `/admin/users`, `/admin/users/[userId]` | Guru/siswa management, status/class assignment | MCP not accessible; legacy docs name `ADMIN-06`, `ADMIN-07` | Low | Wide table and modal-heavy detail screens | P1 | Preserve role/status filters. |
| Admin | `/admin/dictionary`, `/admin/dictionary/[entryId]` | Dictionary CRUD/detail/audio | MCP not accessible; legacy docs name `ADMIN-09`, `ADMIN-10` | Low | Table/actions/audio preview need Figma-aligned hierarchy | P1 | Preserve dictionary detail and audio media. |
| Admin | `/admin/dictionary/import` | CSV preview/confirm/import errors and ZIP audio | No accessible MCP frame beyond legacy `ADMIN-08` | Missing in Figma | Feature may be more detailed than Figma | P1 | Must preserve import flow even if no Figma screen. |
| Admin | `/admin/knowledge-base`, `/admin/knowledge-base/[knowledgeId]` | Basis AI knowledge CRUD/publish/archive/source preview | MCP not accessible; legacy docs name `ADMIN-11`, `ADMIN-12` but stale docs called placeholder | Missing in Figma | Current app has active feature; Figma/legacy docs may lag | P1 | Preserve manual/link/PDF knowledge management. |
| Admin | `/admin/modules`, `/admin/modules/[moduleId]/edit` | Module templates, lessons, apply-to-class | MCP not accessible; legacy docs name `ADMIN-13`, `ADMIN-14` | Low | Multi-step visibility/apply flow is text-heavy | P1 | Keep publish/apply/publish-class-content guardrail. |
| Admin | `/admin/quizzes`, `/admin/quizzes/[quizId]/builder` | Quiz templates/questions/builder/media | MCP not accessible; legacy docs name `ADMIN-15`, `ADMIN-16` | Low | Builder form/action density | P1 | Preserve image media and answer rules. |
| Admin | `/admin/culture/templates` | Global Budaya Mekongga content for classes | No clear accessible MCP frame | Missing in Figma | Feature was added after/around Figma planning | P1 | Must not remove. |
| Admin | `/admin/progress`, `/admin/progress/classes/[classId]`, `/admin/progress/students/[studentId]` | Progress reports/details/print-style views | MCP not accessible; legacy docs name `ADMIN-17`, `ADMIN-18` | Low | Tables/report cards need responsive polish | P1 | Preserve CSV/report affordances if present. |
| Admin | `/admin/settings` | Profile/settings/password/avatar subset | MCP not accessible; legacy docs name `ADMIN-19` | Low | System settings scope may differ from Figma | P2 | Do not invent backend-only settings. |
| Guru | `/teacher/dashboard` | Teacher dashboard summary/activity | MCP not accessible; legacy docs name `TEACHER-01` | Low | Internal capability wording visible | P1 | Preserve active class empty state. |
| Guru | `/teacher/classes`, `/teacher/classes/[classId]` | Class list/detail dashboard | MCP not accessible | Low | Card grids need visual hierarchy | P1 | Preserve scoped class visibility. |
| Guru | `/teacher/students`, `/teacher/students/[studentId]`, `/teacher/classes/[classId]/students` | Student list/detail/progress | MCP not accessible; legacy docs name `TEACHER-02`, `TEACHER-03` | Low | List/detail density and empty states | P1 | Preserve backend scoping. |
| Guru | `/teacher/modules`, `/teacher/classes/[classId]/modules`, `/teacher/modules/[classModuleId]/edit`, lesson edit route | Class module/lesson management | MCP not accessible; legacy docs name `TEACHER-04` to `TEACHER-06` | Low | Editor forms are dense | P1 | Preserve media/content URL behavior. |
| Guru | `/teacher/quizzes`, `/teacher/classes/[classId]/quizzes`, quiz builder/results routes | Class quiz management/results | MCP not accessible; legacy docs name `TEACHER-07` to `TEACHER-09` | Low | Builder/results need responsive detail layout | P1 | Preserve result visibility/reporting. |
| Guru | `/teacher/reports/progress` | Student progress report | MCP not accessible; legacy docs name `TEACHER-10` | Low | Table responsive risk | P1 | Preserve export/report semantics if surfaced. |
| Guru | `/teacher/speaking/results` | Speaking attempt review, audio playback, teacher score/feedback | MCP not accessible; legacy docs name `TEACHER-11` but stale docs called placeholder | Missing in Figma | Current active feature may exceed Figma | P1 | Preserve teacher manual review. |
| Guru | `/teacher/culture`, `/teacher/classes/[classId]/culture` | Class Budaya Mekongga management | No clear accessible MCP frame | Missing in Figma | Existing feature required | P1 | Preserve teacher culture CRUD/publish/archive. |
| Guru | `/teacher/media` | Redirects to culture | MCP not accessible; legacy docs name `TEACHER-12` | Low | Route behavior should be clarified | P2 | Decide in later batch whether to expose media or keep redirect. |
| Guru | `/teacher/profile` | Teacher profile | MCP not accessible; legacy docs name `TEACHER-13` | Low | Standard form polish | P2 | Preserve auth profile endpoints. |
| Siswa | `/student/dashboard` | Student dashboard/continue learning | MCP not accessible; legacy docs name `STUDENT-01` | Low | Internal capability wording visible | P1 | Preserve hidden quiz result rules. |
| Siswa | `/student/modules`, `/student/modules/[moduleId]`, `/student/lessons/[lessonId]` | Module list/detail/lesson progress | MCP not accessible; legacy docs name `STUDENT-02`, `STUDENT-03` | Low | Lesson content/card hierarchy needs polish | P1 | Preserve start/progress/content URL flow. |
| Siswa | `/student/dictionary`, `/student/dictionary/[entryId]` | Dictionary search/detail/audio | MCP not accessible; legacy docs name `STUDENT-04`, `STUDENT-05` | Low | Detail/audio presentation needs Figma check | P1 | Preserve dictionary detail even if absent elsewhere. |
| Siswa | `/student/speaking`, `/student/speaking/results` | Recording, upload, AI status/result, teacher feedback | MCP not accessible; legacy docs name `STUDENT-06`, `STUDENT-07` but stale docs called placeholder | Missing in Figma | Current active feature may exceed Figma | P1 | Preserve AI-assisted plus teacher review positioning. |
| Siswa | `/student/quizzes`, `/student/quizzes/[quizId]`, attempt/result routes | Quiz list/detail/attempt/result | MCP not accessible; legacy docs name `STUDENT-08` to `STUDENT-10` | Low | Quiz attempt needs better confirmation/status/responsive layout | P1 | Preserve idempotency and result visibility. |
| Siswa | `/student/culture` | Budaya Mekongga feed | MCP not accessible; legacy docs name `STUDENT-11` but stale docs called placeholder | Missing in Figma | Current active feature may exceed Figma | P1 | Preserve media-backed culture content. |
| Siswa | `/student/chatbot` | Basis AI chatbot with sources/fallback | MCP not accessible; legacy docs name `STUDENT-12` but stale docs called placeholder | Missing in Figma | Current active feature may exceed Figma | P1 | Preserve source/reference behavior. |
| Siswa | `/student/progress` | Student progress and quiz result report | MCP not accessible; legacy docs name `STUDENT-13` | Low | Report/table/card hierarchy polish | P1 | Preserve progress and quiz report data. |
| Siswa | `/student/profile` | Student profile | MCP not accessible; legacy docs name `STUDENT-14` | Low | Standard form polish | P2 | Preserve auth profile endpoints. |
