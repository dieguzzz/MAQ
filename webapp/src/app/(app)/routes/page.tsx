import type { Metadata } from "next";

export const metadata: Metadata = { title: "Planificar Ruta" };

export default function RoutesPage() {
  return (
    <div className="mx-auto max-w-xl p-6">
      <h1 className="mb-4 text-2xl font-bold">Planificar Ruta</h1>
      <p className="text-[var(--muted-foreground)]">Próximamente: planificador de rutas con ETA en tiempo real.</p>
    </div>
  );
}
