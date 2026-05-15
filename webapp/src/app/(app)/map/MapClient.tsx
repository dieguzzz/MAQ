"use client";

import dynamic from "next/dynamic";

const MapView = dynamic(
  () => import("@/components/map/MapView").then((m) => m.MapView),
  {
    ssr: false,
    loading: () => (
      <div className="flex h-[calc(100vh-3.5rem)] items-center justify-center bg-[var(--background)]">
        <div className="flex flex-col items-center gap-3">
          <div className="h-10 w-10 animate-spin rounded-full border-4 border-[var(--border)] border-t-[var(--brand-primary)]" />
          <p className="text-sm text-[var(--muted-foreground)]">Cargando mapa…</p>
        </div>
      </div>
    ),
  }
);

export function MapClient() {
  return <MapView />;
}
