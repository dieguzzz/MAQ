"use client";

import { X, Users, Clock, AlertCircle } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { LINE_COLORS, LINE_NAMES } from "@/config/metro-lines";
import { cn } from "@/lib/utils/cn";
import type { Station } from "@/types/metro";

const STATUS_LABELS: Record<Station["status"], string> = {
  normal: "Normal",
  crowded: "Congestionado",
  closed: "Cerrado",
  unknown: "Sin datos",
};

const STATUS_VARIANT: Record<
  Station["status"],
  "success" | "warning" | "destructive" | "secondary"
> = {
  normal: "success",
  crowded: "warning",
  closed: "destructive",
  unknown: "secondary",
};

interface Props {
  station: Station;
  onClose: () => void;
  className?: string;
}

export function StationPanel({ station, onClose, className }: Props) {
  const lineColor = LINE_COLORS[station.line];

  return (
    <Card className={cn("mx-auto w-full max-w-sm shadow-xl", className)}>
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between gap-2">
          <div>
            <div
              className="mb-1 text-xs font-semibold uppercase tracking-wider"
              style={{ color: lineColor }}
            >
              {LINE_NAMES[station.line]}
            </div>
            <CardTitle className="text-lg">{station.name}</CardTitle>
          </div>
          <Button variant="ghost" size="icon" onClick={onClose} className="shrink-0">
            <X className="h-4 w-4" />
          </Button>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant={STATUS_VARIANT[station.status]}>
            {STATUS_LABELS[station.status]}
          </Badge>
          {station.isTerminal && (
            <Badge variant="outline">Terminal</Badge>
          )}
        </div>
      </CardHeader>

      <CardContent className="space-y-3">
        <div className="flex items-center gap-2 text-sm text-[var(--muted-foreground)]">
          <Users className="h-4 w-4" />
          <span>Afluencia: {station.crowdLevel}%</span>
        </div>
        <div className="flex items-center gap-2 text-sm text-[var(--muted-foreground)]">
          <Clock className="h-4 w-4" />
          <span>
            Actualizado:{" "}
            {station.updatedAt.toLocaleTimeString("es-PA", {
              hour: "2-digit",
              minute: "2-digit",
            })}
          </span>
        </div>
        {station.connectedLines && station.connectedLines.length > 0 && (
          <div className="flex items-center gap-2 text-sm">
            <AlertCircle className="h-4 w-4 text-[var(--muted-foreground)]" />
            <span className="text-[var(--muted-foreground)]">Conexiones: </span>
            {station.connectedLines.map((l) => (
              <span
                key={l}
                className="rounded-full px-2 py-0.5 text-xs font-bold text-white"
                style={{ backgroundColor: LINE_COLORS[l] }}
              >
                L{l}
              </span>
            ))}
          </div>
        )}

        <Button className="mt-2 w-full" size="sm">
          Reportar en esta estación
        </Button>
      </CardContent>
    </Card>
  );
}
