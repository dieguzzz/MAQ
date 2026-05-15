"use client";

import { useAuthStore } from "@/stores/auth-store";
import { useRouter } from "next/navigation";
import { useEffect, type ReactNode } from "react";

// Temporary: allow any logged-in user to access admin.
// Production: verify custom claim `admin: true` via Firebase ID token.
export function AdminGuard({ children }: { children: ReactNode }) {
  const { user, loading } = useAuthStore();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) router.replace("/login?redirect=/admin");
  }, [user, loading, router]);

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="h-10 w-10 animate-spin rounded-full border-4 border-[var(--border)] border-t-[var(--brand-primary)]" />
      </div>
    );
  }

  if (!user) return null;
  return <>{children}</>;
}
