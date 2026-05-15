"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Map, FileText, Navigation, Trophy, User, Shield } from "lucide-react";
import { cn } from "@/lib/utils/cn";
import { ThemeToggle } from "./ThemeToggle";
import { useAuthStore } from "@/stores/auth-store";

const NAV_ITEMS = [
  { href: "/map", label: "Mapa", icon: Map },
  { href: "/reports", label: "Reportar", icon: FileText },
  { href: "/routes", label: "Rutas", icon: Navigation },
  { href: "/leaderboards", label: "Ranking", icon: Trophy },
  { href: "/profile", label: "Perfil", icon: User },
];

export function Navbar() {
  const pathname = usePathname();
  const { user } = useAuthStore();

  return (
    <header className="sticky top-0 z-50 border-b border-[var(--border)] bg-[var(--background)]/80 backdrop-blur-md">
      <div className="mx-auto flex h-14 max-w-screen-xl items-center justify-between px-4">
        <Link href="/map" className="flex items-center gap-2 font-bold text-[var(--brand-primary)]">
          <span className="text-xl">🚇</span>
          <span className="hidden sm:block">MetroPTY</span>
        </Link>

        <nav className="flex items-center gap-1">
          {NAV_ITEMS.map(({ href, label, icon: Icon }) => (
            <Link
              key={href}
              href={href}
              className={cn(
                "flex items-center gap-1.5 rounded-[var(--radius)] px-3 py-1.5 text-sm transition-colors",
                pathname.startsWith(href)
                  ? "bg-[var(--brand-primary)] text-white"
                  : "text-[var(--muted-foreground)] hover:bg-[var(--muted)] hover:text-[var(--foreground)]"
              )}
            >
              <Icon className="h-4 w-4" />
              <span className="hidden md:block">{label}</span>
            </Link>
          ))}

          {user && (
            <Link
              href="/admin"
              className={cn(
                "ml-1 flex items-center gap-1.5 rounded-[var(--radius)] px-3 py-1.5 text-sm transition-colors",
                pathname.startsWith("/admin")
                  ? "bg-[var(--brand-primary)] text-white"
                  : "text-[var(--muted-foreground)] hover:bg-[var(--muted)] hover:text-[var(--foreground)]"
              )}
              aria-label="Panel Admin"
            >
              <Shield className="h-4 w-4" />
              <span className="hidden md:block">Admin</span>
            </Link>
          )}

          <ThemeToggle />
        </nav>
      </div>
    </header>
  );
}
