# EMI UI/UX Figma Audit

## 1. Scope

- Figma source via MCP: Batch 1 was blocked because no Figma URL was available. Batch 1.5 inspected `https://www.figma.com/design/tZcPOdYQhry2xHzm1B0UIC/Untitled?node-id=0-1&p=f&t=Dg5Gf5gwDyf7Sfxx-0` through Figma MCP. The file was accessible and contains 104 top-level frames on `Page 1`.
- Existing frontend inspected: `Emi-Frontend/src/app`, `src/components`, `src/components/layout`, `src/components/ui`, `src/lib`, `src/features/admin`, `src/features/teacher`, `src/features/student`, auth screens, chatbot, speaking, global CSS, routes, API client, and role layout shell.
- No large UI implementation performed. This batch only creates audit/planning documentation and a light progressbar update.

## Figma MCP Visual Mapping

### Figma Access

- URL inspected: `https://www.figma.com/design/tZcPOdYQhry2xHzm1B0UIC/Untitled?node-id=0-1&p=f&t=Dg5Gf5gwDyf7Sfxx-0`
- MCP access status: accessible. Figma MCP listed `Page 1` (`0:1`) and read its frame tree.
- Pages/frames discovered: 1 page, 104 top-level frames.
- Frame naming quality: desktop frames are clear for auth, admin, teacher, and student. Mobile/responsive frames use a mix of role-specific names and generic `SCREEN N` names, but most map cleanly by title.
- Limitations: this audit used MCP metadata and programmatic frame inspection, not a pixel-perfect visual QA pass against running frontend screenshots. Some text nodes are named generically as `Text`, so design-token readings are approximate.

### Frame Inventory

| Figma Page | Figma Frame | Inferred Role | Inferred Screen | Notes |
|---|---|---|---|---|
| Page 1 | `AUTH-01` to `AUTH-05` | Public/Auth | Login, role selection, teacher register, student register, pending approval | Desktop auth set. |
| Page 1 | `ADMIN-01` to `ADMIN-19` | Admin | Dashboard through settings | Desktop admin set. `ADMIN-5` is named without zero padding but maps to class detail. |
| Page 1 | `TEACHER-01` to `TEACHER-13` | Guru | Dashboard through profile/media/speaking | Desktop teacher set. Culture management is not explicit in the desktop teacher frame names. |
| Page 1 | `STUDENT-01` to `STUDENT-14` | Siswa | Dashboard through profile | Desktop student set. |
| Page 1 | `Pilih Jenis Akun EMI (Mobile)` to `Menunggu Persetujuan Admin (Mobile)` | Public/Auth | Mobile auth variants | Responsive reference for auth screens. |
| Page 1 | `SCREEN 1` to `SCREEN 17` at admin-mobile area | Admin | Mobile admin dashboard/menu/management/progress/settings | Responsive/mobile admin variants. |
| Page 1 | `SCREEN 1` to `SCREEN 13` at teacher-mobile area | Guru | Mobile teacher dashboard/menu/students/modules/quizzes/speaking/media/profile | Responsive/mobile teacher variants. |
| Page 1 | `SCREEN 1` to `SCREEN 18` at student-mobile area | Siswa | Mobile student dashboard/menu/modules/dictionary/speaking/quizzes/culture/chatbot/progress/profile/sync | Responsive/mobile student variants. Includes mobile-only offline/sync concepts. |

### Figma-to-App Mapping

| Role | Figma Frame | Existing Route/Page | Match Level | Gap | Priority | Notes |
|---|---|---|---|---|---|---|
| Public | `AUTH-01 - Login` | `/login` | High | Visual polish needed; app already follows similar bold auth style | P1 | Preserve login, role redirect, and API error handling. |
| Public | `AUTH-02 - Registrasi Pilih Role` | `/register` | High | Needs token/style alignment only | P1 | Existing route chooses guru/siswa. |
| Public | `AUTH-03 - Registrasi Guru` | `/register/teacher` | High | Visual style close but should use shared design tokens | P1 | Preserve school/class lookup. |
| Public | `AUTH-04 - Registrasi Siswa` | `/register/student` | High | Visual style close but should use shared design tokens | P1 | Preserve pending approval flow. |
| Public | `AUTH-05 - Menunggu Persetujuan Admin` | `/pending-approval` | High | Align copy/spacing to Figma | P2 | No logic changes needed. |
| Admin | `ADMIN-01 - Beranda Admin` | `/admin/dashboard` | Medium | Batch 4 replaced the placeholder with real `/admin/dashboard/summary` data, Figma-aligned hero/stats/actions, and honest states; deeper admin dashboard content polish can continue later | Done/P1 | Preserve real API data and avoid dummy demo values. |
| Admin | `ADMIN-02`, `ADMIN-03` | `/admin/approvals`, `/admin/approvals/[requestId]` | Medium | Existing functionality present; visual/table/card hierarchy needs alignment | P1 | Preserve approve/reject review flow. |
| Admin | `ADMIN-04`, `ADMIN-5` | `/admin/schools-classes`, `/admin/classes/[classId]` | Medium | Figma includes clearer dashboard/detail hierarchy; app uses modal-heavy management | P1 | Preserve school/class CRUD and assignment behavior. |
| Admin | `ADMIN-06`, `ADMIN-07` | `/admin/users`, `/admin/users/[userId]` | Medium | Existing route has table/detail; needs Figma filters, status chips, and edit hierarchy polish | P1 | Preserve user status and class assignment. |
| Admin | `ADMIN-08` to `ADMIN-10` | `/admin/dictionary/import`, `/admin/dictionary`, `/admin/dictionary/[entryId]` | High | Existing routes cover the Figma flow; polish tables/import cards/audio preview | P1 | Dictionary import/detail must remain. |
| Admin | `ADMIN-11`, `ADMIN-12` | `/admin/knowledge-base`, `/admin/knowledge-base/[knowledgeId]` | Medium | Figma covers basic AI knowledge but not all current RAG ingestion details | P1 | Preserve PDF/link/manual ingestion and source metadata. |
| Admin | `ADMIN-13`, `ADMIN-14` | `/admin/modules`, `/admin/modules/[moduleId]/edit` | Medium | App has extra apply-to-class behavior beyond Figma wording | P1 | Preserve apply-to-class and publish-class-content guardrail. |
| Admin | `ADMIN-15`, `ADMIN-16` | `/admin/quizzes`, `/admin/quizzes/[quizId]/builder` | Medium | Figma covers quiz template/builder; app details may need visual simplification | P1 | Preserve question image and answer rules. |
| Admin | `ADMIN-17`, `ADMIN-18` | `/admin/progress`, detail routes | Medium | App report routes exist; Figma emphasizes progress dashboards | P1 | Preserve class/student detail report routes. |
| Admin | `ADMIN-19` | `/admin/settings` | Medium | Existing route is profile/settings subset, not broad system settings | P2 | Do not invent unsupported backend settings. |
| Guru | `TEACHER-01` | `/teacher/dashboard` | Medium | Existing dashboard functional; remove internal capability wording and align cards | P1 | Preserve empty assignment state. |
| Guru | `TEACHER-02`, `TEACHER-03` | `/teacher/students`, `/teacher/students/[studentId]` | Medium | Existing reports/detail present; needs hierarchy/table polish | P1 | Preserve scoped student access. |
| Guru | `TEACHER-04` to `TEACHER-06` | `/teacher/modules`, module/lesson edit routes | Medium | Existing app supports modules/lessons but editor density differs | P1 | Preserve media/content URL flow. |
| Guru | `TEACHER-07` to `TEACHER-10` | `/teacher/quizzes`, builder/results, `/teacher/reports/progress` | Medium | Existing functionality present; needs Figma dashboard/table/card polish | P1 | Preserve result visibility and report logic. |
| Guru | `TEACHER-11 - Hasil Speaking` | `/teacher/speaking/results` | Medium | Existing feature active and QA-backed; Figma can guide review layout | P1 | Keep teacher manual review central. |
| Guru | `TEACHER-12 - Media Kelas` | `/teacher/media` | Low | App route redirects to culture and has no standalone media library | P1 | Either implement later by prompt or document as intentionally redirected. |
| Guru | `TEACHER-13 - Profil Guru` | `/teacher/profile` | Medium | Existing profile route present; visual polish only | P2 | Preserve auth profile endpoint. |
| Siswa | `STUDENT-01 - Beranda Belajar` | `/student/dashboard` | Medium | Existing dashboard works; Figma has richer achievement/quick menu pattern | P1 | Preserve hidden quiz result behavior. |
| Siswa | `STUDENT-02`, `STUDENT-03` | `/student/modules`, `/student/modules/[moduleId]`, `/student/lessons/[lessonId]` | Medium | Existing route structure differs from Figma naming but feature exists | P1 | Preserve lesson progress/content URL flow. |
| Siswa | `STUDENT-04`, `STUDENT-05` | `/student/dictionary`, `/student/dictionary/[entryId]` | High | Existing feature maps directly; polish search/detail/audio cards | P1 | Preserve dictionary audio handling. |
| Siswa | `STUDENT-06`, `STUDENT-07` | `/student/speaking`, `/student/speaking/results` | Medium | Existing feature active and QA-backed; Figma guides recorder/result layout | P1 | Keep AI-assisted + teacher review wording. |
| Siswa | `STUDENT-08` to `STUDENT-10` | `/student/quizzes`, quiz detail/attempt/result routes | Medium | Existing flow present; quiz attempt/result needs Figma hierarchy and responsive polish | P1 | Preserve idempotent submit and result visibility. |
| Siswa | `STUDENT-11` | `/student/culture` | Medium | Existing culture feed present; Figma also has mobile detail content screen | P1 | No detail route exists yet. |
| Siswa | `STUDENT-12 - Chatbot AI` | `/student/chatbot` | Medium | Existing chatbot has source references; Figma guides focused chat layout | P1 | Preserve references/sources. |
| Siswa | `STUDENT-13`, `STUDENT-14` | `/student/progress`, `/student/profile` | Medium | Existing routes present; visual polish needed | P1/P2 | Preserve profile/progress APIs. |
| Web responsive | Mobile auth/admin/guru/siswa `SCREEN` frames | Same route families as above | Ambiguous | These are responsive references, not separate routes | P1 | Use for Batch 8 responsive QA and shell/mobile nav design. |
| Siswa/Future mobile | `SCREEN 5 - Mode Offline / Unduhan Materi`, `SCREEN 18 - Sinkronisasi Data` | No existing web route | Missing in App | Offline/sync is future enhancement, not current web scope | P2 | Do not build in Batch 2 unless explicitly requested. |
| Siswa | `SCREEN 14 - Detail Konten Budaya` | No existing `/student/culture/[id]` route found | Missing in App | Figma has detail content pattern; app currently has feed only | P2 | Add only in a later feature batch if requested. |

### Features Present in App but Missing/Unclear in Figma

- Admin global Budaya Mekongga management (`/admin/culture/templates`) is not explicit in desktop Figma admin frames.
- Teacher Budaya Mekongga class management (`/teacher/culture`, class culture redirects) is not explicit in desktop teacher frames.
- Basis AI has Figma screens, but current app also includes PDF extraction/import, link extraction, manual ingestion, publish/archive, preview/source metadata, and page-aware RAG behavior that are not fully represented.
- Chatbot source/reference expansion exists in the app; Figma chatbot should be checked in polish to ensure citations/source affordances are not lost.
- Speaking teacher review is present in Figma and app, but app-specific private audio temporary URL behavior must be preserved.
- Dictionary CSV/ZIP import is represented in Figma and app; import history/errors and duplicate strategies are app/API guardrails that may not be visually explicit.
- Module apply-to-class and class-content publish behavior exists in app and is only partly suggested by Figma.
- Teacher class culture routes and class-specific module/quiz shortcut routes exist in app but are not one-to-one with Figma frames.
- `/teacher/media` is shown as a Figma concept, while the current app redirects it to culture.

### Design System Signals from Figma

- **Primary colors:** warm ink/brown `#241914`, muted brown `#564338`, paper/cream `#fff8f6`, white `#ffffff`, orange `#ff8a3d`, yellow `#fdd758`, green `#5bbe5d`, danger red `#ba1a1a`.
- **Typography:** dominant desktop UI uses Quicksand; mobile/student responsive frames heavily use Plus Jakarta Sans; auth frames also show Lexend and Work Sans. Batch 2 should choose a practical web font strategy rather than mixing all families blindly.
- **Spacing/layout:** desktop role screens use fixed 1280px artboards with sidebars/topbars, large 48px content padding, stats grids, hero/header cards, and two-column content sections. Mobile frames use 390px width, top app bars, bottom nav bars, and stacked cards.
- **Radius:** common radii are 8px and 12px, with pill chips at 9999px.
- **Card style:** white/cream surfaces, thick dark strokes, visible drop shadows, and strong section separation.
- **Button style:** bold filled orange/yellow/green actions with dark borders/shadows; secondary actions use white/cream fills with strong borders.
- **Table/list style:** Figma favors status chips, search bars, filters, card-like rows, and clear table headers; app tables should remain functional but become more mobile-card-friendly.
- **Modal/dialog style:** standalone modal components are not clearly isolated in the Figma frame tree; use Figma cards/forms as style reference and preserve existing app modal behavior until a specific modal design is provided.
- **Dashboard pattern:** hero/header card, stats grid, quick actions, recent activity/task list. This directly highlights the current admin dashboard placeholder gap.
- **Responsive clues:** Figma provides separate mobile variants for auth, admin, teacher, and student, including bottom navigation. Current web shell uses sidebar/topbar and should gain responsive nav polish in a later batch.

### Batch 2 Design System Foundation Update

- Batch 2 implemented the first global web design system foundation in the Next.js frontend without changing application logic, API calls, routes, auth guards, backend, or Python Speaking AI behavior.
- Global CSS now exposes semantic Tailwind v4 tokens for paper, surface, border, muted text, primary orange, accent yellow, success, danger, info, radii, and EMI shadows.
- Root typography now uses Quicksand and Plus Jakarta Sans through `next/font/google`, matching the dominant Figma direction while avoiding a noisy mix of every font family seen in frames.
- Shared primitives were aligned to the new token vocabulary: button, card, badge, alert, input, textarea, select, table, modal, filter panel, page header, sidebar, topbar, stats card, and loading/empty/error states.
- Batch 2 intentionally did not fix page-specific layout gaps, dashboard data placeholders, modal accessibility behavior, route status badges, or responsive navigation. Those remain for later batches.

### Batch 3 Shell/Navigation Foundation Update

- Batch 3 implemented the shared role layout shell polish without changing application routes, API calls, auth guards, backend, or Python Speaking AI behavior.
- The role topbar is now sticky, width-aligned to the 1280px shell, and uses the Batch 2 EMI token vocabulary for brand, border, and text hierarchy.
- The desktop sidebar is now a bordered/shadowed navigation panel with consistent active states, `aria-current`, hover states, and hidden-on-mobile behavior.
- Mobile/tablet now has a full route menu through a native collapsible navigation plus a fixed five-item bottom nav inspired by Figma mobile bottom bars. Bottom padding was added so content is not covered.
- Stale `Next` badges were removed from implemented/usable features: admin Basis AI, teacher Hasil Speaking, student Latihan Speaking, and student Chatbot AI.
- Batch 3 intentionally did not redesign page content, fix the admin dashboard placeholder, implement mobile/offline/sync concepts, or resolve the teacher media route mismatch.

### Batch 4 Admin Dashboard Update

- Batch 4 addressed the P0 `/admin/dashboard` placeholder/static values issue without changing backend/API contracts.
- The admin dashboard now uses the existing Laravel endpoint `/admin/dashboard/summary` through the current frontend service layer and TanStack Query.
- Dummy dash values and stale implementation copy were removed. Loading, error, retry, and empty states now clearly reflect the backend/API state.
- The dashboard now follows the Figma direction more closely with a warm hero card, real stats grid, quick admin actions, and operational signals.
- Preserved admin feature entry points: approvals, school/class management, dictionary import, Basis AI/RAG, modules, quizzes, Budaya Mekongga, progress, and settings.
- Batch 4B polished admin management/list/form screens: approvals, user/class management, dictionary/import, Basis AI list, module/quiz list and apply modals, Budaya Mekongga list, progress overview, and settings copy.
- Batch 4C polished demo-visible admin detail/editor screens: user detail, class detail, module editor and lesson form wording, quiz builder and question form wording, dictionary detail, Basis AI form/detail fallback, Budaya Mekongga global content form, and culture template editor copy.
- Remaining admin polish notes: approval detail and progress detail routes can still receive a deeper visual pass; shared modal accessibility/focus behavior and browser responsive QA remain deferred.

## 2. Design Principles for EMI

- Figma is the visual reference for layout, spacing, typography, color, button style, card style, table/list structure, modal/dialog style, responsive intent, and information hierarchy when actual frames are accessible.
- Existing frontend is the source of functionality and route coverage.
- Laravel backend/API contracts must be preserved; polish must not alter endpoint paths, auth behavior, role guards, payloads, or error handling.
- Features missing from Figma must be preserved when they already exist in the product and are required by project status.
- Speaking remains AI-assisted initial scoring plus teacher manual review. Do not present it as final authoritative Mekongga phonetic assessment.
- Do not copy code from Figma/Weblify exports. Use Figma only as visual reference.

## 3. Global UI/UX Findings

- **Done/P1: Admin dashboard placeholder was addressed in Batch 4.** `/admin/dashboard` now uses existing summary API data and honest loading/error/empty states. Remaining admin dashboard work is visual/content polish, not the original P0 placeholder issue.
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
- Major UX gaps: dense table/action layouts, modal accessibility, some internal/backend wording, and admin detail page hierarchy. The static admin dashboard P0 was addressed in Batch 4.
- Responsive risks: management tables, filter panels with many columns, modal forms for school/class/user/module/dictionary/knowledge flows.
- Priority polish list: continue admin filter/table/action patterns; align knowledge/dictionary/module/culture forms to design tokens; refine admin detail page hierarchy; preserve all admin-only features absent from Figma.

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

- **Batch 2: Design system global.** Completed foundation pass: normalized tokens, shared components, color/radius/shadow/typography, state components, and shell primitives across auth and role screens without logic changes.
- **Batch 3: Layout shell/sidebar/header.** Completed foundation pass: role shell, responsive mobile menu/bottom nav, topbar/sidebar active states, and stale route status badges.
- **Batch 4: Admin polish.** Dashboard P0 completed; continue with approvals, user/class management, dictionary/import, Basis AI, modules/quizzes, culture, progress/settings.
- **Batch 5: Guru polish.** Dashboard/classes/students, modules/lessons, quizzes/results, culture, profile, speaking review.
- **Batch 6: Siswa polish.** Dashboard, modules/lessons, dictionary/detail, quizzes/attempt/result, culture, progress/profile.
- **Batch 7: AI chatbot + Speaking polish.** Focused chat surface, citations/source display, speaking recorder/status, teacher review layout, accessible audio/status feedback.
- **Batch 8: Responsive QA.** Desktop/tablet/mobile pass across high-risk tables, forms, modals, chatbot, quiz attempt, and speaking.

## 8. Priority Matrix

| Priority | Item | Reason | Recommended Batch |
|---|---|---|---|
| Done | Admin dashboard placeholder/static data | Batch 4 replaced misleading static values with real summary API data and honest states | Done; continue admin polish |
| P1 | Design token inconsistency | Foundation completed in Batch 2; page-level hardcoded styling can still be reduced during role batches | Batch 4/5/6 |
| P1 | Stale navigation `Next` badges | Cleaned for implemented Basis AI/chatbot/speaking features in Batch 3 | Done |
| P1 | Mobile navigation lacks drawer/collapse | Batch 3 added a mobile full menu plus bottom nav foundation | Done; full responsive QA remains Batch 8 |
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

Recommend continuing **Batch 4: Admin screens polish** next, now focused on dense admin table/form/content pages: approvals, user/class management, dictionary/import, Basis AI, modules/quizzes, culture, progress, and settings.

## Baseline Mapping Table (Batch 1 Pre-MCP)

This table is retained as the original frontend-first baseline from Batch 1. For current Figma-informed mapping, use the `Figma MCP Visual Mapping` section above.

| Role | Existing Route/Page | Existing Feature | Figma Frame/Reference | Match Level | Gap | Priority | Notes |
|---|---|---|---|---|---|---|---|
| Public | `/login` | Login/auth redirect | MCP not accessible; legacy docs name `AUTH-01 - Login` | Low | Visual comparison blocked; hardcoded auth styling differs from shared tokens | P1 | Keep Sanctum login and role redirect. |
| Public | `/register`, `/register/teacher`, `/register/student`, `/pending-approval` | Role registration and pending approval | MCP not accessible; legacy docs name `AUTH-02` to `AUTH-05` | Low | Visual comparison blocked; auth screens use separate hardcoded palette | P1 | Preserve public school/class lookup and pending status behavior. |
| Admin | `/admin/dashboard` | Admin landing/dashboard | MCP not accessible; legacy docs name `ADMIN-01 - Beranda Admin` | Medium | Batch 4 replaced static placeholder values with real `/admin/dashboard/summary` data and demo-safe states | Done/P1 | Continue only visual/content refinement later. |
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
