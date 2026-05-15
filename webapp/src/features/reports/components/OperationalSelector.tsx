"use client";

import { cn } from "@/lib/utils/cn";

const OPTIONS = [
  { value: "yes",     emoji: "✅", label: "Operando",    desc: "Todo bien" },
  { value: "partial", emoji: "⚠️", label: "Parcial",     desc: "Con problemas" },
  { value: "no",      emoji: "🚫", label: "Cerrada",     desc: "No opera" },
] as const;

type OperationalValue = "yes" | "partial" | "no";

interface Props {
  value: OperationalValue | null;
  onChange: (v: OperationalValue) => void;
}

export function OperationalSelector({ value, onChange }: Props) {
  return (
    <div className="grid grid-cols-3 gap-3" role="radiogroup" aria-label="Estado de la estación">
      {OPTIONS.map((opt) => {
        const selected = value === opt.value;
        return (
          <button
            key={opt.value}
            type="button"
            role="radio"
            aria-checked={selected}
            onClick={() => onChange(opt.value)}
            className={cn(
              "flex flex-col items-center gap-1.5 rounded-[var(--radius-lg)] p-3 text-center transition-all",
              "border-2 focus-visible:ring-2 focus-visible:ring-[var(--ring)] focus-visible:outline-none",
              selected
                ? "border-[var(--brand-primary)] bg-blue-50 scale-[1.03] shadow-sm"
                : "border-[var(--border)] hover:border-[var(--muted-foreground)] hover:bg-[var(--muted)]"
            )}
          >
            <span className="text-2xl leading-none">{opt.emoji}</span>
            <span className={cn("text-xs font-bold", selected ? "text-[var(--brand-primary)]" : "text-[var(--foreground)]")}>
              {opt.label}
            </span>
            <span className="text-[10px] text-[var(--muted-foreground)]">{opt.desc}</span>
          </button>
        );
      })}
    </div>
  );
}
