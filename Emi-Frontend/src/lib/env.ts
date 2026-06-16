export const env = {
  appName:
    process.env.NEXT_PUBLIC_APP_NAME ??
    "EMI — Elearning Mekongga Indonesia",
  apiBaseUrl:
    process.env.NEXT_PUBLIC_API_BASE_URL ??
    "http://localhost:8000/api/v1",
} as const;
