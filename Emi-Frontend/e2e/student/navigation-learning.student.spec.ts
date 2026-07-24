import { expect, test } from "@playwright/test";

import { readFileSync } from "node:fs";

import { api, roleToken, studentClass, unique } from "./helpers";

test.use({ storageState: "playwright/.auth/student.json" });

test("navigation, profile, and network retry use authenticated student data", async ({ page, browser }) => {
  await page.goto("/student/dashboard");
  await expect(page.getByRole("heading", { name: /Selamat datang/i })).toBeVisible();

  for (const [path, heading] of [["modules", /Modul/], ["quizzes", /Kuis/], ["culture", /Budaya/], ["progress", "Progress Belajar"], ["profile", "Profil Saya"]] as const) {
    await page.goto(`/student/${path}`);
    await expect(page.getByRole("heading", { name: heading }).first()).toBeVisible();
  }

  await expect(page.getByText("Nama", { exact: true })).toBeVisible();
  await expect(page.getByText("Email", { exact: true })).toBeVisible();
  await expect(page.getByText("Kelas & Sekolah", { exact: true })).toBeVisible();

  const retryContext = await browser.newContext({ storageState: "playwright/.auth/student.json" });
  const retryPage = await retryContext.newPage();
  let blocked = true;
  await retryPage.route("**/student/modules**", async (route) => {
    if (!["fetch", "xhr"].includes(route.request().resourceType())) return route.continue();
    if (blocked) await route.fulfill({ status: 503, contentType: "application/json", body: JSON.stringify({ message: "E2E transient failure" }) });
    else await route.continue();
  });
  await retryPage.goto("/student/modules");
  await expect(retryPage.getByText("Gagal memuat modul")).toBeVisible({ timeout: 20_000 });
  blocked = false;
  await retryPage.getByRole("button", { name: /Coba lagi/i }).click();
  await expect(retryPage.getByText("Gagal memuat modul")).toHaveCount(0);
  await retryContext.close();
});

test("published modules expose PDF lesson and progress persists", async ({ page, request, browser }) => {
  const { auth, studentClass: ownClass } = await studentClass(page, request);
  const teacherAuth = await roleToken(browser, "teacher");
  const moduleTitle = unique("Module");
  const lessonTitle = unique("PDF lesson");
  const mediaResponse = await request.post(`${process.env.E2E_API_URL ?? "http://127.0.0.1:8000/api/v1"}/media`, {
    headers: { Authorization: `Bearer ${teacherAuth}`, Accept: "application/json" },
    multipart: { purpose: "document", visibility: "private", file: { name: "tiny.pdf", mimeType: "application/pdf", buffer: readFileSync("e2e/fixtures/tiny.pdf") } },
  });
  expect(mediaResponse.status()).toBe(201);
  const media = await mediaResponse.json() as { data: { id: string } };
  const madeModule = await api<{ id: string }>(request, `/classes/${ownClass.id}/modules`, teacherAuth, { method: "POST", data: { title: moduleTitle, description: "Disposable module" } });
  expect(madeModule.response.status()).toBe(201);
  const moduleId = madeModule.data!.id;
  const madeLesson = await api<{ id: string }>(request, `/class-modules/${moduleId}/lessons`, teacherAuth, { method: "POST", data: { title: lessonTitle, description: "PDF fixture", content_type: "pdf", media_id: media.data.id, sort_order: 1 } });
  expect(madeLesson.response.status()).toBe(201);
  const lessonId = madeLesson.data!.id;

  try {
    expect((await api(request, `/class-lessons/${lessonId}/publish`, teacherAuth, { method: "POST" })).response.ok()).toBeTruthy();
    expect((await api(request, `/class-modules/${moduleId}/publish`, teacherAuth, { method: "POST" })).response.ok()).toBeTruthy();
    await page.goto(`/student/modules/${moduleId}`);
    await expect(page.getByRole("heading", { name: moduleTitle })).toBeVisible();
    await page.goto(`/student/lessons/${lessonId}`);
    await expect(page.getByRole("heading", { name: lessonTitle })).toBeVisible();
    await expect(page.getByRole("link", { name: "Buka PDF" })).toBeVisible();
    await page.getByRole("button", { name: "Tandai Selesai" }).click();
    await expect(page.getByText("Materi ditandai selesai.")).toBeVisible();
    await page.reload();
    const progress = await api(request, "/student/reports/progress", auth);
    expect(JSON.stringify(progress.data)).toContain(moduleId);
    expect(JSON.stringify(progress.data)).toContain("completed");
  } finally {
    expect((await api(request, `/class-lessons/${lessonId}/archive`, teacherAuth, { method: "POST" })).response.ok()).toBeTruthy();
    expect((await api(request, `/class-modules/${moduleId}/archive`, teacherAuth, { method: "POST" })).response.ok()).toBeTruthy();
  }
});
