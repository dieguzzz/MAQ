"use client";

import { cn } from "@/lib/utils/cn";

const LEVELS = [
  { value: 1, face: "😌", label: "Vacía", color: "var(--status-normal)" },
  { value: 2, face: "🙂", label: "Baja", color: "var(--status-normal)" },
  { value: 3, face: "😐", label: "Media", color: "var(--status-moderado)" },
  { value: 4, face: "😰", label: "Alta", color: "var(--status-lleno)" },
  { value: 5, face: "🤯", label: "Llena", color: "var(--status-lleno)" },
] as const;

interface Props {
  value: number;
  onChange: (v: number) => void;
}

export function CrowdSelector({ value, onChange }: Props) {
  return (
    <div className="grid grid-cols-5 gap-2" role="radiogroup" aria-label="Nivel de afluencia">
      {LEVELS.map((lvl) => {
        const selected = value === lvl.value;
        return (
          <button
            key={lvl.value}
            type="button"
            role="radio"
            aria-checked={selected}
            onClick={() => onChange(lvl.value)}
            className={cn(
              "flex flex-col items-center gap-1 rounded-[var(--radius-md)] p-2.5 text-center transition-all min-h-[4rem]",
              "border-2 focus-visible:ring-2 focus-visible:ring-[var(--ring)] focus-visible:outline-none",
              selected
                ? "scale-105 shadow-[var(--shadow-card)]"
                : "border-[var(--border)] hover:border-[var(--muted-foreground)] hover:bg-[var(--muted)]"
            )}
            style={selected ? { borderColor: lvl.color, backgroundColor: `color-mix(in srgb, ${lvl.color} 8%, white)` } : undefined}
          >
            <span className="text-[1.75rem] leading-none">{lvl.face}</span>
            <span className={cn("text-[10px] font-semibold", selected ? "font-bold" : "text-[var(--muted-foreground)]")}
              style={selected ? { color: lvl.color } : undefined}
            >
              {lvl.label}
            </span>
          </button>
        );
      })}
    </div>
  );
}
