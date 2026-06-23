"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Map, FileText, Navigation, Trophy, User } from "lucide-react";
import { cn } from "@/lib/utils/cn";
import { ThemeToggle } from "./ThemeToggle";

const NAV_ITEMS = [
  { href: "/map", label: "Mapa", icon: Map },
  { href: "/reports", label: "Reportar", icon: FileText },
  { href: "/routes", label: "Rutas", icon: Navigation },
  { href: "/leaderboards", label: "Ranking", icon: Trophy },
  { href: "/profile", label: "Perfil", icon: User },
];

export function Navbar() {
  const pathname = usePathname();
  const isMap = pathname.startsWith("/map");

  return (
    <>
      {/* ── Desktop top bar ── */}
      <header className="sticky top-0 z-50 hidden md:block border-b border-[var(--border)] bg-[var(--background)]/80 backdrop-blur-md">
        <div className="mx-auto flex h-14 max-w-screen-xl items-center justify-between px-4">
          <Link href="/map" className="flex items-center gap-2 font-bold text-[var(--brand-primary)]" aria-label="MetroPTY — Inicio">
            <span className="text-xl" aria-hidden="true">🚇</span>
            <span>MetroPTY</span>
          </Link>

          <nav aria-label="Navegación principal" className="flex items-center gap-1">
            {NAV_ITEMS.map(({ href, label, icon: Icon }) => {
              const active = pathname.startsWith(href);
              return (
                <Link
                  key={href}
                  href={href}
                  aria-label={label}
                  aria-current={active ? "page" : undefined}
                  className={cn(
                    "relative flex items-center gap-1.5 rounded-[var(--radius)] px-3 py-1.5 text-sm transition-colors",
                    active
                      ? "bg-[var(--brand-primary)]/10 text-[var(--brand-primary)] font-semibold"
                      : "text-[var(--muted-foreground)] hover:bg-[var(--muted)] hover:text-[var(--foreground)]"
                  )}
                >
                  <Icon className="h-4 w-4" aria-hidden="true" />
                  <span>{label}</span>
                  {active && (
                    <span className="absolute bottom-0 left-3 right-3 h-0.5 rounded-full bg-[var(--brand-primary)]" />
                  )}
                </Link>
              );
            })}

            <ThemeToggle />
          </nav>
        </div>
      </header>

      {/* ── Mobile top bar (minimal) ── */}
      <header className={cn(
        "sticky top-0 z-50 md:hidden flex items-center justify-between h-12 px-4",
        isMap
          ? "bg-transparent pointer-events-none [&>*]:pointer-events-auto"
          : "border-b border-[var(--border)] bg-[var(--background)]/80 backdrop-blur-md"
      )}>
        <Link href="/map" className="flex items-center gap-2 font-bold text-[var(--brand-primary)]" aria-label="MetroPTY — Inicio">
          <span className="text-xl" aria-hidden="true">🚇</span>
          <span className="text-sm font-bold">MetroPTY</span>
        </Link>
        <ThemeToggle />
      </header>

      {/* ── Mobile bottom tab bar ── */}
      <nav
        aria-label="Navegación principal"
        className={cn(
          "fixed bottom-0 left-0 right-0 z-50 md:hidden",
          "border-t border-[var(--border)] pb-[env(safe-area-inset-bottom)]",
          isMap
            ? "bg-[var(--background)]/70 backdrop-blur-xl"
            : "bg-[var(--background)]"
        )}
      >
        <div className="flex h-[var(--bottom-nav-height)] items-center justify-around px-2">
          {NAV_ITEMS.map(({ href, label, icon: Icon }) => {
            const active = pathname.startsWith(href);
            return (
              <Link
                key={href}
                href={href}
                aria-label={label}
                aria-current={active ? "page" : undefined}
                className={cn(
                  "flex flex-col items-center justify-center gap-0.5 min-w-[3rem] py-1.5 rounded-[var(--radius)] transition-colors",
                  active
                    ? "text-[var(--brand-primary)]"
                    : "text-[var(--muted-foreground)]"
                )}
              >
                <span className={cn(
                  "flex items-center justify-center h-8 w-8 rounded-[var(--radius-full)] transition-[background-color] duration-[var(--transition-fast)]",
                  active && "bg-[var(--brand-primary)]/10"
                )}>
                  <Icon className="h-5 w-5" aria-hidden="true" />
                </span>
                <span className="text-[0.625rem] font-medium leading-none">{label}</span>
              </Link>
            );
          })}
        </div>
      </nav>
    </>
  );
}
