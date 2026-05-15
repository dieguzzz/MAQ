"use client";

import { useState, useEffect } from "react";
import { useAuthStore } from "@/stores/auth-store";
import { userProfileService, type UserProfile } from "../services/user-profile.service";

export function useUserProfile(uid?: string) {
  const currentUser = useAuthStore((s) => s.user);
  const targetUid = uid ?? currentUser?.uid;

  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(!!targetUid);

  useEffect(() => {
    if (!targetUid) return;
    const unsub = userProfileService.subscribeProfile(targetUid, (p) => {
      setProfile(p);
      setLoading(false);
    });
    return unsub;
  }, [targetUid]);

  return { profile, loading };
}

export function useLeaderboard(count = 20) {
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = userProfileService.subscribeLeaderboard((data) => {
      setUsers(data);
      setLoading(false);
    }, count);
    return unsub;
  }, [count]);

  return { users, loading };
}
