import type { Metadata } from "next";
import { AdminReports } from "@/features/admin/components/AdminReports";

export const metadata: Metadata = { title: "Admin — Reportes" };

export default function AdminReportsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-black">📝 Reportes</h1>
        <p className="text-sm text-[var(--muted-foreground)] mt-1">
          Modera reportes de usuarios en tiempo real
        </p>
      </div>
      <AdminReports />
    </div>
  );
}
