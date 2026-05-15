"use client";

import { X, Users, Clock, Zap } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { LINE_KEY_COLORS, LINE_KEY_NAMES } from "@/config/metro-lines";
import { cn } from "@/lib/utils/cn";
import type { Station, StationStatus } from "@/types/metro";

const STATUS_LABELS: Record<StationStatus, string> = {
  normal: "Normal",
  moderado: "Moderado",
  lleno: "Lleno",
  cerrado: "Cerrado",
};

const STATUS_VARIANT: Record<
  StationStatus,
  "success" | "warning" | "destructive" | "secondary"
> = {
  normal: "success",
  moderado: "warning",
  lleno: "destructive",
  cerrado: "secondary",
};

// Convert 1-5 scale to human label
const CROWD_LABELS: Record<number, string> = {
  1: "Vacía",
  2: "Baja",
  3: "Media",
  4: "Alta",
  5: "Muy Alta",
};

interface Props {
  station: Station;
  onClose: () => void;
  onReport?: () => void;
  className?: string;
}

export function StationPanel({ station, onClose, onReport, className }: Props) {
  const lineColor = LINE_KEY_COLORS[station.linea];

  return (
    <Card className={cn("mx-auto w-full max-w-sm shadow-xl", className)}>
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between gap-2">
          <div>
            <div
              className="mb-1 text-xs font-semibold uppercase tracking-wider"
              style={{ color: lineColor }}
            >
              {LINE_KEY_NAMES[station.linea]}
            </div>
            <CardTitle className="text-lg">{station.nombre}</CardTitle>
          </div>
          <Button variant="ghost" size="icon" onClick={onClose} className="shrink-0">
            <X className="h-4 w-4" />
          </Button>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <Badge variant={STATUS_VARIANT[station.estado_actual]}>
            {STATUS_LABELS[station.estado_actual]}
          </Badge>
          {station.is_estimated && (
            <Badge variant="outline" className="text-xs">
              Estimado
            </Badge>
          )}
          {station.confidence && (
            <Badge variant="outline" className="text-xs capitalize">
              {station.confidence}
            </Badge>
          )}
        </div>
      </CardHeader>

      <CardContent className="space-y-3">
        <div className="flex items-center gap-2 text-sm text-[var(--muted-foreground)]">
          <Users className="h-4 w-4 shrink-0" />
          <span>
            Afluencia:{" "}
            <span className="font-medium text-[var(--foreground)]">
              {CROWD_LABELS[station.aglomeracion] ?? station.aglomeracion}
            </span>
          </span>
        </div>

        {/* Crowd bar */}
        <div className="h-2 w-full overflow-hidden rounded-full bg-[var(--muted)]">
          <div
            className="h-full rounded-full transition-all"
            style={{
              width: `${(station.aglomeracion / 5) * 100}%`,
              backgroundColor: lineColor,
            }}
          />
        </div>

        <div className="flex items-center gap-2 text-sm text-[var(--muted-foreground)]">
          <Clock className="h-4 w-4 shrink-0" />
          <span>
            Actualizado:{" "}
            {station.ultima_actualizacion.toLocaleTimeString("es-PA", {
              hour: "2-digit",
              minute: "2-digit",
            })}
          </span>
        </div>

        <Button className="mt-2 w-full" size="sm" onClick={onReport}>
          <Zap className="mr-1.5 h-4 w-4" />
          Reportar en esta estación
        </Button>
      </CardContent>
    </Card>
  );
}
