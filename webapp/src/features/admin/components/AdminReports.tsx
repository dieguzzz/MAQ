"use client";

import { useState } from "react";
import { useAdminReports } from "../hooks/useAdminData";
import { adminReportsService } from "../services/admin.service";
import { STATIC_STATIONS } from "@/config/stations-static";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils/cn";
import type { SimplifiedReport } from "@/types/metro";

function stationName(id: string) {
  return STATIC_STATIONS.find((s) => s.id === id)?.nombre ?? id;
}

function timeAgo(date: Date) {
  const mins = Math.round((Date.now() - date.getTime()) / 60_000);
  if (mins < 1) return "ahora";
  if (mins < 60) return `${mins}m`;
  return `${Math.floor(mins / 60)}h ${mins % 60}m`;
}

function ReportRow({ report }: { report: SimplifiedReport }) {
  const [loading, setLoading] = useState(false);
  const [done, setDone] = useState(false);

  const act = async (action: "resolve" | "expire") => {
    setLoading(true);
    try {
      if (action === "resolve") await adminReportsService.resolveReport(report.id);
      else await adminReportsService.expireReport(report.id);
      setDone(true);
    } finally {
      setLoading(false);
    }
  };

  const operEmoji =
    report.stationOperational === "no" ? "🚫" :
    report.stationOperational === "partial" ? "⚠️" : "✅";

  const statusVariant =
    report.status === "active" ? "default" :
    report.status === "resolved" ? "success" : "secondary";

  return (
    <div className={cn(
      "rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--card)] p-3 text-sm",
      done && "opacity-50 pointer-events-none"
    )}>
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <span>{operEmoji}</span>
            <span className="font-semibold">{stationName(report.stationId)}</span>
            <Badge variant={statusVariant}>{report.status}</Badge>
            {report.stationCrowd && (
              <Badge variant="secondary">Afluencia {report.stationCrowd}/5</Badge>
            )}
          </div>
          {report.stationIssues && report.stationIssues.length > 0 && (
            <div className="mt-1 flex flex-wrap gap-1">
              {report.stationIssues.map((issue) => (
                <span key={issue} className="rounded-full bg-[var(--muted)] px-2 py-0.5 text-[10px]">
                  {issue}
                </span>
              ))}
            </div>
          )}
          <p className="mt-1 text-xs text-[var(--muted-foreground)]">
            {timeAgo(report.createdAt)} · {report.confirmations} confirmaciones
            {report.confidence !== undefined && ` · ${Math.round(report.confidence * 100)}% conf.`}
          </p>
        </div>

        {report.status === "active" && (
          <div className="flex shrink-0 flex-col gap-1.5">
            <Button
              size="sm"
              variant="secondary"
              className="text-xs"
              disabled={loading}
              onClick={() => act("resolve")}
            >
              ✅ Resolver
            </Button>
            <Button
              size="sm"
              variant="outline"
              className="text-xs"
              disabled={loading}
              onClick={() => act("expire")}
            >
              🗑️ Expirar
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}

export function AdminReports() {
  const { reports, loading } = useAdminReports();
  const [filter, setFilter] = useState<"all" | "active" | "resolved">("active");

  if (loading) {
    return (
      <div className="space-y-2 animate-pulse">
        {Array.from({ length: 8 }).map((_, i) => (
          <div key={i} className="h-16 rounded-[var(--radius-lg)] bg-[var(--muted)]" />
        ))}
      </div>
    );
  }

  const filtered = filter === "all" ? reports : reports.filter((r) => r.status === filter);

  return (
    <div className="space-y-3">
      <div className="flex gap-2">
        {(["active", "resolved", "all"] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={cn(
              "rounded-full border-2 px-3 py-1 text-xs font-semibold capitalize transition-all",
              filter === f
                ? "border-[var(--brand-primary)] bg-blue-50 text-[var(--brand-primary)]"
                : "border-[var(--border)] text-[var(--muted-foreground)] hover:border-[var(--muted-foreground)]"
            )}
          >
            {f === "all" ? "Todos" : f === "active" ? "Activos" : "Resueltos"} (
            {f === "all" ? reports.length : reports.filter((r) => r.status === f).length})
          </button>
        ))}
      </div>

      <div className="space-y-2">
        {filtered.map((r) => <ReportRow key={r.id} report={r} />)}
        {filtered.length === 0 && (
          <p className="py-6 text-center text-sm text-[var(--muted-foreground)]">Sin reportes en este estado</p>
        )}
      </div>
    </div>
  );
}
