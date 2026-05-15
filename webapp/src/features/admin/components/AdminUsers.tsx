"use client";

import { useAdminUsers } from "../hooks/useAdminData";
import { Search } from "lucide-react";
import Image from "next/image";
import type { UserProfile } from "@/features/gamification/services/user-profile.service";

function UserRow({ user, rank }: { user: UserProfile; rank: number }) {
  return (
    <div className="flex items-center gap-3 rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--card)] px-3 py-2.5">
      <span className="w-6 shrink-0 text-center text-xs font-bold text-[var(--muted-foreground)]">
        {rank}
      </span>

      {user.fotoUrl ? (
        <Image
          src={user.fotoUrl}
          alt={user.nombre}
          width={32}
          height={32}
          className="rounded-full object-cover"
        />
      ) : (
        <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-[var(--brand-primary)] text-xs font-black text-white">
          {user.nombre.charAt(0).toUpperCase()}
        </div>
      )}

      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-semibold">{user.nombre}</p>
        <p className="truncate text-xs text-[var(--muted-foreground)]">{user.email}</p>
      </div>

      <div className="shrink-0 text-right">
        <p className="text-sm font-black">{user.gamification.puntos.toLocaleString("es-PA")}</p>
        <p className="text-[10px] text-[var(--muted-foreground)]">
          Nv.{user.gamification.nivel} · {user.reportesCount} rep.
        </p>
      </div>
    </div>
  );
}

export function AdminUsers() {
  const { users, loading, search, searching, runSearch } = useAdminUsers();

  return (
    <div className="space-y-3">
      {/* Search */}
      <div className="flex items-center gap-2 rounded-[var(--radius-lg)] border-2 border-[var(--border)] bg-[var(--card)] px-3 py-2 focus-within:border-[var(--brand-primary)] transition-colors">
        <Search className="h-4 w-4 shrink-0 text-[var(--muted-foreground)]" />
        <input
          type="text"
          value={search}
          onChange={(e) => runSearch(e.target.value)}
          placeholder="Buscar por nombre o email…"
          className="flex-1 bg-transparent text-sm outline-none placeholder:text-[var(--muted-foreground)]"
        />
        {searching && (
          <span className="h-4 w-4 animate-spin rounded-full border-2 border-[var(--border)] border-t-[var(--brand-primary)]" />
        )}
      </div>

      {/* List */}
      {loading ? (
        <div className="space-y-2 animate-pulse">
          {Array.from({ length: 8 }).map((_, i) => (
            <div key={i} className="h-14 rounded-[var(--radius-lg)] bg-[var(--muted)]" />
          ))}
        </div>
      ) : (
        <div className="space-y-2">
          {users.map((u, i) => (
            <UserRow key={u.uid} user={u} rank={i + 1} />
          ))}
          {users.length === 0 && (
            <p className="py-6 text-center text-sm text-[var(--muted-foreground)]">
              Sin resultados para &ldquo;{search}&rdquo;
            </p>
          )}
        </div>
      )}
    </div>
  );
}
