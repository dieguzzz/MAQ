import type { Metadata } from "next";
import { LeaderboardView } from "@/features/gamification/components/LeaderboardView";

export const metadata: Metadata = { title: "Ranking" };

export default function LeaderboardsPage() {
  return (
    <div className="mx-auto max-w-xl px-4 py-6">
      <div className="mb-6">
        <h1 className="text-2xl font-black tracking-tight">🏆 Ranking</h1>
        <p className="mt-1 text-sm text-[var(--muted-foreground)]">
          Los mejores colaboradores del Metro de Panamá 🇵🇦
        </p>
      </div>
      <LeaderboardView />
    </div>
  );
}
