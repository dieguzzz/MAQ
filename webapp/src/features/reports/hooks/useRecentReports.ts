"use client";

import { useState, useEffect } from "react";
import { reportsService } from "../services/reports.service";
import type { SimplifiedReport } from "@/types/metro";

export function useRecentReports(count = 20) {
  const [reports, setReports] = useState<SimplifiedReport[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = reportsService.subscribeRecent((data) => {
      setReports(data);
      setLoading(false);
    }, count);
    return unsub;
  }, [count]);

  return { reports, loading };
}
