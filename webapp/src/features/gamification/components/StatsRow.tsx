interface Stat {
  emoji: string;
  label: string;
  value: string | number;
}

interface Props {
  stats: Stat[];
}

export function StatsRow({ stats }: Props) {
  return (
    <div className="grid grid-cols-3 gap-3">
      {stats.map((s) => (
        <div
          key={s.label}
          className="flex flex-col items-center gap-1 rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--card)] p-3 text-center"
        >
          <span className="text-2xl">{s.emoji}</span>
          <span className="text-lg font-black tracking-tight">{s.value}</span>
          <span className="text-[10px] font-medium text-[var(--muted-foreground)]">{s.label}</span>
        </div>
      ))}
    </div>
  );
}
