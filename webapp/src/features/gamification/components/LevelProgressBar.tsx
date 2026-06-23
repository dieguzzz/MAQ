"use client";

import { getLevelName, getLevelProgress, getPointsToNextLevel } from "../services/level.service";

interface Props {
  points: number;
  level: number;
}

export function LevelProgressBar({ points, level }: Props) {
  const progress = getLevelProgress(points, level);
  const pct = Math.round(progress * 100);
  const toNext = getPointsToNextLevel(points, level);
  const name = getLevelName(level);

  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between text-sm">
        <span className="font-bold">{name}</span>
        <span className="text-[var(--muted-foreground)]">Nivel {level}</span>
      </div>

      <div className="relative h-4 w-full overflow-hidden rounded-full bg-[var(--muted)]">
        <div
          className="h-full rounded-full bg-gradient-to-r from-[var(--brand-primary)] to-blue-400 transition-all duration-700"
          style={{ width: `${pct}%` }}
        />
        {/* shine */}
        <div className="absolute inset-y-0 left-0 w-full rounded-full bg-gradient-to-b from-white/25 to-transparent" />
      </div>

      <div className="flex items-center justify-between text-xs text-[var(--muted-foreground)]">
        <span>{points.toLocaleString("es-PA")} pts</span>
        {level < 50 ? (
          <span>{toNext.toLocaleString("es-PA")} pts para nivel {level + 1}</span>
        ) : (
          <span>🏆 Nivel máximo</span>
        )}
      </div>
    </div>
  );
}
