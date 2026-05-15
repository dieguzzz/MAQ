"use client";

import { useState } from "react";
import { useStations } from "@/features/stations/hooks/useStations";
import { adminStationsService } from "../services/admin.service";
import { LINE_KEY_COLORS, LINE_KEY_NAMES } from "@/config/metro-lines";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils/cn";
import type { Station, StationStatus } from "@/types/metro";

const STATUS_OPTIONS: { value: StationStatus; emoji: string; label: string }[] = [
  { value: "normal",   emoji: "✅", label: "Normal" },
  { value: "moderado", emoji: "🟡", label: "Moderado" },
  { value: "lleno",    emoji: "🔴", label: "Lleno" },
  { value: "cerrado",  emoji: "🚫", label: "Cerrado" },
];

const STATUS_VARIANT: Record<StationStatus, "success" | "warning" | "destructive" | "secondary"> = {
  normal: "success", moderado: "warning", lleno: "destructive", cerrado: "secondary",
};

function StationRow({ station }: { station: Station }) {
  const [editing, setEditing] = useState(false);
  const [status, setStatus] = useState<StationStatus>(station.estado_actual);
  const [crowd, setCrowd] = useState(station.aglomeracion);
  const [saving, setSaving] = useState(false);
  const color = LINE_KEY_COLORS[station.linea];

  const save = async () => {
    setSaving(true);
    try {
      await adminStationsService.updateStatus(station.id, status, crowd);
      setEditing(false);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className={cn(
      "rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--card)] p-3 transition-all",
      editing && "ring-2 ring-[var(--brand-primary)]"
    )}>
      <div className="flex items-center gap-3">
        <div
          className="h-2.5 w-2.5 shrink-0 rounded-full"
          style={{ backgroundColor: color }}
        />
        <div className="min-w-0 flex-1">
          <p className="truncate font-semibold text-sm">{station.nombre}</p>
          <p className="text-xs text-[var(--muted-foreground)]">{LINE_KEY_NAMES[station.linea]}</p>
        </div>
        <Badge variant={STATUS_VARIANT[station.estado_actual]} className="shrink-0">
          {station.estado_actual}
        </Badge>
        <Button
          variant="ghost"
          size="sm"
          onClick={() => setEditing((e) => !e)}
          className="shrink-0 text-xs"
        >
          {editing ? "Cancelar" : "Editar"}
        </Button>
      </div>

      {editing && (
        <div className="mt-3 space-y-3 border-t border-[var(--border)] pt-3 animate-fade-in">
          {/* Status selector */}
          <div>
            <p className="mb-1.5 text-xs font-semibold text-[var(--muted-foreground)]">Estado</p>
            <div className="flex flex-wrap gap-2">
              {STATUS_OPTIONS.map((opt) => (
                <button
                  key={opt.value}
                  type="button"
                  onClick={() => setStatus(opt.value)}
                  className={cn(
                    "flex items-center gap-1.5 rounded-full border-2 px-3 py-1 text-xs font-semibold transition-all",
                    status === opt.value
                      ? "border-[var(--brand-primary)] bg-blue-50 text-[var(--brand-primary)]"
                      : "border-[var(--border)] text-[var(--muted-foreground)] hover:border-[var(--muted-foreground)]"
                  )}
                >
                  {opt.emoji} {opt.label}
                </button>
              ))}
            </div>
          </div>

          {/* Crowd selector */}
          <div>
            <p className="mb-1.5 text-xs font-semibold text-[var(--muted-foreground)]">
              Afluencia: <span className="font-black text-[var(--foreground)]">{crowd}/5</span>
            </p>
            <input
              type="range"
              min={1}
              max={5}
              step={1}
              value={crowd}
              onChange={(e) => setCrowd(Number(e.target.value))}
              className="w-full accent-[var(--brand-primary)]"
            />
          </div>

          <Button size="sm" onClick={save} disabled={saving} style={{ backgroundColor: color }}>
            {saving ? "Guardando…" : "Guardar cambios"}
          </Button>
        </div>
      )}
    </div>
  );
}

export function AdminStations() {
  const { stations, loading } = useStations();
  const [filter, setFilter] = useState<StationStatus | "all">("all");

  if (loading) {
    return (
      <div className="space-y-2 animate-pulse">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="h-14 rounded-[var(--radius-lg)] bg-[var(--muted)]" />
        ))}
      </div>
    );
  }

  const filtered = filter === "all" ? stations : stations.filter((s) => s.estado_actual === filter);

  return (
    <div className="space-y-3">
      {/* Filter bar */}
      <div className="flex flex-wrap gap-2">
        {([
          { value: "all", label: "Todas", count: stations.length },
          { value: "cerrado", label: "Cerradas", count: stations.filter((s) => s.estado_actual === "cerrado").length },
          { value: "lleno", label: "Llenas", count: stations.filter((s) => s.estado_actual === "lleno").length },
          { value: "moderado", label: "Moderadas", count: stations.filter((s) => s.estado_actual === "moderado").length },
        ] as const).map((f) => (
          <button
            key={f.value}
            onClick={() => setFilter(f.value)}
            className={cn(
              "rounded-full border-2 px-3 py-1 text-xs font-semibold transition-all",
              filter === f.value
                ? "border-[var(--brand-primary)] bg-blue-50 text-[var(--brand-primary)]"
                : "border-[var(--border)] text-[var(--muted-foreground)] hover:border-[var(--muted-foreground)]"
            )}
          >
            {f.label} ({f.count})
          </button>
        ))}
      </div>

      {/* Station list */}
      <div className="space-y-2">
        {filtered.map((s) => <StationRow key={s.id} station={s} />)}
        {filtered.length === 0 && (
          <p className="py-6 text-center text-sm text-[var(--muted-foreground)]">
            Sin estaciones en este estado
          </p>
        )}
      </div>
    </div>
  );
}
