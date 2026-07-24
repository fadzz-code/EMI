import { resolve } from "node:path";

import { chromium, expect, test } from "@playwright/test";

import { api, archiveSpeakingExercise, createSpeakingExercise, studentClass, unique } from "./helpers";

test.use({ storageState: "playwright/.auth/student.json" });

test("fake microphone uploads, status/history persist, and teacher review is visible", async ({ page, request, browser }) => {
  const { studentClass: ownClass } = await studentClass(page, request);
  const fixture = await createSpeakingExercise(request, browser, ownClass.id);
  const microphoneBrowser = await chromium.launch({ args: ["--use-fake-device-for-media-stream", `--use-file-for-fake-audio-capture=${resolve("e2e/fixtures/silence.pcm.wav").replaceAll("\\", "/")}`] });
  const microphoneContext = await microphoneBrowser.newContext({ baseURL: process.env.E2E_BASE_URL ?? "http://127.0.0.1:3000", storageState: "playwright/.auth/student.json", permissions: ["microphone"] });
  await microphoneContext.addInitScript(() => {
    Object.defineProperty(navigator.mediaDevices, "getUserMedia", {
      configurable: true,
      value: async () => {
        const audio = new AudioContext();
        const oscillator = audio.createOscillator();
        const destination = audio.createMediaStreamDestination();
        oscillator.connect(destination);
        oscillator.start();
        return destination.stream;
      },
    });
  });
  const microphonePage = await microphoneContext.newPage();
  const feedback = unique("Speaking review");
  let attemptId: string | undefined;

  try {
    await microphonePage.goto("/student/speaking");
    await microphonePage.getByText(fixture.title, { exact: true }).click();
    await microphonePage.getByRole("button", { name: "Mulai rekaman" }).click();
    await expect(microphonePage.getByText("Sedang merekam...")).toBeVisible();
    await microphonePage.waitForTimeout(500);
    await microphonePage.getByRole("button", { name: "Stop rekaman" }).click();
    await expect(microphonePage.getByText("Rekaman siap dikirim")).toBeVisible();
    const uploaded = microphonePage.waitForResponse((response) => response.url().includes(`/student/speaking/exercises/${fixture.exerciseId}/attempts`) && response.request().method() === "POST");
    await microphonePage.getByRole("button", { name: "Kirim audio" }).click();
    const uploadResponse = await uploaded;
    expect(uploadResponse.status(), await uploadResponse.text()).toBe(201);
    const body = await uploadResponse.json() as { data: { id: string; status: string } };
    attemptId = body.data.id;
    expect(["pending", "processing", "completed", "failed"]).toContain(body.data.status);
    await expect(microphonePage.getByText("Hasil Percobaan Terakhir")).toBeVisible();

    let status = body.data.status;
    for (let poll = 0; poll < 5 && ["pending", "processing"].includes(status); poll += 1) {
      await microphonePage.waitForTimeout(1_000);
      const detail = await api<{ status: string }>(request, `/student/speaking/attempts/${attemptId}`, await microphonePage.evaluate(() => localStorage.getItem("emi.auth.token") ?? ""));
      status = detail.data!.status;
    }
    expect(["pending", "processing", "completed", "failed"]).toContain(status);

    const reviewed = await api(request, `/teacher/speaking/attempts/${attemptId}/feedback`, fixture.teacherAuth, { method: "PATCH", data: { teacher_score: 91, teacher_feedback: feedback } });
    expect(reviewed.response.ok()).toBeTruthy();
    await microphonePage.waitForTimeout(2_000);
    const stableReview = await api(request, `/teacher/speaking/attempts/${attemptId}/feedback`, fixture.teacherAuth, { method: "PATCH", data: { teacher_score: 91, teacher_feedback: feedback } });
    expect(stableReview.data).toMatchObject({ teacher_feedback: feedback, teacher_score: 91 });
    expect(["pending", "processing", "completed", "failed", "reviewed"]).toContain((stableReview.data as { status: string }).status);
    await microphonePage.goto("/student/speaking/results");
    await expect(microphonePage.getByText(fixture.title, { exact: true }).first()).toBeVisible();
    await expect(microphonePage.getByText(`Feedback: ${feedback}`, { exact: true })).toBeVisible();
    await microphonePage.reload();
    await expect(microphonePage.getByText(`Feedback: ${feedback}`, { exact: true })).toBeVisible();
  } finally {
    await microphoneContext.close();
    await microphoneBrowser.close();
    await archiveSpeakingExercise(request, fixture.exerciseId, fixture.teacherAuth);
  }
});
