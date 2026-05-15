import type { Metadata } from "next";
import { AdminUsers } from "@/features/admin/components/AdminUsers";

export const metadata: Metadata = { title: "Admin — Usuarios" };

export default function AdminUsersPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-black">👥 Usuarios</h1>
        <p className="text-sm text-[var(--muted-foreground)] mt-1">
          Top colaboradores y búsqueda de usuarios
        </p>
      </div>
      <AdminUsers />
    </div>
  );
}
