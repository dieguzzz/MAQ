const SESSION_COOKIE = "__session";

export function setSessionCookie(value: string | null) {
  if (typeof document === "undefined") return;
  if (value) {
    const expires = new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toUTCString();
    document.cookie = `${SESSION_COOKIE}=${value}; path=/; expires=${expires}; SameSite=Strict`;
  } else {
    document.cookie = `${SESSION_COOKIE}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
  }
}
