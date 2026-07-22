import { expect, test } from "@playwright/test";

import { roleDashboards, type Role } from "../../playwright/helpers/auth";

const roles: Role[] = ["admin", "teacher", "student"];

test("setiap sesi tersimpan menuju dashboard role yang benar", async ({ browser }) => {
  for (const role of roles) {
    const context = await browser.newContext({ storageState: `playwright/.auth/${role}.json` });
    const page = await context.newPage();
    const dashboard = roleDashboards[role];

    await page.goto(dashboard.path);
    await expect(page).toHaveURL(new RegExp(`${dashboard.path}$`));
    await expect(page.getByText(dashboard.marker, { exact: true })).toBeVisible();
    await context.close();
  }
});

test("logout menghapus sesi dan route terproteksi kembali ke login", async ({ browser }) => {
  const context = await browser.newContext({ storageState: "playwright/.auth/student.json" });
  const page = await context.newPage();

  await page.goto(roleDashboards.student.path);
  await expect(page.getByText(roleDashboards.student.marker, { exact: true })).toBeVisible();
  await page.getByRole("button", { name: "Keluar dari EMI" }).click();
  await expect(page).toHaveURL(/\/login$/);
  await expect.poll(() => page.evaluate(() => localStorage.getItem("emi.auth.token"))).toBeNull();

  await page.goto(roleDashboards.student.path);
  await expect(page).toHaveURL(/\/login$/);
  await context.close();
});
