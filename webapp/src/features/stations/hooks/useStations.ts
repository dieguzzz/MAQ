"use client";

import { useState, useEffect } from "react";
import { stationsService } from "../services/stations.service";
import type { Station } from "@/types/metro";

export function useStations() {
  const [stations, setStations] = useState<Station[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsub = stationsService.subscribeAll((data) => {
      setStations(data);
      setLoading(false);
    });
    return unsub;
  }, []);

  return { stations, loading };
}

export function useStation(stationId: string | null) {
  const [station, setStation] = useState<Station | null>(null);
  const [loading, setLoading] = useState(!!stationId);

  useEffect(() => {
    if (!stationId) return;
    const unsub = stationsService.subscribeOne(stationId, (data) => {
      setStation(data);
      setLoading(false);
    });
    return unsub;
  }, [stationId]);

  return { station, loading };
}
