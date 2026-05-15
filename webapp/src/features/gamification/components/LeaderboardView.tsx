"use client";

import Image from "next/image";
import { useLeaderboard } from "../hooks/useUserProfile";
import { useAuthStore } from "@/stores/auth-store";
import { LevelBadge } from "./LevelBadge";
import { cn } from "@/lib/utils/cn";
import type { UserProfile } from "../services/user-profile.service";

const POSITION_EMOJIS: Record<number, string> = { 1: "🥇", 2: "🥈", 3: "🥉" };

function LeaderboardRow({
  user,
  position,
  isCurrentUser,
}: {
  user: UserProfile;
  position: number;
  isCurrentUser: boolean;
}) {
  const posEmoji = POSITION_EMOJIS[position] ?? null;

  return (
    <div
      className={cn(
        "flex items-center gap-3 rounded-[var(--radius-lg)] px-3 py-2.5 transition-colors",
        isCurrentUser
          ? "bg-blue-50 border-2 border-[var(--brand-primary)]"
          : "border border-[var(--border)] bg-[var(--card)] hover:bg-[var(--muted)]"
      )}
    >
      {/* Position */}
      <div className="w-8 text-center">
        {posEmoji ? (
          <span className="text-xl">{posEmoji}</span>
        ) : (
          <span className="text-sm font-bold text-[var(--muted-foreground)]">
            #{position}
          </span>
        )}
      </div>

      {/* Avatar */}
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
          className="absolute -bottom-1 -right-1 h-4 w-4 text-[8px] ring-1 ring-white"
        />
      </div>

      {/* Info */}
      <div className="min-w-0 flex-1">
        <p className={cn("truncate text-sm font-bold", isCurrentUser && "text-[var(--brand-primary)]")}>
          {user.nombre}
          {isCurrentUser && " (tú)"}
        </p>
        <p className="text-xs text-[var(--muted-foreground)]">
          {user.reportesCount} reportes · 🔥 {user.gamification.streak}d
        </p>
      </div>

      {/* Points */}
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

  return (
    <div className="space-y-2">
      {/* Top 3 podium hint */}
      {users.length >= 3 && (
        <div className="metro-card mb-4 bg-gradient-to-br from-amber-50 to-white text-center py-4">
          <p className="text-3xl font-black tracking-tight">
            {users[0]?.nombre.split(" ")[0] ?? ""}
          </p>
          <p className="text-sm text-[var(--muted-foreground)]">lidera el Metro de Panamá 🇵🇦</p>
          <p className="mt-1 text-2xl font-black text-amber-600">
            {users[0]?.gamification.puntos.toLocaleString("es-PA")} pts
          </p>
        </div>
      )}

      {users.map((u, i) => (
        <LeaderboardRow
          key={u.uid}
          user={u}
          position={i + 1}
          isCurrentUser={u.uid === currentUser?.uid}
        />
      ))}
    </div>
  );
}
