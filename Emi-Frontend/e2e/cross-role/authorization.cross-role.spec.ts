import { readFileSync } from "node:fs";

import { expect, test } from "@playwright/test";

import { api, apiBase, classFixture, rolePage, token, unique } from "./helpers";

test("[E2E Cross Role] foreign IDs and private media reject access without path or token leaks", async ({ browser, request }) => {
  const admin = await rolePage(browser, "admin");
  const teacher = await rolePage(browser, "teacher");
  const student = await rolePage(browser, "student");
  
  // Authorization approval test - UI side
  const unauthorizedCheck = await teacher.page.goto("/admin/approvals");
  await expect(teacher.page.locator("body")).toContainText(/Akses Ditolak|Halaman Tidak Ditemukan|Tidak ada akses|unauthorized/i);

  const adminAuth = await token(admin.page, "admin");
  const teacherAuth = await token(teacher.page, "teacher");
  const { studentToken, classroom } = await classFixture(request, student.page);
  let foreignClassId: string | undefined;
  let mediaId: string | undefined;

  try {
    const own = await api<{ school?: { id: string } }>(request, `/classes/${classroom.id}`, adminAuth);
    const foreign = await api<{ id: string }>(request, "/classes", adminAuth, { method: "POST", data: { school_id: own.data?.school?.id, name: unique("Foreign class"), grade_level: "99", academic_year: "2099/2100", status: "active" } });
    expect(foreign.response.status()).toBe(201);
    foreignClassId = foreign.data!.id;

    for (const [auth, endpoint] of [[teacherAuth, `/classes/${foreignClassId}`], [teacherAuth, `/classes/${foreignClassId}/modules`], [studentToken, `/classes/${foreignClassId}`]] as const) {
      expect([403, 404]).toContain((await api(request, endpoint, auth)).response.status());
    }

    const uploaded = await request.post(`${apiBase}/media`, { headers: { Authorization: `Bearer ${teacherAuth}`, Accept: "application/json" }, multipart: { purpose: "document", visibility: "private", file: { name: "tiny.pdf", mimeType: "application/pdf", buffer: readFileSync("e2e/fixtures/tiny.pdf") } } });
    expect(uploaded.status()).toBe(201);
    const uploadBody = await uploaded.json() as { data: Record<string, unknown> & { id: string } };
    mediaId = uploadBody.data.id;
    expect(uploadBody.data).not.toHaveProperty("path");
    expect(JSON.stringify(uploadBody.data)).not.toContain(teacherAuth);

    for (const endpoint of [`/media/${mediaId}`, `/media/${mediaId}/temporary-url`]) {
      const result = await api(request, endpoint, studentToken, { method: endpoint.endsWith("temporary-url") ? "POST" : "GET" });
      expect([403, 404]).toContain(result.response.status());
      const text = await result.response.text();
      expect(text).not.toMatch(/storage[\\/]|Bearer\s|emi\.auth\.token/i);
      expect(text).not.toContain(teacherAuth);
    }
  } finally {
    if (mediaId) await api(request, `/media/${mediaId}`, teacherAuth, { method: "DELETE" });
    if (foreignClassId) await api(request, `/classes/${foreignClassId}`, adminAuth, { method: "DELETE" });
    await Promise.all([admin.context.close(), teacher.context.close(), student.context.close()]);
  }
});
