import { expect, test } from "@playwright/test";

import { roleDashboards } from "../../playwright/helpers/auth";

test("Admin masuk dashboard yang benar", async ({ page }) => {
  await page.goto(roleDashboards.admin.path);

  await expect(page).toHaveURL(new RegExp(`${roleDashboards.admin.path}$`));
  await expect(page.getByText(roleDashboards.admin.marker, { exact: true })).toBeVisible();
  await expect(page.getByRole("link", { name: "Pengaturan" })).toBeVisible();
});
