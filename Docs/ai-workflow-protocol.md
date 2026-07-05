# EMI AI Workflow Protocol

## 1. Purpose

This protocol keeps EMI work reusable, safe, and easy to continue across GPT Chat, OpenCode, and future AI sessions.

Workflow model:

```text
GPT Chat = planning, reasoning, prompt writing, evaluation
OpenCode = execution in repository
User = copies GPT prompt into OpenCode, then copies OpenCode final report back to GPT Chat
```

## 2. Roles and Responsibilities

| Role | Responsibility |
|---|---|
| GPT Chat | Understand goals, plan tasks, write precise OpenCode prompts, evaluate final reports, decide next steps. |
| OpenCode | Inspect repository, execute exact task, edit files, verify, update progress, commit only requested files. |
| User | Provides direction, moves prompts/reports between tools, runs manual QA when needed, decides whether to push/deploy. |

## 3. Standard Task Lifecycle

1. User discusses plan with GPT Chat.
2. GPT Chat creates detailed OpenCode prompt.
3. OpenCode reads relevant Docs first.
4. OpenCode runs preflight.
5. OpenCode executes exact task.
6. OpenCode runs verification.
7. OpenCode updates `Docs/progressbar.md` when task changes project status.
8. OpenCode commits with exact files only.
9. User copies OpenCode final report to GPT Chat.
10. GPT Chat evaluates and decides next step.

## 4. Required Preflight

Every OpenCode execution should start at project root:

```cmd
cd /d "D:\!Kerjaan\EMI"
git status --short
```

Allowed generated/noise:

```text
Emi-Frontend/next-env.d.ts
Emi-Frontend/dev_stderr.log
Emi-Frontend/dev_stdout.log
Emi-Speaking-AI/.venv/
Emi-Speaking-AI/__pycache__/
Emi-Speaking-AI/**/*.pyc
```

Cleanup allowed frontend noise only:

```cmd
git restore -- "Emi-Frontend/next-env.d.ts"
if exist "Emi-Frontend\dev_stderr.log" del /q "Emi-Frontend\dev_stderr.log"
if exist "Emi-Frontend\dev_stdout.log" del /q "Emi-Frontend\dev_stdout.log"
```

Rules:

- Stop if unrelated dirty source files exist.
- Do not delete `.venv`.
- Do not touch `D:\!Kerjaan\EMI2`.

## 5. Required Docs Reading

Before coding, read:

- `Docs/progressbar.md`
- `Docs/current-project-handover.md`
- `Docs/ai-workflow-protocol.md`
- any domain-specific docs related to the task

Examples:

- Speaking task → also read `Docs/speaking-ai-integration.md`.
- Mobile/API task → also read `Docs/backend-api-mobile-readiness-handover.md` and `Docs/api-v1-route-inventory.md`.
- Basis AI task → read relevant Basis AI docs and inspect services/routes/tests.
- Documentation task → inspect current docs and source code before writing.

## 6. Prompt Requirements

A good OpenCode prompt should include:

- Project root and component paths.
- Exact task scope.
- Files/docs to read first.
- Files or directories not to touch.
- Expected behavior.
- Verification commands.
- Git hygiene rules.
- Whether commit is requested.
- Final report format.

For phase-scoped tasks, mention the exact phase and do not ask OpenCode to continue beyond it.

## 7. Execution Rules

OpenCode must:

- Work only in `D:\!Kerjaan\EMI` unless user explicitly says otherwise.
- Execute only the requested task.
- Avoid product feature changes during documentation-only tasks.
- Avoid schema changes unless explicitly requested.
- Follow existing Laravel/Next/Python patterns.
- Keep controllers thin and business logic in services for Laravel work.
- Keep frontend calls routed through Laravel API.
- Keep Python Speaking AI internal.
- Never use `git add .`.
- Never use `git clean`.
- Never push, merge, tag, switch branch, or add remotes unless explicitly asked.

## 8. Verification Rules

Verification depends on scope.

Backend work usually requires:

```cmd
cd /d "D:\!Kerjaan\EMI\Emi-Backend"
php artisan test
composer audit
```

Backend formatting may require:

```cmd
vendor/bin/pint
```

Frontend work usually requires:

```cmd
cd /d "D:\!Kerjaan\EMI\Emi-Frontend"
npm.cmd run lint
npm.cmd run build
```

API documentation or route-sensitive work should run:

```cmd
cd /d "D:\!Kerjaan\EMI\Emi-Backend"
php artisan route:list --path=api/v1
```

Documentation-only tasks do not require frontend build unless frontend files changed. Always run:

```cmd
cd /d "D:\!Kerjaan\EMI"
git diff --check
```

Known composer audit advisories may remain for:

- `guzzlehttp/guzzle`
- `guzzlehttp/psr7`

Report them only unless user asks to modify dependencies.

## 9. Progressbar Update Rules

Use `Docs/progressbar.md` as the current project todo source of truth.

Rules:

- If a task completes an item, change `[ ]` to `[x]`.
- If a task partially completes an item, keep `[ ]` and add a short note.
- If a task discovers a new bug, add it under the appropriate section.
- If a task changes project status, update `progressbar.md` in the same commit when safe.
- Do not mark manual QA as done unless manual QA was actually performed.
- Do not mark deployment as done unless deployed and verified.
- Keep completed log entries intact.

## 10. Final Report Format

Use this reusable final report template:

```text
1. cleanup result
2. docs read
3. files changed
4. root cause / task summary
5. implementation summary
6. progressbar updates
7. verification result
8. manual QA status
9. known issues
10. final git status
11. commit hash
12. recommended next step
```

For documentation-only tasks, replace implementation summary with documentation summary.

## 11. Handling Changed Requirements

If user request differs from current progressbar todo:

- Do not force old todo blindly.
- Follow the user's latest explicit request.
- Update the related todo wording/status.
- Mention the change in final report.
- Keep historical completed log intact.

If user request conflicts with safe rules, stop and ask for clarification or offer a safe alternative.

## 12. Handling Dirty Git State

If preflight shows dirty files:

1. Identify whether they are allowed noise.
2. Clean only explicitly allowed frontend noise.
3. Do not delete `.venv` or Python cache by broad cleanup.
4. Stop if unrelated source/docs files are dirty.
5. Report the dirty files and ask user how to proceed.

Allowed noise does not include arbitrary source code changes.

## 13. Handling Manual QA

Manual QA must be treated separately from automated tests.

Rules:

- Do not mark manual QA done unless the user/executor actually performed it.
- If manual QA is requested but cannot be run, document it as not run.
- If manual QA discovers a bug, add it to `Docs/progressbar.md` under Known Bugs / QA Issues.
- For speaking QA, use the full stack: Python service, Laravel backend, queue worker, Next frontend, student login, teacher login.

## 14. Security and Secrets Rules

Never include or commit:

- Real `.env` values.
- API keys.
- DB passwords.
- Gemini keys.
- Tokens.
- Private credentials.
- Production secrets.

Use placeholders only.

Demo account credentials may be documented only if they are project demo credentials already present in seeders/docs.

Security defaults:

- Laravel validates authorization and scope.
- Mobile/web clients must not decide permissions.
- Python Speaking AI must remain private/internal.
- Speaking recordings stay private media.
- Do not store raw audio binary in DB.

## 15. Mobile Planning Rules

Mobile planning must follow these rules:

- Use Laravel `/api/v1` as the backend.
- Do not propose a separate mobile backend unless a specific future requirement justifies it.
- Build student-first unless user changes priority.
- Store Sanctum tokens securely on device.
- Reuse existing API response/error patterns.
- Implement speaking mobile only after web speaking manual QA is stable.
- Mobile must call Laravel only, never Python Speaking AI directly.
- Keep offline sync as a later enhancement unless user explicitly prioritizes it.
