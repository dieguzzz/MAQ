"use client";

import { useState, useEffect } from "react";
import { useStations } from "@/features/stations/hooks/useStations";
import {
  fetchAdminStats,
  adminReportsService,
  adminUsersService,
  type AdminStats,
} from "../services/admin.service";
import type { SimplifiedReport } from "@/types/metro";
import type { UserProfile } from "@/features/gamification/services/user-profile.service";

export function useAdminStats() {
  const { stations } = useStations();
  const [stats, setStats] = useState<AdminStats | null>(null);

  useEffect(() => {
    if (!stations.length) return;
    fetchAdminStats(stations).then(setStats).catch(console.error);
    // Refresh every 30s
    const id = setInterval(() => {
      fetchAdminStats(stations).then(setStats).catch(console.error);
    }, 30_000);
    return () => clearInterval(id);
  }, [stations]);

  return stats;
}

export function useAdminReports() {
  const [reports, setReports] = useState<SimplifiedReport[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = adminReportsService.subscribeRecent((data) => {
      setReports(data);
      setLoading(false);
    });
    return unsub;
  }, []);

  return { reports, loading };
}

export function useAdminUsers() {
  const [users, setUsers] = useState<UserProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [searchResults, setSearchResults] = useState<UserProfile[] | null>(null);
  const [searching, setSearching] = useState(false);

  useEffect(() => {
    const unsub = adminUsersService.subscribeTopUsers((data) => {
      setUsers(data);
      setLoading(false);
    });
    return unsub;
  }, []);

  const runSearch = async (term: string) => {
    setSearch(term);
    if (!term.trim()) {
      setSearchResults(null);
      return;
    }
    setSearching(true);
    try {
      const results = await adminUsersService.searchUsers(term);
      setSearchResults(results);
    } finally {
      setSearching(false);
    }
  };

  return {
    users: searchResults ?? users,
    loading,
    search,
    searching,
    runSearch,
  };
}
