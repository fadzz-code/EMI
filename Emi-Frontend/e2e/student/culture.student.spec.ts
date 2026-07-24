import { expect, test } from "@playwright/test";

import { api, roleToken, studentClass, unique } from "./helpers";

test.use({ storageState: "playwright/.auth/student.json" });

test("culture shows published own-class media and excludes foreign-class content", async ({ page, request, browser }) => {
  const { studentClass: ownClass } = await studentClass(page, request);
  const teacherAuth = await roleToken(browser, "teacher");
  const ownTitle = unique("Culture own");
  const own = await api<{ id: string }>(request, `/classes/${ownClass.id}/culture`, teacherAuth, { method: "POST", data: { title: ownTitle, description: "Own class culture", content_type: "link", external_url: "https://example.com/" } });
  test.skip(!own.response.ok(), "Teacher E2E account cannot build culture for student class");
  try {
    expect((await api(request, `/class-culture-items/${own.data!.id}/publish`, teacherAuth, { method: "POST" })).response.ok()).toBeTruthy();
    const classes = await api<Array<{ id: string }>>(request, "/classes?per_page=100", teacherAuth);
    const foreign = classes.data?.find((item) => item.id !== ownClass.id);
    let foreignId: string | undefined;
    let foreignTitle: string | undefined;
    if (foreign) {
      foreignTitle = unique("Culture foreign");
      const made = await api<{ id: string }>(request, `/classes/${foreign.id}/culture`, teacherAuth, { method: "POST", data: { title: foreignTitle, description: "Foreign", content_type: "link", external_url: "https://example.com/" } });
      if (made.response.ok()) {
        foreignId = made.data!.id;
        await api(request, `/class-culture-items/${foreignId}/publish`, teacherAuth, { method: "POST" });
      }
    }
    await page.goto("/student/culture");
    await expect(page.getByText(ownTitle, { exact: true })).toBeVisible();
    await expect(page.getByText("Own class culture", { exact: true })).toBeVisible();
    if (foreignTitle) await expect(page.getByText(foreignTitle, { exact: true })).toHaveCount(0);
    if (foreignId) await api(request, `/class-culture-items/${foreignId}`, teacherAuth, { method: "DELETE" });
  } finally {
    await api(request, `/class-culture-items/${own.data!.id}`, teacherAuth, { method: "DELETE" });
  }
});
