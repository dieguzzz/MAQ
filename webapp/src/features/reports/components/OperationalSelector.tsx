"use client";

import { CheckCircle, AlertTriangle, XCircle } from "lucide-react";
import { cn } from "@/lib/utils/cn";

const OPTIONS = [
  { value: "yes", icon: CheckCircle, label: "Funcionando", desc: "Todo bien", color: "var(--status-normal)", bg: "var(--status-normal-bg)" },
  { value: "partial", icon: AlertTriangle, label: "Problemas", desc: "Con fallas", color: "var(--status-moderado)", bg: "var(--status-moderado-bg)" },
  { value: "no", icon: XCircle, label: "Cerrada", desc: "No opera", color: "var(--status-lleno)", bg: "var(--status-lleno-bg)" },
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
        const Icon = opt.icon;
        return (
          <button
            key={opt.value}
            type="button"
            role="radio"
            aria-checked={selected}
            onClick={() => onChange(opt.value)}
            className={cn(
              "flex flex-col items-center gap-2 rounded-[var(--radius-lg)] p-4 text-center transition-all min-h-[5.5rem]",
              "border-2 focus-visible:ring-2 focus-visible:ring-[var(--ring)] focus-visible:outline-none",
              selected
                ? "scale-[1.03] shadow-[var(--shadow-card)]"
                : "border-[var(--border)] hover:border-[var(--muted-foreground)] hover:bg-[var(--muted)]"
            )}
            style={selected ? { borderColor: opt.color, backgroundColor: opt.bg } : undefined}
          >
            <Icon className="h-6 w-6" style={{ color: opt.color }} aria-hidden="true" />
            <div>
              <span className={cn("text-xs font-bold block", selected ? "" : "text-[var(--foreground)]")}
                style={selected ? { color: opt.color } : undefined}
              >
                {opt.label}
              </span>
              <span className="text-[10px] text-[var(--muted-foreground)]">{opt.desc}</span>
            </div>
          </button>
        );
      })}
    </div>
  );
}
