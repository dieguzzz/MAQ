"use client";

import { useState } from "react";
import { reportsService } from "../services/reports.service";
import { useAuthStore } from "@/stores/auth-store";

interface SubmitParams {
  stationId: string;
  stationOperational: "yes" | "partial" | "no";
  stationCrowd: number;
  stationIssues?: string[];
}

type SubmitState = "idle" | "loading" | "success" | "error";

export function useSubmitReport() {
  const user = useAuthStore((s) => s.user);
  const [state, setState] = useState<SubmitState>("idle");
  const [earnedPoints, setEarnedPoints] = useState(0);

  const submit = async (params: SubmitParams) => {
    if (!user) return;
    setState("loading");
    try {
      await reportsService.submitStationReport({ userId: user.uid, ...params });
      setEarnedPoints(10);
      setState("success");
    } catch {
      setState("error");
    }
  };

  const reset = () => setState("idle");

  return { submit, state, earnedPoints, reset };
}
