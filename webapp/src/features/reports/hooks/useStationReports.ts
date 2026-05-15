"use client";

import { useState, useEffect } from "react";
import { reportsService } from "../services/reports.service";
import type { SimplifiedReport } from "@/types/metro";

export function useStationReports(stationId: string | null) {
  const [reports, setReports] = useState<SimplifiedReport[]>([]);
  const [loading, setLoading] = useState(!!stationId);

  useEffect(() => {
    if (!stationId) return;
    const unsub = reportsService.subscribeByStation(stationId, (data) => {
      setReports(data);
      setLoading(false);
    });
    return unsub;
  }, [stationId]);

  return { reports, loading };
}
