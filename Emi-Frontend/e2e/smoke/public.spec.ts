import { expect, test } from "@playwright/test";

test("halaman login dapat dibuka", async ({ page }) => {
  await page.goto("/login");

  await expect(page.getByRole("heading", { name: "Selamat Datang di EMI" })).toBeVisible();
  await expect(page.getByLabel("Email")).toBeVisible();
  await expect(page.getByLabel("Kata Sandi")).toBeVisible();
  await expect(page.getByRole("button", { name: "Masuk →" })).toBeVisible();
});

test("guest diarahkan dari route terproteksi ke login", async ({ page }) => {
  await page.goto("/student/dashboard");

  await expect(page).toHaveURL(/\/login$/);
  await expect(page.getByRole("heading", { name: "Selamat Datang di EMI" })).toBeVisible();
});
