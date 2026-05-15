"use client";

import { useRecentReports } from "../hooks/useRecentReports";
import { STATIC_STATIONS } from "@/config/stations-static";
import type { SimplifiedReport } from "@/types/metro";
import { LINE_KEY_COLORS } from "@/config/metro-lines";

const CROWD_LABELS: Record<number, string> = { 1: "Vacía", 2: "Baja", 3: "Media", 4: "Alta", 5: "Muy Alta" };

function stationName(id: string) {
  return STATIC_STATIONS.find((s) => s.id === id)?.nombre ?? id;
}

function stationLinea(id: string) {
  return STATIC_STATIONS.find((s) => s.id === id)?.linea ?? "linea1";
}

function timeAgo(date: Date) {
  const mins = Math.round((Date.now() - date.getTime()) / 60000);
  if (mins < 1) return "ahora";
  if (mins < 60) return `${mins}m`;
  return `${Math.floor(mins / 60)}h`;
}

function ReportCard({ report }: { report: SimplifiedReport }) {
  const linea = stationLinea(report.stationId);
  const color = LINE_KEY_COLORS[linea];
  const emoji =
    report.stationOperational === "no" ? "🚫" :
    report.stationOperational === "partial" ? "⚠️" : "✅";
  const operLabel =
    report.stationOperational === "yes" ? "Todo bien" :
    report.stationOperational === "partial" ? "Con problemas" :
    report.stationOperational === "no" ? "Cerrada" : "";

  return (
    <div className="metro-card flex gap-3 animate-fade-in">
      <div
        className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[var(--radius-md)] text-xl"
        style={{ backgroundColor: `${color}18` }}
      >
        {emoji}
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex items-baseline justify-between gap-2">
          <p className="truncate font-bold text-sm">{stationName(report.stationId)}</p>
          <span className="shrink-0 text-xs text-[var(--muted-foreground)]">{timeAgo(report.createdAt)}</span>
        </div>
        <p className="text-xs text-[var(--muted-foreground)]">
          {operLabel}
          {report.stationCrowd ? ` · Afluencia: ${CROWD_LABELS[report.stationCrowd]}` : ""}
        </p>
        {report.stationIssues && report.stationIssues.length > 0 && (
          <div className="mt-1 flex flex-wrap gap-1">
            {report.stationIssues.map((issue) => (
              <span key={issue} className="rounded-full bg-[var(--muted)] px-2 py-0.5 text-[10px] font-medium text-[var(--muted-foreground)]">
                {issue}
              </span>
            ))}
          </div>
        )}
      </div>
      <div className="h-8 w-1 shrink-0 rounded-full" style={{ backgroundColor: color }} />
    </div>
  );
}

export function ReportFeed() {
  const { reports, loading } = useRecentReports(30);

  if (loading) {
    return (
      <div className="space-y-3">
        {Array.from({ length: 5 }).map((_, i) => (
          <div key={i} className="metro-card h-16 animate-pulse bg-[var(--muted)]" />
        ))}
      </div>
    );
  }

  if (reports.length === 0) {
    return (
      <div className="flex flex-col items-center gap-3 py-12 text-center">
        <span className="text-5xl">🗺️</span>
        <p className="font-semibold">Sin reportes recientes</p>
        <p className="text-sm text-[var(--muted-foreground)]">
          Sé el primero en reportar el estado del metro.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {reports.map((r) => (
        <ReportCard key={r.id} report={r} />
      ))}
    </div>
  );
}
