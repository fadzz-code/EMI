import { expect, type Locator, type Page } from "@playwright/test";

export const adminData = (domain: string) => `[E2E Admin] ${domain} ${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

export async function openAdmin(page: Page, path: string, heading: string) {
  await page.goto(path);
  await expect(page).toHaveURL(new RegExp(`${path.replaceAll("/", "\\/")}$`));
  await expect(page.getByRole("heading", { name: heading, exact: true })).toBeVisible();
}

export async function reloadAndExpect(page: Page, text: string) {
  await page.reload();
  await expect(page.getByText(text, { exact: true }).first()).toBeVisible();
}

export function rowWith(page: Page, text: string): Locator {
  return page.getByRole("row").filter({ hasText: text });
}

export function cardWith(page: Page, text: string): Locator {
  return page.locator("article, [class*='rounded']").filter({ hasText: text }).last();
}
