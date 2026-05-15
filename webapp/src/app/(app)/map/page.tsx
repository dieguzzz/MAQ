import type { Metadata } from "next";
import dynamic from "next/dynamic";

export const metadata: Metadata = { title: "Mapa en Tiempo Real" };

// Load MapView only on client — Google Maps SDK is browser-only
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

export default function MapPage() {
  return (
    <div className="flex h-[calc(100vh-3.5rem)]">
      <MapView />
    </div>
  );
}
