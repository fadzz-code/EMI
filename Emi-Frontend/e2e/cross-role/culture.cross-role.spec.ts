import { expect, test } from "@playwright/test";

import { api, card, classFixture, rolePage, token, unique } from "./helpers";

test("[E2E Cross Role] global culture appears across roles and removal spares unrelated global content", async ({ browser, request }) => {
  const admin = await rolePage(browser, "admin");
  const teacher = await rolePage(browser, "teacher");
  const student = await rolePage(browser, "student");
  const adminAuth = await token(admin.page, "admin");
  const { classroom } = await classFixture(request, student.page);
  const title = unique("Culture");
  const sentinel = unique("Culture sentinel");
  let createdId: string | undefined;
  let sentinelId: string | undefined;

  try {
    const sentinelCreated = await api<{ id: string }>(request, "/admin/culture/items", adminAuth, { method: "POST", data: { title: sentinel, description: "Collateral sentinel", content_type: "link", external_url: "https://example.com/" } });
    expect(sentinelCreated.response.status()).toBe(201);
    sentinelId = sentinelCreated.data!.id;

    await admin.page.goto("/admin/culture/templates");
    await admin.page.getByRole("button", { name: "Tambah Konten Budaya" }).click();
    await admin.page.getByLabel("Judul").fill(title);
    await admin.page.getByLabel("Deskripsi").fill("Cross-role global culture");
    await admin.page.getByLabel("Tipe konten").selectOption("link");
    await admin.page.getByLabel("URL").fill("https://example.com/");
    const created = admin.page.waitForResponse((response) => response.request().method() === "POST" && response.url().includes("culture"));
    await admin.page.getByRole("button", { name: "Simpan Konten" }).click();
    createdId = (await (await created).json() as { data: { id: string } }).data.id;
    await card(admin.page, title).getByRole("button", { name: "Terbitkan" }).click();

    await teacher.page.goto("/teacher/culture");
    await expect(teacher.page.getByText(title, { exact: true })).toBeVisible();
    await student.page.goto("/student/culture");
    await expect(student.page.getByText(title, { exact: true })).toBeVisible();

    await api(request, `/admin/culture/items/${createdId}`, adminAuth, { method: "DELETE" });
    createdId = undefined;
    await teacher.page.reload();
    await expect(teacher.page.getByText(title, { exact: true })).toHaveCount(0);
    expect((await api(request, `/admin/culture/items/${sentinelId}`, adminAuth)).response.ok()).toBeTruthy();
    expect(classroom.id).toBeTruthy();
  } finally {
    if (createdId) await api(request, `/admin/culture/templates/${createdId}`, adminAuth, { method: "DELETE" });
    if (sentinelId) await api(request, `/admin/culture/items/${sentinelId}`, adminAuth, { method: "DELETE" });
    await Promise.all([admin.context.close(), teacher.context.close(), student.context.close()]);
  }
});
