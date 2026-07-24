import { expect, test } from "@playwright/test";

import { api, assignedClass, foreignClass, teacherToken } from "./helpers";

test.use({ storageState: "playwright/.auth/teacher.json" });

test("guru ditolak dari halaman admin dengan halaman ramah", async ({ page }) => {
  await page.goto("/admin/dashboard");
  await expect(page).not.toHaveURL(/\/admin\/dashboard$/);
  await expect(page.getByText(/tidak memiliki izin|Beranda Guru/i).first()).toBeVisible();
});

test("guru ditolak lintas domain kelas asing yang ditemukan lewat admin", async ({ page, request, browser }) => {
  const ownClass = await assignedClass(page);
  const token = await teacherToken(page);
  expect(token).toBeTruthy();
  const discovered = await foreignClass(request, browser, ownClass.id);
  let foreign = discovered.teacherClass;
  const adminToken = discovered.adminToken;
  let disposableClassId: string | undefined;
  if (!foreign) {
    const ownDetail = await api<{ school?: { id: string } }>(request, `/classes/${ownClass.id}`, adminToken);
    const created = await api<{ id: string; name: string }>(request, "/classes", adminToken, {
      method: "POST",
      data: {
        school_id: ownDetail.data?.school?.id,
        name: `[E2E Guru] Kelas Asing ${Date.now()}`,
        grade_level: "99",
        academic_year: "2099/2100",
        status: "active",
      },
    });
    expect(created.response.ok()).toBeTruthy();
    foreign = created.data;
    disposableClassId = foreign?.id;
  }
  expect(foreign).toBeTruthy();

  try {
  const foreignModules = await api<{ id: string }[]>(request, `/classes/${foreign!.id}/modules?per_page=100`, adminToken);
  const foreignQuizzes = await api<{ id: string }[]>(request, `/class-quizzes?class_id=${foreign!.id}&per_page=100`, adminToken);
  const foreignCulture = await api<{ id: string }[]>(request, `/classes/${foreign!.id}/culture?per_page=100`, adminToken);
  const foreignSpeaking = await api<{ id: string }[]>(request, `/teacher/speaking/exercises?classroom_id=${foreign!.id}&per_page=100`, adminToken);

  const scopedQuizzes = await api<{ id: string; class_id?: string }[]>(request, `/class-quizzes?class_id=${foreign!.id}`, token!);
  expect(scopedQuizzes.response.status()).toBe(200);
  expect(scopedQuizzes.data?.every((quiz) => quiz.class_id !== foreign!.id)).toBeTruthy();

  const probes = [
    `/classes/${foreign!.id}`,
    `/classes/${foreign!.id}/students`,
    `/classes/${foreign!.id}/modules`,
    `/classes/${foreign!.id}/culture`,
    `/teacher/reports/progress/students?class_id=${foreign!.id}`,
    ...(foreignModules.data?.[0] ? [`/class-modules/${foreignModules.data[0].id}`] : []),
    ...(foreignQuizzes.data?.[0] ? [`/class-quizzes/${foreignQuizzes.data[0].id}`] : []),
    ...(foreignCulture.data?.[0] ? [`/class-culture-items/${foreignCulture.data[0].id}`] : []),
    ...(foreignSpeaking.data?.[0] ? [`/teacher/speaking/exercises/${foreignSpeaking.data[0].id}`] : []),
  ];

  for (const endpoint of probes) {
    const result = await api(request, endpoint, token!);
    expect([403, 404], `${endpoint} harus menolak guru asing`).toContain(result.response.status());
  }

  const responsePromise = page.waitForResponse((response) => response.url().includes(`/api/v1/classes/${foreign!.id}`));
  await page.goto(`/teacher/classes/${foreign!.id}`);
  expect([403, 404]).toContain((await responsePromise).status());
  await expect(page.getByText(/tidak memiliki izin|tidak tersedia|tidak ditemukan|unauthorized/i).first()).toBeVisible();
  } finally {
    if (disposableClassId) {
      const deleted = await api(request, `/classes/${disposableClassId}`, adminToken, { method: "DELETE" });
      expect([200, 204]).toContain(deleted.response.status());
    }
  }
});
