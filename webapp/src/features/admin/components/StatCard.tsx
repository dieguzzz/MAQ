import { cn } from "@/lib/utils/cn";
import type { LucideIcon } from "lucide-react";

interface Props {
  emoji?: string;
  Icon?: LucideIcon;
  label: string;
  value: string | number;
  sub?: string;
  color?: string;
  className?: string;
}

export function StatCard({ emoji, Icon, label, value, sub, color = "var(--brand-primary)", className }: Props) {
  return (
    <div className={cn(
      "metro-card flex items-start gap-4 bg-gradient-to-br from-[var(--card)] to-[var(--muted)]",
      className
    )}>
      <div
        className="flex h-12 w-12 shrink-0 items-center justify-center rounded-[var(--radius-md)] text-white"
        style={{ backgroundColor: color }}
      >
        {emoji ? (
          <span className="text-2xl">{emoji}</span>
        ) : Icon ? (
          <Icon className="h-6 w-6" />
        ) : null}
      </div>
      <div className="min-w-0">
        <p className="text-sm text-[var(--muted-foreground)]">{label}</p>
        <p className="text-2xl font-black tracking-tight">{value}</p>
        {sub && <p className="text-xs text-[var(--muted-foreground)] mt-0.5">{sub}</p>}
      </div>
    </div>
  );
}
