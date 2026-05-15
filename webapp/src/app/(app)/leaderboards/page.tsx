import type { Metadata } from "next";

export const metadata: Metadata = { title: "Ranking" };

export default function LeaderboardsPage() {
  return (
    <div className="mx-auto max-w-xl p-6">
      <h1 className="mb-4 text-2xl font-bold">Ranking de Colaboradores</h1>
      <p className="text-[var(--muted-foreground)]">Los usuarios más activos esta semana.</p>
    </div>
  );
}
