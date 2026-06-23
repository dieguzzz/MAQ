"use client";

import { useMapStore } from "@/stores/map-store";
import { LINE_KEY_COLORS, LINE_KEY_NAMES } from "@/config/metro-lines";
import { cn } from "@/lib/utils/cn";
import type { LineKey } from "@/types/metro";

const LINES: LineKey[] = ["linea1", "linea2", "linea3"];

interface Props {
  className?: string;
}

export function LineFilter({ className }: Props) {
  const { activeLines, toggleLine } = useMapStore();

  return (
    <div className={cn("flex gap-1.5", className)}>
      {LINES.map((linea) => {
        const active = activeLines.includes(linea);
        const color = LINE_KEY_COLORS[linea];
        const label = LINE_KEY_NAMES[linea];
        const shortLabel = linea.replace("linea", "L");

        return (
          <button
            key={linea}
            onClick={() => toggleLine(linea)}
            className={cn(
              "flex items-center gap-1.5 rounded-[var(--radius-full)] px-3 py-1.5 text-xs font-bold transition-all shadow-[var(--shadow-sm)] backdrop-blur-sm",
              active
                ? "text-white"
                : "bg-[var(--background)]/80 text-[var(--muted-foreground)]"
            )}
            style={active ? { backgroundColor: color } : undefined}
            aria-pressed={active}
            aria-label={`${active ? "Ocultar" : "Mostrar"} ${label}`}
          >
            <span
              className="h-2.5 w-2.5 rounded-full shrink-0"
              style={{ backgroundColor: color }}
              aria-hidden="true"
            />
            {shortLabel}
          </button>
        );
      })}
    </div>
  );
}
