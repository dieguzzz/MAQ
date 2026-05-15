import type { BadgeEntry } from "../services/user-profile.service";
import { cn } from "@/lib/utils/cn";

interface Props {
  badges: BadgeEntry[];
}

export function BadgeGrid({ badges }: Props) {
  if (badges.length === 0) {
    return (
      <div className="py-6 text-center text-sm text-[var(--muted-foreground)]">
        <p className="text-3xl mb-2">🏅</p>
        <p>Aún no tienes insignias. ¡Empieza a reportar!</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-3 gap-3 sm:grid-cols-4">
      {badges.map((badge, i) => (
        <div
          key={`${badge.type}-${i}`}
          className={cn(
            "flex flex-col items-center gap-1.5 rounded-[var(--radius-lg)] border-2 border-[var(--border)] p-3 text-center",
            "bg-gradient-to-b from-[var(--card)] to-amber-50 transition-all hover:scale-105 hover:shadow-md"
          )}
          title={badge.descripcion}
        >
          <span className="text-3xl leading-none">{badge.icono}</span>
          <span className="text-[10px] font-bold leading-tight">{badge.nombre}</span>
          {badge.desbloqueadoEn && (
            <span className="text-[9px] text-[var(--muted-foreground)]">
              {badge.desbloqueadoEn.toLocaleDateString("es-PA", { month: "short", day: "numeric" })}
            </span>
          )}
        </div>
      ))}
    </div>
  );
}
