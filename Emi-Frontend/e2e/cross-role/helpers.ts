import { expect, type APIRequestContext, type Browser, type Page } from "@playwright/test";

type Envelope<T> = { data?: T };

export const apiBase = process.env.E2E_API_URL ?? process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://127.0.0.1:8000/api/v1";
export const unique = (domain: string) => `[E2E Cross Role] ${domain} ${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;

export async function rolePage(browser: Browser, role: "admin" | "teacher" | "student") {
  const context = await browser.newContext({ storageState: `playwright/.auth/${role}.json` });
  const page = await context.newPage();
  return { context, page };
}

export async function token(page: Page, role: "admin" | "teacher" | "student") {
  await page.goto(`/${role}/dashboard`);
  const auth = await page.evaluate(() => localStorage.getItem("emi.auth.token"));
  expect(auth, `${role} auth token`).toBeTruthy();
  return auth!;
}

export async function api<T>(request: APIRequestContext, path: string, auth: string, options: { method?: string; data?: unknown } = {}) {
  const response = await request.fetch(`${apiBase}${path}`, {
    method: options.method ?? "GET",
    data: options.data,
    headers: { Authorization: `Bearer ${auth}`, Accept: "application/json" },
  });
  const body = await response.json().catch(() => ({})) as Envelope<T>;
  return { response, data: body.data };
}

export async function classFixture(request: APIRequestContext, studentPage: Page) {
  const studentToken = await token(studentPage, "student");
  const me = await api<{ active_class?: { id: string; name: string } }>(request, "/auth/me", studentToken);
  expect(me.data?.active_class, "student active class").toBeTruthy();
  return { studentToken, classroom: me.data!.active_class! };
}

export function card(page: Page, text: string) {
  return page.locator("article, [class*='rounded']").filter({ hasText: text }).last();
}
