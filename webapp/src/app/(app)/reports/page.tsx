import type { Metadata } from "next";
import { ReportFeed } from "@/features/reports/components/ReportFeed";

export const metadata: Metadata = { title: "Reportes" };

export default function ReportsPage() {
  return (
    <div className="mx-auto max-w-xl px-4 py-6">
      <div className="mb-6">
        <h1 className="text-2xl font-black tracking-tight">
          📝 Reportes en vivo
        </h1>
        <p className="mt-1 text-sm text-[var(--muted-foreground)]">
          Actualizados en tiempo real por la comunidad 🇵🇦
        </p>
      </div>
      <ReportFeed />
    </div>
  );
}
