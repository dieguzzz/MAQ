"use client";

import { AdvancedMarker, Pin } from "@vis.gl/react-google-maps";
import { LINE_COLORS } from "@/config/metro-lines";
import type { Station } from "@/types/metro";

const STATUS_BG: Record<Station["status"], string> = {
  normal: "#22c55e",
  crowded: "#f59e0b",
  closed: "#ef4444",
  unknown: "#94a3b8",
};

interface Props {
  station: Station;
  isSelected: boolean;
  onClick: () => void;
}

export function StationMarker({ station, isSelected, onClick }: Props) {
  const lineColor = LINE_COLORS[station.line];
  const bgColor = isSelected ? lineColor : STATUS_BG[station.status];

  return (
    <AdvancedMarker
      position={{ lat: station.lat, lng: station.lng }}
      onClick={onClick}
      title={station.name}
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
