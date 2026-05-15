import type { Metadata } from "next";

export const metadata: Metadata = { title: "Sin conexión" };

export default function OfflinePage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-6 p-8 text-center">
      <div className="text-7xl">🚇</div>
      <div>
        <h1 className="text-2xl font-black">Sin conexión</h1>
        <p className="mt-2 text-[var(--muted-foreground)]">
          MetroPTY necesita internet para mostrar datos en tiempo real.
        </p>
        <p className="mt-1 text-sm text-[var(--muted-foreground)]">
          Revisa tu conexión y vuelve a intentarlo.
        </p>
      </div>
      <a
        href="/map"
        className="rounded-[var(--radius-full)] bg-[var(--brand-primary)] px-6 py-2.5 text-sm font-bold text-white shadow transition-opacity hover:opacity-90"
      >
        Reintentar
      </a>
    </div>
  );
}
