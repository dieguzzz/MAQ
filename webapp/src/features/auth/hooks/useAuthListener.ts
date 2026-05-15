"use client";

import { useEffect } from "react";
import { onAuthStateChanged } from "firebase/auth";
import { auth } from "@/lib/firebase/client";
import { useAuthStore } from "@/stores/auth-store";

// Firebase Auth session cookie name expected by the middleware
const SESSION_COOKIE = "__session";

function setSessionCookie(value: string | null) {
  if (typeof document === "undefined") return;
  if (value) {
    // Expire in 5 days; SameSite=Strict for CSRF protection
    const expires = new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toUTCString();
    document.cookie = `${SESSION_COOKIE}=${value}; path=/; expires=${expires}; SameSite=Strict`;
  } else {
    document.cookie = `${SESSION_COOKIE}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
  }
}

export function useAuthListener() {
  const setUser = useAuthStore((s) => s.setUser);
  const setLoading = useAuthStore((s) => s.setLoading);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        // Store a short-lived token so middleware can verify auth state
        const token = await user.getIdToken();
        setSessionCookie(token);
      } else {
        setSessionCookie(null);
      }
      setUser(user);
      setLoading(false);
    });
    return unsubscribe;
  }, [setUser, setLoading]);
}
