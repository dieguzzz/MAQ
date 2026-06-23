"use client";

import { Button } from "@/components/ui/button";

interface Props {
  points: number;
  onClose: () => void;
}

export function ReportSuccess({ points, onClose }: Props) {
  return (
    <div className="flex flex-col items-center gap-5 py-6 text-center animate-bounce-in">
      <div className="flex h-20 w-20 items-center justify-center rounded-full bg-[var(--status-normal-bg)]">
        <svg className="h-10 w-10 text-[var(--status-normal)]" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={3} strokeLinecap="round" strokeLinejoin="round">
          <polyline points="20 6 9 17 4 12" />
        </svg>
      </div>
      <div>
        <h3 className="text-xl font-black">¡Reporte enviado!</h3>
        <p className="mt-1 text-sm text-[var(--muted-foreground)]">
          Tu reporte ayuda a miles de usuarios en Panamá.
        </p>
      </div>
      <div className="inline-flex items-center gap-2 rounded-[var(--radius-full)] bg-[var(--brand-accent)]/15 px-5 py-2.5 border border-[var(--brand-accent)]/30 animate-bounce-in" style={{ animationDelay: "200ms" }}>
        <span className="text-xl font-black text-[var(--brand-accent-hover)]">+{points} XP</span>
      </div>
      <Button variant="metro" className="mt-1 w-full" onClick={onClose}>
        Perfecto
      </Button>
    </div>
  );
}
