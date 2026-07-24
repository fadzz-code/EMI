import { expect, test } from "@playwright/test";

import { adminData, openAdmin, rowWith } from "./helpers";

test("admin membaca pengguna dan mengelola sekolah serta kelas", async ({ page }) => {
  test.setTimeout(60_000);
  const school = adminData("Sekolah");
  const schoolUpdated = `${school} Diubah`;
  const schoolSearch = school.split(" ").at(-1) ?? school;
  await openAdmin(page, "/admin/users", "Data Guru & Siswa");
  await page.getByRole("button", { name: "Daftar Siswa" }).click();
  await expect(page.getByRole("heading", { name: "Daftar Siswa" })).toBeVisible();
  await page.getByRole("button", { name: "Daftar Guru" }).click();
  const detail = page.getByRole("link", { name: "Detail/Edit" }).first();
  if (await detail.count()) {
    await detail.click();
    await expect(page).toHaveURL(/\/admin\/users\//);
  }

  await openAdmin(page, "/admin/schools-classes", "Sekolah & Kelas");
  await page.getByRole("button", { name: "Tambah Sekolah" }).click();
  await page.getByLabel("Nama sekolah").fill(school);
  await page.getByLabel("Alamat").fill("Alamat E2E Admin");
  await page.getByRole("button", { name: "Simpan Sekolah" }).click();
  await expect(page.getByText(`Sekolah ${school} berhasil dibuat.`)).toBeVisible();

  try {
    await page.reload();
    await page.getByLabel("Cari sekolah").fill(schoolSearch);
    await page.getByRole("button", { name: "Terapkan" }).click();
    await expect(page.getByText(school, { exact: true })).toBeVisible();
    const schoolRow = rowWith(page, school);
    await schoolRow.getByRole("button", { name: "Edit" }).click();
    await page.getByLabel("Nama sekolah").fill(schoolUpdated);
    await page.getByRole("button", { name: "Simpan Sekolah" }).click();
    await expect(page.getByText(`Sekolah ${schoolUpdated} berhasil diperbarui.`)).toBeVisible();
    await page.getByRole("button", { name: "Kelas", exact: true }).click();
    await expect(page.getByRole("heading", { name: "Daftar Kelas" })).toBeVisible();
    await page.reload();
    await page.getByRole("button", { name: "Sekolah", exact: true }).click();
    await page.getByLabel("Cari sekolah").fill(schoolSearch);
    await page.getByRole("button", { name: "Terapkan" }).click();
    await expect(page.getByText(schoolUpdated, { exact: true })).toBeVisible();
  } finally {
    if (!page.url().includes("schools-classes")) await page.goto("/admin/schools-classes");
    await page.getByRole("button", { name: "Sekolah", exact: true }).click();
    await page.getByLabel("Cari sekolah").fill(schoolSearch);
    await page.getByRole("button", { name: "Terapkan" }).click();
    const schoolRow = rowWith(page, schoolUpdated).or(rowWith(page, school)).first();
    if (await schoolRow.count()) await schoolRow.getByRole("button", { name: "Nonaktifkan" }).click();
  }
});
