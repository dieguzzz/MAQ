export function MapLoadingOverlay() {
  return (
    <div className="absolute inset-0 flex items-center justify-center bg-[var(--background)]/60 backdrop-blur-sm">
      <div className="flex flex-col items-center gap-3">
        <div className="h-10 w-10 animate-spin rounded-full border-4 border-[var(--border)] border-t-[var(--brand-primary)]" />
        <p className="text-sm text-[var(--muted-foreground)]">
          Cargando mapa…
        </p>
      </div>
    </div>
  );
}
