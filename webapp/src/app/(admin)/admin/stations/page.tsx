import type { Metadata } from "next";
import { AdminStations } from "@/features/admin/components/AdminStations";

export const metadata: Metadata = { title: "Admin — Estaciones" };

export default function AdminStationsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-black">📍 Estaciones</h1>
        <p className="text-sm text-[var(--muted-foreground)] mt-1">
          Gestiona el estado de cada estación en tiempo real
        </p>
      </div>
      <AdminStations />
    </div>
  );
}
