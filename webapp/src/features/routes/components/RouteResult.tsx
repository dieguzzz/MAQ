"use client";

import { Clock, ArrowRightLeft, AlertTriangle, CheckCircle2 } from "lucide-react";
import { LINE_KEY_COLORS, LINE_KEY_NAMES } from "@/config/metro-lines";
import type { CalculatedRoute, RouteSegment } from "../services/route-calculator";
import type { Station } from "@/types/metro";

function StationDot({ station, isEndpoint, color }: { station: Station; isEndpoint: boolean; color: string }) {
  const isClosed = station.estado_actual === "cerrado";
  const isCrowded = station.estado_actual === "lleno";

  return (
    <li className="relative flex items-center gap-3 pl-7">
      {/* Vertical line + dot */}
      <span
        className="absolute left-2.5 top-0 h-full w-0.5"
        style={{ backgroundColor: color }}
        aria-hidden
      />
      <span
        className="absolute left-0 top-2 h-5 w-5 rounded-full border-2 bg-[var(--card)]"
        style={{ borderColor: color }}
        aria-hidden
      >
        {isEndpoint && (
          <span
            className="absolute inset-0.5 rounded-full"
            style={{ backgroundColor: color }}
          />
        )}
      </span>

      <div className="flex-1 py-1.5">
        <p className={isEndpoint ? "font-bold" : "text-sm"}>
          {station.nombre}
        </p>
        {(isClosed || isCrowded) && (
          <p className="text-xs font-medium" style={{ color: isClosed ? "var(--destructive)" : "var(--warning)" }}>
            {isClosed ? "🚫 Cerrada" : "🔴 Lleno"}
          </p>
        )}
      </div>
    </li>
  );
}

function SegmentBlock({ segment, isFirst, isLast }: { segment: RouteSegment; isFirst: boolean; isLast: boolean }) {
  const color = LINE_KEY_COLORS[segment.linea];

  return (
    <div className="relative">
      <div className="mb-2 flex items-center gap-2">
        <span
          className="rounded-full px-2.5 py-0.5 text-xs font-bold text-white"
          style={{ backgroundColor: color }}
        >
          {LINE_KEY_NAMES[segment.linea]}
        </span>
        <span className="text-xs text-[var(--muted-foreground)]">
          {segment.stations.length} estaciones · ~{segment.timeMin} min
        </span>
      </div>
      <ul className="ml-1">
        {segment.stations.map((s, i) => (
          <StationDot
            key={`${segment.linea}-${s.id}-${i}`}
            station={s}
            isEndpoint={
              (isFirst && i === 0) ||
              (isLast && i === segment.stations.length - 1)
            }
            color={color}
          />
        ))}
      </ul>
    </div>
  );
}

const STATUS_CONFIG = {
  optima: { icon: CheckCircle2, label: "Ruta óptima",       color: "var(--success)",      bg: "bg-green-50",  border: "border-green-200" },
  congestionada: { icon: AlertTriangle, label: "Con congestión", color: "var(--warning)",   bg: "bg-amber-50",  border: "border-amber-200" },
  interrumpida: { icon: AlertTriangle, label: "Ruta interrumpida", color: "var(--destructive)", bg: "bg-red-50",    border: "border-red-200" },
} as const;

export function RouteResult({ route }: { route: CalculatedRoute }) {
  const cfg = STATUS_CONFIG[route.status];
  const StatusIcon = cfg.icon;

  return (
    <div className="space-y-4 animate-slide-up">
      {/* Summary card */}
      <div className="metro-card bg-gradient-to-br from-white to-[#F0F7FF]">
        <div className="flex items-center justify-between gap-3">
          <div>
            <p className="text-xs font-bold uppercase tracking-wider text-[var(--muted-foreground)]">
              Tiempo estimado
            </p>
            <p className="text-3xl font-black tracking-tight" style={{ color: "var(--brand-primary)" }}>
              {route.totalTimeMin} min
            </p>
          </div>
          <div className="flex flex-col items-end gap-1.5">
            <span className={`inline-flex items-center gap-1 rounded-full border px-2.5 py-1 text-xs font-semibold ${cfg.bg} ${cfg.border}`} style={{ color: cfg.color }}>
              <StatusIcon className="h-3.5 w-3.5" />
              {cfg.label}
            </span>
            {route.transfers > 0 && (
              <span className="inline-flex items-center gap-1 rounded-full bg-[var(--muted)] px-2.5 py-1 text-xs font-semibold text-[var(--muted-foreground)]">
                <ArrowRightLeft className="h-3.5 w-3.5" />
                {route.transfers} transbordo{route.transfers > 1 ? "s" : ""}
              </span>
            )}
          </div>
        </div>

        <div className="mt-3 flex items-center gap-1.5 text-xs text-[var(--muted-foreground)]">
          <Clock className="h-3.5 w-3.5" />
          <span>Basado en afluencia actual reportada por la comunidad</span>
        </div>
      </div>

      {/* Segments */}
      <div className="metro-card">
        <h3 className="mb-3 flex items-center gap-2 font-bold">
          <span>🛤️</span>
          <span>Tu recorrido</span>
        </h3>
        <div className="space-y-4">
          {route.segments.map((seg, i) => (
            <SegmentBlock
              key={i}
              segment={seg}
              isFirst={i === 0}
              isLast={i === route.segments.length - 1}
            />
          ))}
        </div>

        {route.transfers > 0 && (
          <div className="mt-4 rounded-[var(--radius)] bg-amber-50 border border-amber-200 p-3 text-xs text-amber-800">
            <strong>💡 Transbordo en San Miguelito:</strong> Camina a la otra línea
            (~{5} min). Sigue las señales en la estación.
          </div>
        )}
      </div>
    </div>
  );
}
