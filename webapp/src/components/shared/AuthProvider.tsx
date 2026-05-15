"use client";

import { useAuthListener } from "@/features/auth/hooks/useAuthListener";
import { useEffect } from "react";
import { useAuthStore } from "@/stores/auth-store";
import { userProfileService } from "@/features/gamification/services/user-profile.service";
import type { ReactNode } from "react";

function ProfileSync() {
  const user = useAuthStore((s) => s.user);

  useEffect(() => {
    if (!user) return;
    // Fire-and-forget: create Firestore doc if first login
    userProfileService.createIfNotExists(user).catch(console.error);
  }, [user]);

  return null;
}

export function AuthProvider({ children }: { children: ReactNode }) {
  useAuthListener();
  return (
    <>
      <ProfileSync />
      {children}
    </>
  );
}
