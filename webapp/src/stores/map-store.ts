import { create } from "zustand";
import type { Station, LineKey } from "@/types/metro";
import { MAP_CENTER, MAP_DEFAULT_ZOOM } from "@/config/metro-lines";

interface MapState {
  center: { lat: number; lng: number };
  zoom: number;
  selectedStation: Station | null;
  activeLines: LineKey[];
  setCenter: (center: { lat: number; lng: number }) => void;
  setZoom: (zoom: number) => void;
  selectStation: (station: Station | null) => void;
  toggleLine: (line: LineKey) => void;
}

export const useMapStore = create<MapState>((set) => ({
  center: MAP_CENTER,
  zoom: MAP_DEFAULT_ZOOM,
  selectedStation: null,
  activeLines: ["linea1", "linea2", "linea3"],
  setCenter: (center) => set({ center }),
  setZoom: (zoom) => set({ zoom }),
  selectStation: (station) => set({ selectedStation: station }),
  toggleLine: (line) =>
    set((state) => ({
      activeLines: state.activeLines.includes(line)
        ? state.activeLines.filter((l) => l !== line)
        : [...state.activeLines, line],
    })),
}));
