"use client";

import { cn } from "@/lib/utils/cn";

const ISSUES = [
  { value: "ac",        emoji: "❄️",  label: "A/C" },
  { value: "escalator", emoji: "📶",  label: "Escalera" },
  { value: "elevator",  emoji: "🔼",  label: "Ascensor" },
  { value: "atm",       emoji: "🏧",  label: "ATM" },
  { value: "recharge",  emoji: "💳",  label: "Recarga" },
  { value: "bathroom",  emoji: "🚻",  label: "Baños" },
  { value: "lights",    emoji: "💡",  label: "Luces" },
] as const;

interface Props {
  selected: string[];
  onChange: (issues: string[]) => void;
}

export function IssueSelector({ selected, onChange }: Props) {
  const toggle = (value: string) => {
    onChange(
      selected.includes(value)
        ? selected.filter((v) => v !== value)
        : [...selected, value]
    );
  };

  return (
    <div className="flex flex-wrap gap-2" role="group" aria-label="Problemas en la estación">
      {ISSUES.map((issue) => {
        const active = selected.includes(issue.value);
        return (
          <button
            key={issue.value}
            type="button"
            aria-pressed={active}
            onClick={() => toggle(issue.value)}
            className={cn(
              "flex items-center gap-1.5 rounded-[var(--radius-full)] px-3 py-1.5",
              "text-xs font-semibold border-2 transition-all",
              "focus-visible:ring-2 focus-visible:ring-[var(--ring)] focus-visible:outline-none",
              active
                ? "border-[var(--destructive)] bg-red-50 text-[var(--destructive)]"
                : "border-[var(--border)] text-[var(--muted-foreground)] hover:border-[var(--muted-foreground)]"
            )}
          >
            <span>{issue.emoji}</span>
            <span>{issue.label}</span>
          </button>
        );
      })}
    </div>
  );
}
