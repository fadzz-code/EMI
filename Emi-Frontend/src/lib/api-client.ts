import { env } from "./env";

const DEFAULT_TIMEOUT_MS = 15_000;

export type ApiPaginationMeta = {
  current_page?: number;
  last_page?: number;
  per_page?: number;
  total?: number;
  from?: number | null;
  to?: number | null;
};

export type ApiResponse<T> = {
  success: boolean;
  message: string;
  data?: T;
  code?: string;
  errors?: Record<string, string[]>;
  meta?: ApiPaginationMeta | Record<string, unknown>;
};

export class ApiError extends Error {
  code?: string;
  errors?: Record<string, string[]>;
  status: number;
  isTimeout: boolean;

  constructor(params: {
    message: string;
    status: number;
    code?: string;
    errors?: Record<string, string[]>;
    isTimeout?: boolean;
  }) {
    super(params.message);
    this.name = "ApiError";
    this.status = params.status;
    this.code = params.code;
    this.errors = params.errors;
    this.isTimeout = params.isTimeout ?? false;
  }
}

type ApiRequestOptions = Omit<RequestInit, "body" | "headers"> & {
  body?: unknown;
  token?: string | null;
  headers?: HeadersInit;
  query?: Record<string, string | number | boolean | null | undefined>;
  timeoutMs?: number;
};

function buildUrl(path: string, query?: ApiRequestOptions["query"]): string {
  if (path.startsWith("http")) {
    const url = new URL(path);
    appendQuery(url, query);
    return url.toString();
  }

  const normalizedPath = path.startsWith("/") ? path : `/${path}`;
  const url = new URL(`${env.apiBaseUrl}${normalizedPath}`);
  appendQuery(url, query);
  return url.toString();
}

function appendQuery(url: URL, query?: ApiRequestOptions["query"]) {
  Object.entries(query ?? {}).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== "") {
      url.searchParams.set(key, String(value));
    }
  });
}

function safeErrorMessage(status: number, fallback?: string, code?: string) {
  if (status === 401) {
    if (code === "INVALID_CREDENTIALS") {
      return fallback || "Email atau password yang Anda masukkan salah.";
    }

    return "Sesi Anda tidak valid. Silakan login kembali.";
  }

  if (status === 403) {
    return fallback || "Anda tidak memiliki izin untuk membuka data ini.";
  }

  if (status === 404) {
    return "Data tidak ditemukan.";
  }

  if (status === 422) {
    return fallback || "Data yang diberikan belum valid.";
  }

  if (status === 429) {
    return "Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.";
  }

  if (status >= 500) {
    // Show fallback message from backend if it looks like a known validation or domain exception
    if (fallback && code && code !== "SERVER_ERROR") {
      return fallback;
    }
    return "Layanan sedang bermasalah. Coba lagi beberapa saat lagi.";
  }

  if (fallback) {
    return fallback;
  }

  return "Permintaan API gagal.";
}

export function getFirstApiError(error: unknown): string {
  if (!(error instanceof ApiError)) {
    return "Terjadi kesalahan. Silakan coba lagi.";
  }

  const firstFieldError = Object.values(error.errors ?? {})
    .flat()
    .find(Boolean);

  return firstFieldError ?? error.message;
}

export async function apiRequest<T>(
  path: string,
  options: ApiRequestOptions = {},
): Promise<ApiResponse<T>> {
  const controller = new AbortController();
  const timeout = globalThis.setTimeout(
    () => controller.abort(),
    options.timeoutMs ?? DEFAULT_TIMEOUT_MS,
  );
  const headers = new Headers(options.headers);

  headers.set("Accept", "application/json");

  let body: BodyInit | undefined;
  if (options.body instanceof FormData) {
    body = options.body;
  } else if (options.body !== undefined) {
    headers.set("Content-Type", "application/json");
    body = JSON.stringify(options.body);
  }

  if (options.token) {
    headers.set("Authorization", `Bearer ${options.token}`);
  }

  try {
    const response = await fetch(buildUrl(path, options.query), {
      ...options,
      body,
      headers,
      signal: options.signal ?? controller.signal,
    });

    if (response.status === 204) {
      return {
        success: true,
        message: "Berhasil.",
      } satisfies ApiResponse<T>;
    }

    const contentType = response.headers.get("content-type") ?? "";
    const payload = contentType.includes("application/json")
      ? ((await response.json()) as ApiResponse<T>)
      : ({
          success: response.ok,
          message: response.statusText,
        } satisfies ApiResponse<T>);

    if (!response.ok || payload.success === false) {
      throw new ApiError({
        message: safeErrorMessage(response.status, payload.message, payload.code),
        status: response.status,
        code: payload.code,
        errors: payload.errors,
      });
    }

    return payload;
  } catch (error) {
    if (error instanceof ApiError) {
      throw error;
    }

    if (error instanceof DOMException && error.name === "AbortError") {
      throw new ApiError({
        message: "Koneksi ke server terlalu lama. Periksa jaringan lalu coba lagi.",
        status: 0,
        code: "REQUEST_TIMEOUT",
        isTimeout: true,
      });
    }

    throw new ApiError({
      message: "Tidak dapat terhubung ke server EMI.",
      status: 0,
      code: "NETWORK_ERROR",
    });
  }
  finally {
    globalThis.clearTimeout(timeout);
  }
}

export const apiClient = {
  get<T>(path: string, options?: Omit<ApiRequestOptions, "method" | "body">) {
    return apiRequest<T>(path, { ...options, method: "GET" });
  },
  post<T>(path: string, body?: unknown, options?: Omit<ApiRequestOptions, "method" | "body">) {
    return apiRequest<T>(path, { ...options, method: "POST", body });
  },
  put<T>(path: string, body?: unknown, options?: Omit<ApiRequestOptions, "method" | "body">) {
    return apiRequest<T>(path, { ...options, method: "PUT", body });
  },
  patch<T>(path: string, body?: unknown, options?: Omit<ApiRequestOptions, "method" | "body">) {
    return apiRequest<T>(path, { ...options, method: "PATCH", body });
  },
  delete<T>(path: string, options?: Omit<ApiRequestOptions, "method" | "body">) {
    return apiRequest<T>(path, { ...options, method: "DELETE" });
  },
};

export function getFieldError(error: ApiError | null, field: string) {
  return error?.errors?.[field]?.[0];
}
