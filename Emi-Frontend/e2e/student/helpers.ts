import { readFileSync } from "node:fs";

import { expect, test, type APIRequestContext, type Browser, type Page } from "@playwright/test";

test.use({ storageState: "playwright/.auth/student.json" });

type Envelope<T> = { data?: T };
export type StudentClass = { id: string; name: string };

const apiBase = process.env.E2E_API_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://127.0.0.1:8000/api/v1";

export async function token(page: Page) {
  await page.goto("/student/dashboard");
  const value = await page.evaluate(() => localStorage.getItem("emi.auth.token"));
  expect(value, "Student storage state must contain token").toBeTruthy();
  return value!;
}

export async function roleToken(browser: Browser, role: "admin" | "teacher") {
  const context = await browser.newContext({ storageState: `playwright/.auth/${role}.json` });
  const page = await context.newPage();
  await page.goto(`/${role}/dashboard`);
  const value = await page.evaluate(() => localStorage.getItem("emi.auth.token"));
  await context.close();
  expect(value, `${role} storage state must contain token`).toBeTruthy();
  return value!;
}

export async function api<T>(request: APIRequestContext, path: string, auth: string, options: { method?: string; data?: unknown } = {}) {
  const response = await request.fetch(`${apiBase}${path}`, {
    method: options.method ?? "GET",
    data: options.data,
    headers: { Authorization: `Bearer ${auth}`, Accept: "application/json" },
  });
  const body = await response.json().catch(() => ({})) as Envelope<T>;
  return { response, data: body.data };
}

export async function studentClass(page: Page, request: APIRequestContext) {
  const auth = await token(page);
  const me = await api<{ active_class?: StudentClass }>(request, "/auth/me", auth);
  expect(me.response.ok()).toBeTruthy();
  expect(me.data?.active_class, "E2E student must have active class").toBeTruthy();
  return { auth, studentClass: me.data!.active_class! };
}

export async function createSpeakingExercise(request: APIRequestContext, browser: Browser, classId: string) {
  const teacherAuth = await roleToken(browser, "teacher");
  const title = unique("Speaking");
  const created = await api<{ id: string }>(request, "/teacher/speaking/exercises", teacherAuth, {
    method: "POST",
    data: { classroom_id: classId, title, target_text: "Mekongga E2E", prompt_text: "Baca target", language_code: "mek", difficulty: "beginner", status: "published" },
  });
  expect(created.response.status()).toBe(201);
  return { exerciseId: created.data!.id, teacherAuth, title };
}

export async function archiveSpeakingExercise(request: APIRequestContext, exerciseId: string, teacherAuth: string) {
  const archived = await api(request, `/teacher/speaking/exercises/${exerciseId}/archive`, teacherAuth, { method: "PATCH" });
  expect(archived.response.ok()).toBeTruthy();
}

export const wavFixture = () => readFileSync("e2e/fixtures/silence.pcm.wav");
export const unique = (domain: string) => `[E2E Student] ${domain} ${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
