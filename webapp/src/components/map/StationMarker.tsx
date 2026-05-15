"use client";

import { AdvancedMarker, Pin } from "@vis.gl/react-google-maps";
import { LINE_KEY_COLORS } from "@/config/metro-lines";
import type { Station, StationStatus } from "@/types/metro";

const STATUS_BG: Record<StationStatus, string> = {
  normal: "#22c55e",
  moderado: "#f59e0b",
  lleno: "#ef4444",
  cerrado: "#6b7280",
};

interface Props {
  station: Station;
  isSelected: boolean;
  onClick: () => void;
}

export function StationMarker({ station, isSelected, onClick }: Props) {
  const lineColor = LINE_KEY_COLORS[station.linea];
  const bgColor = isSelected ? lineColor : STATUS_BG[station.estado_actual];

  return (
    <AdvancedMarker
      position={{ lat: station.lat, lng: station.lng }}
      onClick={onClick}
      title={station.nombre}
    >
      <Pin
        background={bgColor}
        borderColor={lineColor}
        glyphColor="#ffffff"
        scale={isSelected ? 1.3 : 1}
      />
    </AdvancedMarker>
  );
}
