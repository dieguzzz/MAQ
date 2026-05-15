"use client";

import { useAdminStats } from "../hooks/useAdminData";
import { StatCard } from "./StatCard";

export function AdminOverview() {
  const stats = useAdminStats();

  if (!stats) {
    return (
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-3 animate-pulse">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="h-24 rounded-[var(--radius-xl)] bg-[var(--muted)]" />
        ))}
      </div>
    );
  }

  return (
    <div className="grid grid-cols-2 gap-3 lg:grid-cols-3">
      <StatCard
        emoji="👥"
        label="Usuarios totales"
        value={stats.totalUsers.toLocaleString("es-PA")}
        color="#0066CC"
      />
      <StatCard
        emoji="📝"
        label="Reportes activos"
        value={stats.activeReports.toLocaleString("es-PA")}
        color="#009933"
      />
      <StatCard
        emoji="📅"
        label="Reportes hoy"
        value={stats.reportsToday.toLocaleString("es-PA")}
        color="#f59e0b"
      />
      <StatCard
        emoji="🚫"
        label="Estaciones cerradas"
        value={stats.stationsClosed}
        color={stats.stationsClosed > 0 ? "#ef4444" : "#64748b"}
      />
      <StatCard
        emoji="⚠️"
        label="Con congestión"
        value={stats.stationsWithIssues}
        color={stats.stationsWithIssues > 0 ? "#f59e0b" : "#64748b"}
      />
      <StatCard
        emoji="🔄"
        label="Actualización"
        value="En vivo"
        sub="Cada 30s"
        color="#8b5cf6"
      />
    </div>
  );
}
