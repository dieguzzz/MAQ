"use client";

import { useMemo } from "react";
import { calculateRoute, type CalculatedRoute } from "../services/route-calculator";
import type { Station } from "@/types/metro";

export function useRouteCalculation(
  origin: Station | null,
  destination: Station | null,
  liveStations: Station[]
): CalculatedRoute | null {
  return useMemo(() => {
    if (!origin || !destination) return null;
    return calculateRoute(origin, destination, liveStations);
  }, [origin, destination, liveStations]);
}
