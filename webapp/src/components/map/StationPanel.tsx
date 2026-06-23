"use client";

import { X, Users, Clock, Zap, MessageSquare, CheckCircle, AlertTriangle, XCircle, MinusCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { LINE_KEY_COLORS, LINE_KEY_NAMES } from "@/config/metro-lines";
import { cn } from "@/lib/utils/cn";
import { useStationReports } from "@/features/reports/hooks/useStationReports";
import type { Station, StationStatus, SimplifiedReport } from "@/types/metro";

const STATUS_LABELS: Record<StationStatus, string> = {
  normal: "Normal",
  moderado: "Moderado",
  lleno: "Lleno",
  cerrado: "Cerrado",
};

const STATUS_BADGE_VARIANT: Record<StationStatus, "status-normal" | "status-moderado" | "status-lleno" | "status-cerrado"> = {
  normal: "status-normal",
  moderado: "status-moderado",
  lleno: "status-lleno",
  cerrado: "status-cerrado",
};

const STATUS_ICONS: Record<StationStatus, React.ReactNode> = {
  normal: <CheckCircle className="h-3 w-3" />,
  moderado: <AlertTriangle className="h-3 w-3" />,
  lleno: <XCircle className="h-3 w-3" />,
  cerrado: <MinusCircle className="h-3 w-3" />,
};

const CROWD_LABELS: Record<number, string> = { 1: "Vacía", 2: "Baja", 3: "Media", 4: "Alta", 5: "Muy Alta" };

function reportTimeAgo(createdAt: Date) {
  const mins = Math.round((Date.now() - createdAt.getTime()) / 60000);
  return mins < 1 ? "ahora" : `${mins}m`;
}

function CrowdDots({ level }: { level: number }) {
  return (
    <div className="flex gap-1.5">
      {Array.from({ length: 5 }, (_, i) => (
        <span
          key={i}
          className={cn(
            "h-2.5 w-2.5 rounded-full transition-colors",
            i < level ? "" : "bg-[var(--muted)]"
          )}
          style={i < level ? { backgroundColor: i < 2 ? "var(--status-normal)" : i < 4 ? "var(--status-moderado)" : "var(--status-lleno)" } : undefined}
        />
      ))}
    </div>
  );
}

function ReportPill({ report }: { report: SimplifiedReport }) {
  const emoji =
    report.stationOperational === "no" ? "🚫" :
    report.stationOperational === "partial" ? "⚠️" : "✅";
  const crowd = report.stationCrowd ? ` · ${CROWD_LABELS[report.stationCrowd] ?? ""}` : "";
  const ago = reportTimeAgo(report.createdAt);

  return (
    <div className="flex items-center gap-2 rounded-[var(--radius)] bg-[var(--muted)] px-2.5 py-1.5 text-xs">
      <span>{emoji}</span>
      <span className="font-medium">{report.stationOperational === "yes" ? "Todo bien" : report.stationOperational === "partial" ? "Con problemas" : "Cerrada"}{crowd}</span>
      <span className="ml-auto text-[var(--muted-foreground)]">{ago}</span>
    </div>
  );
}

interface Props {
  station: Station;
  onClose: () => void;
  onReport?: () => void;
  className?: string;
}

export function StationPanel({ station, onClose, onReport, className }: Props) {
  const lineColor = LINE_KEY_COLORS[station.linea];
  const { reports } = useStationReports(station.id);
  const recentReports = reports.slice(0, 3);

  return (
    <div
      className={cn(
        "mx-auto w-full max-w-sm rounded-[var(--radius-xl)] border border-[var(--border)] bg-[var(--card)] shadow-[var(--shadow-panel)] animate-slide-up overflow-hidden",
        className
      )}
    >
      {/* Line color accent strip */}
      <div className="h-1" style={{ backgroundColor: lineColor }} />

      <div className="p-4 space-y-3">
        {/* Header */}
        <div className="flex items-start justify-between gap-2">
          <div>
            <span className="text-[0.65rem] font-bold uppercase tracking-wider" style={{ color: lineColor }}>
              {LINE_KEY_NAMES[station.linea]}
            </span>
            <h3 className="text-lg font-black tracking-tight leading-tight">{station.nombre}</h3>
          </div>
          <Button variant="ghost" size="icon" onClick={onClose} className="shrink-0 rounded-full -mt-1 -mr-1 h-8 w-8">
            <X className="h-4 w-4" />
          </Button>
        </div>

        {/* Status + badges */}
        <div className="flex flex-wrap items-center gap-2">
          <Badge variant={STATUS_BADGE_VARIANT[station.estado_actual]} icon={STATUS_ICONS[station.estado_actual]}>
            {STATUS_LABELS[station.estado_actual]}
          </Badge>
          {station.is_estimated && <Badge variant="outline" className="text-[0.65rem]">Estimado</Badge>}
          {station.confidence && <Badge variant="outline" className="text-[0.65rem] capitalize">{station.confidence}</Badge>}
        </div>

        {/* Crowd dots */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-1.5 text-sm text-[var(--muted-foreground)]">
            <Users className="h-4 w-4" />
            <span>Afluencia</span>
          </div>
          <div className="flex items-center gap-2">
            <CrowdDots level={station.aglomeracion} />
            <span className="text-xs font-semibold">{CROWD_LABELS[station.aglomeracion] ?? station.aglomeracion}</span>
          </div>
        </div>

        {/* Update time */}
        <div className="flex items-center gap-1.5 text-xs text-[var(--muted-foreground)]">
          <Clock className="h-3.5 w-3.5" />
          <span>
            Actualizado:{" "}
            {station.ultima_actualizacion.toLocaleTimeString("es-PA", {
              hour: "2-digit",
              minute: "2-digit",
            })}
          </span>
        </div>

        {/* Recent reports */}
        {recentReports.length > 0 && (
          <div className="space-y-1.5">
            <div className="flex items-center gap-1.5 text-xs font-semibold text-[var(--muted-foreground)]">
              <MessageSquare className="h-3.5 w-3.5" />
              <span>Reportes recientes</span>
            </div>
            {recentReports.map((r) => (
              <ReportPill key={r.id} report={r} />
            ))}
          </div>
        )}

        {/* Report CTA */}
        <Button
          variant="accent"
          className="w-full font-bold"
          onClick={onReport}
        >
          <Zap className="mr-1.5 h-4 w-4" />
          Reportar estado
        </Button>
      </div>
    </div>
  );
}
