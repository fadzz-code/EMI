import { expect, test } from "@playwright/test";

import { roleDashboards } from "../../playwright/helpers/auth";

test("Siswa masuk dashboard yang benar", async ({ page }) => {
  await page.goto(roleDashboards.student.path);

  await expect(page).toHaveURL(new RegExp(`${roleDashboards.student.path}$`));
  await expect(page.getByText(roleDashboards.student.marker, { exact: true })).toBeVisible();
  await expect(page.getByRole("link", { name: "Modul Belajar" })).toBeVisible();
});
