import type { MetroLine, LineKey } from "@/types/metro";

// Real Panama Metro brand colors (from design-rules.md)
export const LINE_COLORS: Record<MetroLine, string> = {
  1: "#0066CC", // Línea 1 — Azul
  2: "#009933", // Línea 2 — Verde
  3: "#e74c3c", // Línea 3 — Rojo (future)
};

export const LINE_KEY_COLORS: Record<LineKey, string> = {
  linea1: "#0066CC",
  linea2: "#009933",
  linea3: "#e74c3c",
};

// Soft gradient backgrounds per line
export const LINE_KEY_GRADIENTS: Record<LineKey, string> = {
  linea1: "from-white to-[#F0F7FF]",
  linea2: "from-white to-[#F0FFF4]",
  linea3: "from-white to-[#FFF0F0]",
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
