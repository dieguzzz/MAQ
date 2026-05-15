"use client";

import { Button } from "@/components/ui/button";

interface Props {
  points: number;
  onClose: () => void;
}

export function ReportSuccess({ points, onClose }: Props) {
  return (
    <div className="flex flex-col items-center gap-4 py-4 text-center animate-bounce-in">
      <div className="text-6xl">🎉</div>
      <div>
        <h3 className="text-xl font-bold">¡Reporte enviado!</h3>
        <p className="mt-1 text-sm text-[var(--muted-foreground)]">
          Tu reporte ayuda a miles de usuarios en Panamá.
        </p>
      </div>
      <div className="flex items-center gap-2 rounded-[var(--radius-full)] bg-amber-50 px-5 py-2 border border-amber-200">
        <span className="text-2xl">⭐</span>
        <span className="text-lg font-black text-amber-600">+{points} pts</span>
      </div>
      <Button className="mt-2 w-full" onClick={onClose}>
        Perfecto
      </Button>
    </div>
  );
}
