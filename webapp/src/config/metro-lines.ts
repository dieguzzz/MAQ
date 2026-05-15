import type { MetroLine } from "@/types/metro";

export const LINE_COLORS: Record<MetroLine, string> = {
  1: "#2ecc71",
  2: "#3498db",
  3: "#e74c3c",
};

export const LINE_NAMES: Record<MetroLine, string> = {
  1: "Línea 1",
  2: "Línea 2",
  3: "Línea 3",
};

export const MAP_CENTER = { lat: 8.9936, lng: -79.5197 }; // Panama City
export const MAP_DEFAULT_ZOOM = 13;
