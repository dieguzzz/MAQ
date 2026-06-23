"use client";

import { AdvancedMarker } from "@vis.gl/react-google-maps";
import { LINE_KEY_COLORS } from "@/config/metro-lines";
import type { Station, StationStatus } from "@/types/metro";

const STATUS_COLORS: Record<StationStatus, string> = {
  normal: "var(--status-normal)",
  moderado: "var(--status-moderado)",
  lleno: "var(--status-lleno)",
  cerrado: "var(--status-cerrado)",
};

const STATUS_SHAPES: Record<StationStatus, string> = {
  normal: "●",
  moderado: "▲",
  lleno: "■",
  cerrado: "✕",
};

interface Props {
  station: Station;
  isSelected: boolean;
  onClick: () => void;
}

export function StationMarker({ station, isSelected, onClick }: Props) {
  const lineColor = LINE_KEY_COLORS[station.linea];
  const statusColor = STATUS_COLORS[station.estado_actual];
  const isRecent = Date.now() - station.ultima_actualizacion.getTime() < 10 * 60 * 1000;

  return (
    <AdvancedMarker
      position={{ lat: station.lat, lng: station.lng }}
      onClick={onClick}
      title={`${station.nombre} — ${station.estado_actual}`}
    >
      <div className="relative flex items-center justify-center" style={{ width: isSelected ? 40 : 32, height: isSelected ? 40 : 32 }}>
        {isRecent && !isSelected && (
          <span
            className="absolute inset-0 rounded-full animate-pulse-ring"
            style={{ backgroundColor: statusColor, opacity: 0.3 }}
          />
        )}
        <span
          className="absolute inset-0 rounded-full border-[3px] transition-transform duration-[var(--transition-fast)]"
          style={{
            borderColor: isSelected ? lineColor : statusColor,
            backgroundColor: "white",
            transform: isSelected ? "scale(1.15)" : "scale(1)",
            boxShadow: isSelected ? "var(--shadow-float)" : "var(--shadow-card)",
          }}
        />
        <span
          className="relative text-[0.6rem] font-black leading-none"
          style={{ color: isSelected ? lineColor : statusColor }}
          aria-hidden="true"
        >
          {STATUS_SHAPES[station.estado_actual]}
        </span>
      </div>
    </AdvancedMarker>
  );
}
