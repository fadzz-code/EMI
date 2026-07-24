import { expect, type Page } from "@playwright/test";

export type RoleCredentials = {
  email: string;
  password: string;
};

export const roleDashboards = {
  admin: {
    path: "/admin/dashboard",
    marker: "Beranda Admin",
  },
  teacher: {
    path: "/teacher/dashboard",
    marker: "Beranda Guru",
  },
  student: {
    path: "/student/dashboard",
    marker: "Beranda Belajar",
  },
} as const;

export type Role = keyof typeof roleDashboards;

export function credentials(role: Role): RoleCredentials {
  const prefix = role === "teacher" ? "TEACHER" : role.toUpperCase();
  const email = process.env[`E2E_${prefix}_EMAIL`];
  const password = process.env[`E2E_${prefix}_PASSWORD`];

  if (!email || !password) {
    throw new Error(`Kredensial E2E ${role} belum diatur. Isi E2E_${prefix}_EMAIL dan E2E_${prefix}_PASSWORD.`);
  }

  return { email, password };
}

export async function loginThroughUi(page: Page, role: Role, account = credentials(role)) {
  const dashboard = roleDashboards[role];

  await page.goto("/login");
  await expect(page.getByRole("heading", { name: "Selamat Datang di EMI" })).toBeVisible();
  await page.getByLabel("Email").fill(account.email);
  await page.getByLabel("Kata Sandi").fill(account.password);
  await page.getByRole("button", { name: "Masuk →" }).click();

  try {
    await expect(page).toHaveURL(new RegExp(`${dashboard.path.replaceAll("/", "\\/")}$`));
    await expect(page.getByText(dashboard.marker, { exact: true })).toBeVisible();
  } catch (error) {
    const alert = page.getByRole("alert");
    const detail = await alert.isVisible().then((visible) => visible ? alert.textContent() : null).catch(() => null);
    throw new Error(`Login ${role} gagal${detail ? `: ${detail}` : ". Dashboard role tidak tampil."}`, { cause: error });
  }
}
