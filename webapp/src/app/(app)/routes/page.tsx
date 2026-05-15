import type { Metadata } from "next";
import { Suspense } from "react";
import { RoutePlanner } from "@/features/routes/components/RoutePlanner";

export const metadata: Metadata = { title: "Planificar Ruta" };

function RouteSkeleton() {
  return (
    <div className="space-y-4 animate-pulse">
      <div className="metro-card h-40 bg-[var(--muted)]" />
      <div className="metro-card h-20 bg-[var(--muted)]" />
    </div>
  );
}

export default function RoutesPage() {
  return (
    <div className="mx-auto max-w-xl px-4 py-6">
      <div className="mb-6">
        <h1 className="text-2xl font-black tracking-tight">🧭 Planificar viaje</h1>
        <p className="mt-1 text-sm text-[var(--muted-foreground)]">
          Calcula ruta, tiempo y transbordos en tiempo real
        </p>
      </div>
      <Suspense fallback={<RouteSkeleton />}>
        <RoutePlanner />
      </Suspense>
    </div>
  );
}
