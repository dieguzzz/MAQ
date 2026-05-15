import type { Metadata } from "next";

export const metadata: Metadata = { title: "Reportar" };

export default function ReportsPage() {
  return (
    <div className="mx-auto max-w-xl p-6">
      <h1 className="mb-4 text-2xl font-bold">Reportar</h1>
      <p className="text-[var(--muted-foreground)]">
        Selecciona una estación en el mapa o usa el formulario para reportar.
      </p>
    </div>
  );
}
