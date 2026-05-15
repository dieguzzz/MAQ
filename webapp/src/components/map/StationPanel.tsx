"use client";

import { X, Users, Clock, Zap, MessageSquare } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
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

const STATUS_VARIANT: Record<StationStatus, "success" | "warning" | "destructive" | "secondary"> = {
  normal: "success",
  moderado: "warning",
  lleno: "destructive",
  cerrado: "secondary",
};

const CROWD_LABELS: Record<number, string> = { 1: "Vacía", 2: "Baja", 3: "Media", 4: "Alta", 5: "Muy Alta" };

function reportTimeAgo(createdAt: Date) {
  const mins = Math.round((Date.now() - createdAt.getTime()) / 60000);
  return mins < 1 ? "ahora" : `${mins}m`;
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
    <Card className={cn("mx-auto w-full max-w-sm shadow-[var(--shadow-panel)] animate-slide-up", className)}>
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between gap-2">
          <div>
            <div className="mb-1 flex items-center gap-1.5">
              <span className="text-lg">🚇</span>
              <span className="text-xs font-bold uppercase tracking-wider" style={{ color: lineColor }}>
                {LINE_KEY_NAMES[station.linea]}
              </span>
            </div>
            <CardTitle className="text-lg font-black tracking-tight">{station.nombre}</CardTitle>
          </div>
          <Button variant="ghost" size="icon" onClick={onClose} className="shrink-0 rounded-full">
            <X className="h-4 w-4" />
          </Button>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <Badge variant={STATUS_VARIANT[station.estado_actual]}>
            {STATUS_LABELS[station.estado_actual]}
          </Badge>
          {station.is_estimated && <Badge variant="outline" className="text-xs">Estimado</Badge>}
          {station.confidence && <Badge variant="outline" className="text-xs capitalize">{station.confidence}</Badge>}
        </div>
      </CardHeader>

      <CardContent className="space-y-3">
        {/* Crowd bar */}
        <div className="space-y-1">
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center gap-1.5 text-[var(--muted-foreground)]">
              <Users className="h-4 w-4" />
              <span>Afluencia</span>
            </div>
            <span className="font-bold" style={{ color: lineColor }}>
              {CROWD_LABELS[station.aglomeracion] ?? station.aglomeracion}
            </span>
          </div>
          <div className="h-2.5 w-full overflow-hidden rounded-full bg-[var(--muted)]">
            <div
              className="h-full rounded-full transition-all duration-500"
              style={{ width: `${(station.aglomeracion / 5) * 100}%`, backgroundColor: lineColor }}
            />
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

        <Button
          className="mt-1 w-full font-bold"
          size="sm"
          onClick={onReport}
          style={{ backgroundColor: lineColor }}
        >
          <Zap className="mr-1.5 h-4 w-4" />
          Reportar estado ⚡
        </Button>
      </CardContent>
    </Card>
  );
}
