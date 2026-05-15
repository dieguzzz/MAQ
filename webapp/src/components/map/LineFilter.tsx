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
    <div
      className={cn(
        "flex gap-2 rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--background)]/90 p-2 shadow backdrop-blur-sm",
        className
      )}
    >
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
              "rounded-[var(--radius)] px-3 py-1 text-sm font-semibold transition-all",
              active ? "text-white shadow" : "opacity-40"
            )}
            style={{
              backgroundColor: active ? color : "transparent",
              border: `2px solid ${color}`,
            }}
            aria-pressed={active}
            aria-label={`${active ? "Ocultar" : "Mostrar"} ${label}`}
          >
            {shortLabel}
          </button>
        );
      })}
    </div>
  );
}
