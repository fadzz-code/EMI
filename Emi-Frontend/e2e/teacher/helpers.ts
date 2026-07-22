import { expect, test, type APIRequestContext, type Browser, type Page } from "@playwright/test";

test.use({ storageState: "playwright/.auth/teacher.json" });

export const teacherData = (domain: string) => `[E2E Guru] ${domain} ${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

type ApiEnvelope<T> = { data?: T };
export type TeacherClass = { id: string; name: string; school?: { id?: string } };

export async function teacherToken(page: Page) {
  return page.evaluate(() => localStorage.getItem("emi.auth.token"));
}

export async function api<T>(request: APIRequestContext, url: string, token: string, options: { method?: string; data?: unknown } = {}) {
  const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000/api/v1";
  const response = await request.fetch(`${apiBaseUrl}${url}`, {
    method: options.method ?? "GET",
    data: options.data,
    headers: { Authorization: `Bearer ${token}`, Accept: "application/json" },
  });
  const body = await response.json() as ApiEnvelope<T>;
  return { response, data: body.data };
}

export async function adminToken(browser: Browser) {
  const context = await browser.newContext({ storageState: "playwright/.auth/admin.json" });
  const page = await context.newPage();
  await page.goto("/admin/dashboard");
  const token = await teacherToken(page);
  await context.close();
  expect(token, "Storage state admin harus memuat token").toBeTruthy();
  return token!;
}

export async function foreignClass(request: APIRequestContext, browser: Browser, ownClassId: string) {
  const token = await adminToken(browser);
  const result = await api<TeacherClass[]>(request, "/classes?per_page=100", token);
  expect(result.response.ok()).toBeTruthy();
  const teacherClass = result.data?.find((item) => item.id !== ownClassId);
  return { teacherClass, adminToken: token };
}

export async function assignedClass(page: Page): Promise<TeacherClass> {
  const responsePromise = page.waitForResponse((response) => response.url().includes("/api/v1/classes?") && response.request().method() === "GET");
  await page.goto("/teacher/classes");
  const response = await responsePromise;
  expect(response.ok()).toBeTruthy();
  const body = await response.json() as ApiEnvelope<TeacherClass[]>;
  const teacherClass = body.data?.[0];
  expect(teacherClass, "Guru E2E harus memiliki assignment kelas aktif").toBeTruthy();
  return teacherClass!;
}

export function cardWith(page: Page, text: string) {
  return page.locator("article, [class*='rounded']").filter({ hasText: text }).last();
}
