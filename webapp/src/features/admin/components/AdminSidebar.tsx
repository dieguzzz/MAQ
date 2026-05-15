"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { LayoutDashboard, MapPin, FileText, Users, LogOut } from "lucide-react";
import { authService } from "@/features/auth/services/auth.service";
import { cn } from "@/lib/utils/cn";

const NAV = [
  { href: "/admin",           label: "Overview",    Icon: LayoutDashboard },
  { href: "/admin/stations",  label: "Estaciones",  Icon: MapPin },
  { href: "/admin/reports",   label: "Reportes",    Icon: FileText },
  { href: "/admin/users",     label: "Usuarios",    Icon: Users },
];

export function AdminSidebar() {
  const pathname = usePathname();

  return (
    <aside className="flex w-56 shrink-0 flex-col border-r border-[var(--border)] bg-[var(--card)]">
      {/* Brand */}
      <div className="flex items-center gap-2 border-b border-[var(--border)] px-4 py-4">
        <span className="text-2xl">🚇</span>
        <div>
          <p className="font-black text-sm">MetroPTY</p>
          <p className="text-[10px] font-semibold uppercase tracking-wider text-[var(--muted-foreground)]">
            Admin
          </p>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 space-y-1 p-3">
        {NAV.map(({ href, label, Icon }) => {
          const active = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              className={cn(
                "flex items-center gap-2.5 rounded-[var(--radius-md)] px-3 py-2 text-sm font-semibold transition-colors",
                active
                  ? "bg-[var(--brand-primary)] text-white"
                  : "text-[var(--muted-foreground)] hover:bg-[var(--muted)] hover:text-[var(--foreground)]"
              )}
            >
              <Icon className="h-4 w-4 shrink-0" />
              {label}
            </Link>
          );
        })}
      </nav>

      {/* Sign out */}
      <div className="border-t border-[var(--border)] p-3">
        <Link
          href="/map"
          className="mb-1 flex items-center gap-2.5 rounded-[var(--radius-md)] px-3 py-2 text-sm font-semibold text-[var(--muted-foreground)] hover:bg-[var(--muted)] hover:text-[var(--foreground)] transition-colors"
        >
          ← Volver al mapa
        </Link>
        <button
          onClick={() => authService.signOut()}
          className="flex w-full items-center gap-2.5 rounded-[var(--radius-md)] px-3 py-2 text-sm font-semibold text-[var(--muted-foreground)] hover:bg-red-50 hover:text-red-600 transition-colors"
        >
          <LogOut className="h-4 w-4 shrink-0" />
          Cerrar sesión
        </button>
      </div>
    </aside>
  );
}
