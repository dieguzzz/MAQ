"use client";

import { useMapStore } from "@/stores/map-store";
import { LINE_COLORS, LINE_NAMES } from "@/config/metro-lines";
import { cn } from "@/lib/utils/cn";
import type { MetroLine } from "@/types/metro";

const LINES: MetroLine[] = [1, 2, 3];

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
      {LINES.map((line) => {
        const active = activeLines.includes(line);
        return (
          <button
            key={line}
            onClick={() => toggleLine(line)}
            className={cn(
              "rounded-[var(--radius)] px-3 py-1 text-sm font-semibold transition-all",
              active ? "text-white shadow" : "opacity-40"
            )}
            style={{
              backgroundColor: active ? LINE_COLORS[line] : "transparent",
              borderColor: LINE_COLORS[line],
              border: "2px solid",
            }}
            aria-pressed={active}
            aria-label={`${active ? "Ocultar" : "Mostrar"} ${LINE_NAMES[line]}`}
          >
            L{line}
          </button>
        );
      })}
    </div>
  );
}
