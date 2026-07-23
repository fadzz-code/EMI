import { resolve } from "node:path";

import { chromium, expect, test } from "@playwright/test";

import { api, card, classFixture, rolePage, token, unique } from "./helpers";

test("[E2E Cross Role] speaking target flows through fake mic, teacher review, stable reviewed state, archive", async ({ browser, request }) => {
  test.setTimeout(120_000);
  const teacher = await rolePage(browser, "teacher");
  const studentSetup = await rolePage(browser, "student");
  const teacherAuth = await token(teacher.page, "teacher");
  const { classroom } = await classFixture(request, studentSetup.page);
  const title = unique("Speaking");
  const feedback = unique("Review");
  let exerciseId: string | undefined;
  let attemptId: string | undefined;
  const micBrowser = await chromium.launch({ args: ["--use-fake-device-for-media-stream", `--use-file-for-fake-audio-capture=${resolve("e2e/fixtures/silence.pcm.wav").replaceAll("\\", "/")}`] });
  const micContext = await micBrowser.newContext({ baseURL: process.env.E2E_BASE_URL ?? "http://127.0.0.1:3000", storageState: "playwright/.auth/student.json", permissions: ["microphone"] });
  await micContext.addInitScript(() => {
    Object.defineProperty(navigator.mediaDevices, "getUserMedia", { configurable: true, value: async () => {
      const audio = new AudioContext();
      const oscillator = audio.createOscillator();
      const destination = audio.createMediaStreamDestination();
      oscillator.connect(destination);
      oscillator.start();
      return destination.stream;
    } });
  });
  const student = await micContext.newPage();

  try {
    const created = await api<{ id: string }>(request, "/teacher/speaking/exercises", teacherAuth, { method: "POST", data: { classroom_id: classroom.id, title, target_text: "Mekongga cross role", prompt_text: "Baca target", language_code: "mek", difficulty: "beginner", status: "published" } });
    expect(created.response.status()).toBe(201);
    exerciseId = created.data!.id;
    await teacher.page.goto("/teacher/speaking/exercises");
    await expect(card(teacher.page, title).getByText("Published", { exact: true })).toBeVisible();

    await student.goto("/student/speaking");
    await student.getByText(title, { exact: true }).click();
    await student.getByRole("button", { name: "Mulai rekaman" }).click();
    await student.waitForTimeout(500);
    await student.getByRole("button", { name: "Stop rekaman" }).click();
    const uploaded = student.waitForResponse((response) => response.url().includes(`/student/speaking/exercises/${exerciseId}/attempts`) && response.request().method() === "POST");
    await student.getByRole("button", { name: "Kirim audio" }).click();
    attemptId = (await (await uploaded).json() as { data: { id: string } }).data.id;

    await teacher.page.goto("/teacher/speaking/results");
    await teacher.page.getByPlaceholder("Cari siswa, latihan, status...").fill(title);
    await teacher.page.getByRole("button").filter({ hasText: title }).first().click();
    await teacher.page.getByLabel("Skor guru (0-100)").fill("91");
    await teacher.page.getByLabel("Feedback guru").fill(feedback);
    await teacher.page.getByRole("button", { name: "Simpan Feedback Guru" }).click();
    await expect(teacher.page.getByText("Feedback speaking berhasil disimpan.")).toBeVisible();

    await student.goto("/student/speaking/results");
    await expect(student.getByText(`Feedback: ${feedback}`, { exact: true })).toBeVisible();
    await student.waitForTimeout(2_000);
    const stable = await api<{ status: string; teacher_feedback: string }>(request, `/student/speaking/attempts/${attemptId}`, await student.evaluate(() => localStorage.getItem("emi.auth.token") ?? ""));
    expect(stable.data).toMatchObject({ status: "reviewed", teacher_feedback: feedback });
    expect(classroom.id).toBeTruthy();
  } finally {
    if (exerciseId) await api(request, `/teacher/speaking/exercises/${exerciseId}/archive`, teacherAuth, { method: "PATCH" });
    await Promise.all([teacher.context.close(), studentSetup.context.close(), micContext.close()]);
    await micBrowser.close();
  }
});
