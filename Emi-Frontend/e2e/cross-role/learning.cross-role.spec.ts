import { readFileSync } from "node:fs";

import { expect, test } from "@playwright/test";

import { api, apiBase, classFixture, rolePage, token, unique } from "./helpers";

test("[E2E Cross Role] learning lifecycle reaches student progress and teacher/admin reports", async ({ browser, request }) => {
  test.setTimeout(90_000);
  const teacher = await rolePage(browser, "teacher");
  const student = await rolePage(browser, "student");
  const admin = await rolePage(browser, "admin");
  const teacherAuth = await token(teacher.page, "teacher");
  const adminAuth = await token(admin.page, "admin");
  const { studentToken, classroom } = await classFixture(request, student.page);
  const title = unique("Learning");
  const lessonTitle = unique("Lesson");
  let moduleId: string | undefined;
  let lessonId: string | undefined;

  try {
    const madeModule = await api<{ id: string }>(request, `/classes/${classroom.id}/modules`, teacherAuth, { method: "POST", data: { title, description: "Cross-role learning gate" } });
    expect(madeModule.response.status()).toBe(201);
    moduleId = madeModule.data!.id;

    const mediaResponse = await request.post(`${apiBase}/media`, { headers: { Authorization: `Bearer ${teacherAuth}`, Accept: "application/json" }, multipart: { purpose: "document", visibility: "private", file: { name: "tiny.pdf", mimeType: "application/pdf", buffer: readFileSync("e2e/fixtures/tiny.pdf") } } });
    expect(mediaResponse.status()).toBe(201);
    const media = await mediaResponse.json() as { data: { id: string } };
    const lesson = await api<{ id: string }>(request, `/class-modules/${moduleId}/lessons`, teacherAuth, { method: "POST", data: { title: lessonTitle, description: "PDF fixture", content_type: "pdf", media_id: media.data.id, sort_order: 1 } });
    expect(lesson.response.status()).toBe(201);
    lessonId = lesson.data!.id;
    expect((await api(request, `/class-lessons/${lessonId}/publish`, teacherAuth, { method: "POST" })).response.ok()).toBeTruthy();
    await teacher.page.goto(`/teacher/modules/${moduleId}/edit`);
    await expect(teacher.page.getByLabel("Judul modul")).toHaveValue(title);
    teacher.page.once("dialog", (dialog) => dialog.accept());
    const published = teacher.page.waitForResponse((response) => response.url().includes(`/class-modules/${moduleId}/publish`) && response.request().method() === "POST");
    await teacher.page.getByRole("button", { name: "Terbitkan Modul" }).click();
    expect((await published).ok()).toBeTruthy();

    await student.page.goto(`/student/modules/${moduleId}`);
    await expect(student.page.getByRole("heading", { name: title })).toBeVisible();
    await student.page.goto(`/student/lessons/${lessonId}`);
    await student.page.getByRole("button", { name: "Tandai Selesai" }).click();
    await expect(student.page.getByText("Materi ditandai selesai.")).toBeVisible();
    expect(JSON.stringify((await api(request, "/student/reports/progress", studentToken)).data)).toContain(moduleId);

    await teacher.page.goto("/teacher/reports/progress");
    await expect(teacher.page.getByText(classroom.name, { exact: true }).first()).toBeVisible();
    await admin.page.goto("/admin/progress");
    await expect(admin.page.getByRole("heading", { name: "Progress Siswa", exact: true })).toBeVisible();
    expect((await api(request, `/admin/reports/progress/students?class_id=${classroom.id}`, adminAuth)).response.ok()).toBeTruthy();
  } finally {
    if (lessonId) await api(request, `/class-lessons/${lessonId}/archive`, teacherAuth, { method: "POST" });
    if (moduleId) await api(request, `/class-modules/${moduleId}/archive`, teacherAuth, { method: "POST" });
    await Promise.all([teacher.context.close(), student.context.close(), admin.context.close()]);
  }
});
