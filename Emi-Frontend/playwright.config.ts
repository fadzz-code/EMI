import { existsSync } from "node:fs";
import { loadEnvFile } from "node:process";

import { defineConfig, devices } from "@playwright/test";

if (existsSync(".env.e2e")) loadEnvFile(".env.e2e");

const baseURL = process.env.E2E_BASE_URL ?? "http://127.0.0.1:3000";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: false,
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  timeout: 30_000,
  expect: {
    timeout: 10_000,
  },
  reporter: process.env.CI ? "line" : "list",
  outputDir: "test-results",
  use: {
    baseURL,
    screenshot: "only-on-failure",
    video: "retain-on-failure",
    trace: "retain-on-failure",
  },
  projects: [
    {
      name: "setup",
      testMatch: /.*\.setup\.ts/,
      use: { ...devices["Desktop Chrome"] },
    },
    {
      name: "public",
      testMatch: /.*public.*\.spec\.ts/,
      use: { ...devices["Desktop Chrome"] },
      dependencies: ["setup"],
    },
    {
      name: "chromium",
      testMatch: /.*admin.*\.spec\.ts/,
      use: {
        ...devices["Desktop Chrome"],
        storageState: "playwright/.auth/admin.json",
      },
      dependencies: ["setup"],
    },
    {
      name: "teacher",
      testMatch: /.*teacher.*\.spec\.ts/,
      use: {
        ...devices["Desktop Chrome"],
        storageState: "playwright/.auth/teacher.json",
      },
      dependencies: ["setup"],
    },
    {
      name: "student",
      testMatch: /.*student.*\.spec\.ts/,
      use: {
        ...devices["Desktop Chrome"],
        storageState: "playwright/.auth/student.json",
      },
      dependencies: ["setup"],
    },
    {
      name: "cross-role",
      testMatch: /.*cross-role.*\.spec\.ts/,
      use: { ...devices["Desktop Chrome"] },
      dependencies: ["setup"],
    },
  ],
});
