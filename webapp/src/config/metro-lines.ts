import type { MetroLine, LineKey } from "@/types/metro";

export const LINE_COLORS: Record<MetroLine, string> = {
  1: "#2ecc71",
  2: "#3498db",
  3: "#e74c3c",
};

export const LINE_KEY_COLORS: Record<LineKey, string> = {
  linea1: "#2ecc71",
  linea2: "#3498db",
  linea3: "#e74c3c",
};

export const LINE_NAMES: Record<MetroLine, string> = {
  1: "Línea 1",
  2: "Línea 2",
  3: "Línea 3",
};

export const LINE_KEY_NAMES: Record<LineKey, string> = {
  linea1: "Línea 1",
  linea2: "Línea 2",
  linea3: "Línea 3",
};

export const MAP_CENTER = { lat: 9.03, lng: -79.5 };
export const MAP_DEFAULT_ZOOM = 12;
