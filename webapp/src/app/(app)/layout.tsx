import { Navbar } from "@/components/shared/Navbar";
import type { ReactNode } from "react";

export const dynamic = "force-dynamic";

export default function AppLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col">
      <Navbar />
      <main id="main-content" className="flex-1 pb-[var(--bottom-nav-height)] md:pb-0" tabIndex={-1}>
        {children}
      </main>
    </div>
  );
}
