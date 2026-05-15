import type { Metadata } from "next";
import { AdminOverview } from "@/features/admin/components/AdminOverview";

export const metadata: Metadata = { title: "Admin — Overview" };

export default function AdminPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-black">📊 Overview</h1>
        <p className="text-sm text-[var(--muted-foreground)] mt-1">
          Métricas en tiempo real del Metro de Panamá
        </p>
      </div>
      <AdminOverview />
    </div>
  );
}
