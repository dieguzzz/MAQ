"use client";

import Image from "next/image";
import { useAuthStore } from "@/stores/auth-store";
import { useUserProfile } from "../hooks/useUserProfile";
import { LevelBadge } from "./LevelBadge";
import { LevelProgressBar } from "./LevelProgressBar";
import { BadgeGrid } from "./BadgeGrid";
import { StatsRow } from "./StatsRow";
import { authService } from "@/features/auth/services/auth.service";
import { Button } from "@/components/ui/button";
import { LINE_KEY_COLORS } from "@/config/metro-lines";
import { LogOut, Flame } from "lucide-react";
import { getLevelProgress } from "../services/level.service";

function ProfileSkeleton() {
  return (
    <div className="space-y-4 animate-pulse">
      <div className="metro-card h-32 bg-[var(--muted)]" />
      <div className="metro-card h-24 bg-[var(--muted)]" />
      <div className="metro-card h-40 bg-[var(--muted)]" />
    </div>
  );
}

function NotLoggedIn() {
  return (
    <div className="metro-card py-10 text-center">
      <p className="text-5xl mb-3">🚇</p>
      <h3 className="font-bold mb-1">Inicia sesión</h3>
      <p className="text-sm text-[var(--muted-foreground)]">
        Para ver tu perfil y gamificación necesitas estar conectado.
      </p>
    </div>
  );
}

export function ProfileView() {
  const { user } = useAuthStore();
  const { profile, loading } = useUserProfile();

  if (!user) return <NotLoggedIn />;
  if (loading) return <ProfileSkeleton />;
  if (!profile) return <NotLoggedIn />;

  const g = profile.gamification;
  const progress = getLevelProgress(g.puntos, g.nivel);

  const lineStats = Object.entries(g.puntosPorLinea)
    .filter(([, pts]) => pts > 0)
    .sort(([, a], [, b]) => b - a);

  const stats = [
    { emoji: "📝", label: "Reportes", value: profile.reportesCount.toLocaleString("es-PA") },
    { emoji: "🔥", label: "Racha", value: `${g.streak}d` },
    { emoji: "⭐", label: "Reputación", value: profile.reputacion },
  ];

  return (
    <div className="space-y-4 animate-slide-up">
      {/* Avatar + name card */}
      <div className="metro-card">
        <div className="flex items-center gap-4">
          <div className="relative">
            {profile.fotoUrl ? (
              <Image
                src={profile.fotoUrl}
                alt={profile.nombre}
                width={64}
                height={64}
                className="rounded-full object-cover"
              />
            ) : (
              <div className="flex h-16 w-16 items-center justify-center rounded-full bg-[var(--brand-primary)] text-2xl font-black text-white">
                {profile.nombre.charAt(0).toUpperCase()}
              </div>
            )}
            <LevelBadge
              level={g.nivel}
              size="sm"
              progress={progress}
              className="absolute -bottom-1 -right-1 ring-2 ring-[var(--card)]"
            />
          </div>

          <div className="min-w-0 flex-1">
            <h2 className="truncate text-lg font-black">{profile.nombre}</h2>
            <p className="truncate text-sm text-[var(--muted-foreground)]">{profile.email}</p>
            <div className="flex items-center gap-2 mt-0.5">
              {g.ranking && (
                <span className="text-xs font-semibold text-amber-600">
                  🏆 #{g.ranking}
                </span>
              )}
              {g.streak > 0 && (
                <span className="inline-flex items-center gap-0.5 text-xs font-semibold text-orange-500">
                  <Flame className="h-3 w-3" />
                  {g.streak}d
                </span>
              )}
            </div>
          </div>

          <Button
            variant="ghost"
            size="icon"
            onClick={() => authService.signOut()}
            aria-label="Cerrar sesión"
            className="shrink-0"
          >
            <LogOut className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Level progress */}
      <div className="metro-card">
        <h3 className="mb-3 font-bold">Progreso</h3>
        <LevelProgressBar points={g.puntos} level={g.nivel} />
      </div>

      {/* Stats */}
      <StatsRow stats={stats} />

      {/* Points per line */}
      {lineStats.length > 0 && (
        <div className="metro-card">
          <h3 className="mb-3 font-bold">Puntos por línea</h3>
          <div className="space-y-2">
            {lineStats.map(([linea, pts]) => {
              const color = LINE_KEY_COLORS[linea as keyof typeof LINE_KEY_COLORS] ?? "#64748b";
              const label = linea.replace("linea", "Línea ");
              const maxPts = lineStats[0]?.[1] ?? 1;
              return (
                <div key={linea} className="space-y-1">
                  <div className="flex justify-between text-sm">
                    <span className="font-semibold" style={{ color }}>{label}</span>
                    <span className="text-[var(--muted-foreground)]">{pts.toLocaleString("es-PA")} pts</span>
                  </div>
                  <div className="h-2 w-full overflow-hidden rounded-full bg-[var(--muted)]">
                    <div
                      className="h-full rounded-full transition-all duration-700"
                      style={{ width: `${(pts / maxPts) * 100}%`, backgroundColor: color }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Badges */}
      <div className="metro-card">
        <h3 className="mb-3 font-bold">Insignias ({g.badges.length})</h3>
        <BadgeGrid badges={g.badges} />
      </div>
    </div>
  );
}
