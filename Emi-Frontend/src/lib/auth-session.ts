export const AUTH_TOKEN_KEY = "emi.auth.token";
export const AUTH_SESSION_MESSAGE_KEY = "emi.auth.session_message";

const EMI_STORAGE_KEY_PREFIXES = ["emi.auth.", "emi.session."];
const EMI_COOKIE_NAMES = ["XSRF-TOKEN", "laravel_session", "emi_session"];
const PUBLIC_AUTH_PATHS = ["/login", "/register", "/pending-approval"];

let isRecoveringInvalidAuthSession = false;

function isBrowser() {
  return typeof window !== "undefined";
}

function removeMatchingStorageKeys(storage: Storage) {
  const keys = Array.from({ length: storage.length }, (_, index) => storage.key(index)).filter(
    (key): key is string => Boolean(key),
  );

  keys.forEach((key) => {
    if (EMI_STORAGE_KEY_PREFIXES.some((prefix) => key.startsWith(prefix))) {
      storage.removeItem(key);
    }
  });
}

function clearCookie(name: string) {
  document.cookie = `${name}=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/`;
  document.cookie = `${name}=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/;SameSite=Lax`;
}

export function clearAuthSession() {
  if (!isBrowser()) {
    return;
  }

  removeMatchingStorageKeys(window.localStorage);
  removeMatchingStorageKeys(window.sessionStorage);
  EMI_COOKIE_NAMES.forEach(clearCookie);
}

export function setSessionExpiredMessage(message = "Sesi Anda berakhir. Silakan masuk kembali.") {
  if (!isBrowser()) {
    return;
  }

  window.sessionStorage.setItem(AUTH_SESSION_MESSAGE_KEY, message);
}

export function consumeSessionExpiredMessage() {
  if (!isBrowser()) {
    return null;
  }

  const message = window.sessionStorage.getItem(AUTH_SESSION_MESSAGE_KEY);
  window.sessionStorage.removeItem(AUTH_SESSION_MESSAGE_KEY);
  return message;
}

export function isPublicAuthPath(pathname: string) {
  return PUBLIC_AUTH_PATHS.some((path) => pathname === path || pathname.startsWith(`${path}/`));
}

export function recoverInvalidAuthSession() {
  if (!isBrowser() || isRecoveringInvalidAuthSession) {
    return;
  }

  isRecoveringInvalidAuthSession = true;
  clearAuthSession();

  const { pathname } = window.location;
  if (isPublicAuthPath(pathname)) {
    isRecoveringInvalidAuthSession = false;
    return;
  }

  setSessionExpiredMessage();
  window.location.replace("/login");
}
