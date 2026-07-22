import { expect, test } from "@playwright/test";

import { roleDashboards } from "../../playwright/helpers/auth";

test("Guru masuk dashboard yang benar", async ({ page }) => {
  await page.goto(roleDashboards.teacher.path);

  await expect(page).toHaveURL(new RegExp(`${roleDashboards.teacher.path}$`));
  await expect(page.getByText(roleDashboards.teacher.marker, { exact: true })).toBeVisible();
  await expect(page.getByRole("link", { name: "Kelas" })).toBeVisible();
});
