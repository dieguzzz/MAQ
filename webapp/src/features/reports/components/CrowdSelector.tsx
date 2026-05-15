"use client";

import { cn } from "@/lib/utils/cn";

const LEVELS = [
  { value: 1, emoji: "🟢", label: "Vacía" },
  { value: 2, emoji: "🟡", label: "Baja" },
  { value: 3, emoji: "🟠", label: "Media" },
  { value: 4, emoji: "🔴", label: "Alta" },
  { value: 5, emoji: "🆘", label: "Muy Alta" },
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
              "flex flex-col items-center gap-1 rounded-[var(--radius-md)] p-2 text-center transition-all",
              "border-2 focus-visible:ring-2 focus-visible:ring-[var(--ring)] focus-visible:outline-none",
              selected
                ? "border-[var(--brand-primary)] bg-blue-50 scale-105 shadow-sm"
                : "border-[var(--border)] hover:border-[var(--muted-foreground)] hover:bg-[var(--muted)]"
            )}
          >
            <span className="text-2xl leading-none">{lvl.emoji}</span>
            <span className={cn("text-[10px] font-semibold", selected ? "text-[var(--brand-primary)]" : "text-[var(--muted-foreground)]")}>
              {lvl.label}
            </span>
          </button>
        );
      })}
    </div>
  );
}
