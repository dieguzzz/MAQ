"use client";

import Image from "next/image";
import { useLeaderboard } from "../hooks/useUserProfile";
import { useAuthStore } from "@/stores/auth-store";
import { LevelBadge } from "./LevelBadge";
import { cn } from "@/lib/utils/cn";
import type { UserProfile } from "../services/user-profile.service";

const PODIUM_STYLES: Record<number, { ring: string; bg: string; text: string }> = {
  1: { ring: "ring-amber-400", bg: "bg-amber-50", text: "text-amber-600" },
  2: { ring: "ring-gray-400", bg: "bg-gray-50", text: "text-gray-500" },
  3: { ring: "ring-orange-400", bg: "bg-orange-50", text: "text-orange-500" },
};

function PodiumCard({ user, position }: { user: UserProfile; position: number }) {
  const style = PODIUM_STYLES[position]!;
  const medals = ["🥇", "🥈", "🥉"];

  return (
    <div className={cn(
      "flex flex-col items-center gap-1.5 rounded-[var(--radius-lg)] p-3",
      style.bg,
      position === 1 ? "order-2 -mt-2" : position === 2 ? "order-1" : "order-3"
    )}>
      <span className="text-2xl">{medals[position - 1]}</span>
      <div className={cn("relative rounded-full ring-2", style.ring)}>
        {user.fotoUrl ? (
          <Image
            src={user.fotoUrl}
            alt={user.nombre}
            width={position === 1 ? 56 : 44}
            height={position === 1 ? 56 : 44}
            className="rounded-full object-cover"
          />
        ) : (
          <div className={cn(
            "flex items-center justify-center rounded-full bg-[var(--brand-primary)] font-black text-white",
            position === 1 ? "h-14 w-14 text-xl" : "h-11 w-11 text-base"
          )}>
            {user.nombre.charAt(0).toUpperCase()}
          </div>
        )}
      </div>
      <p className="text-xs font-bold truncate max-w-[5rem]">{user.nombre.split(" ")[0]}</p>
      <p className={cn("text-sm font-black", style.text)}>
        {user.gamification.puntos.toLocaleString("es-PA")}
      </p>
    </div>
  );
}

function LeaderboardRow({
  user,
  position,
  isCurrentUser,
}: {
  user: UserProfile;
  position: number;
  isCurrentUser: boolean;
}) {
  return (
    <div
      className={cn(
        "flex items-center gap-3 rounded-[var(--radius-lg)] px-3 py-2.5 transition-colors",
        isCurrentUser
          ? "bg-[var(--brand-primary)]/5 ring-2 ring-[var(--brand-primary)]/20"
          : "bg-[var(--card)] hover:bg-[var(--muted)]"
      )}
    >
      <div className="w-7 text-center text-sm font-bold text-[var(--muted-foreground)]">
        {position}
      </div>

      <div className="relative shrink-0">
        {user.fotoUrl ? (
          <Image
            src={user.fotoUrl}
            alt={user.nombre}
            width={36}
            height={36}
            className="rounded-full object-cover"
          />
        ) : (
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[var(--brand-primary)] text-sm font-black text-white">
            {user.nombre.charAt(0).toUpperCase()}
          </div>
        )}
        <LevelBadge
          level={user.gamification.nivel}
          size="sm"
          className="absolute -bottom-1 -right-1 h-4 w-4 text-[8px] ring-1 ring-[var(--card)]"
        />
      </div>

      <div className="min-w-0 flex-1">
        <p className={cn("truncate text-sm font-bold", isCurrentUser && "text-[var(--brand-primary)]")}>
          {user.nombre}
          {isCurrentUser && " (tú)"}
        </p>
        <p className="text-xs text-[var(--muted-foreground)]">
          {user.reportesCount} reportes · 🔥 {user.gamification.streak}d
        </p>
      </div>

      <div className="shrink-0 text-right">
        <p className="text-sm font-black">{user.gamification.puntos.toLocaleString("es-PA")}</p>
        <p className="text-[10px] text-[var(--muted-foreground)]">pts</p>
      </div>
    </div>
  );
}

function LeaderboardSkeleton() {
  return (
    <div className="space-y-2 animate-pulse">
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} className="h-14 rounded-[var(--radius-lg)] bg-[var(--muted)]" />
      ))}
    </div>
  );
}

export function LeaderboardView() {
  const { users, loading } = useLeaderboard(20);
  const currentUser = useAuthStore((s) => s.user);

  if (loading) return <LeaderboardSkeleton />;

  if (users.length === 0) {
    return (
      <div className="metro-card py-10 text-center">
        <p className="text-5xl mb-3">🏆</p>
        <p className="font-bold">Sin datos todavía</p>
        <p className="text-sm text-[var(--muted-foreground)] mt-1">
          ¡Sé el primero en reportar y llega al top!
        </p>
      </div>
    );
  }

  const top3 = users.slice(0, 3);
  const rest = users.slice(3);

  return (
    <div className="space-y-3">
      {/* Podium */}
      {top3.length >= 3 && (
        <div className="flex items-end justify-center gap-2 pb-2">
          {top3.map((u, i) => (
            <PodiumCard key={u.uid} user={u} position={i + 1} />
          ))}
        </div>
      )}

      {/* Remaining rows */}
      <div className="space-y-1.5">
        {(top3.length < 3 ? users : rest).map((u, i) => (
          <LeaderboardRow
            key={u.uid}
            user={u}
            position={top3.length < 3 ? i + 1 : i + 4}
            isCurrentUser={u.uid === currentUser?.uid}
          />
        ))}
      </div>
    </div>
  );
}
