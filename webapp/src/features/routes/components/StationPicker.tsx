"use client";

import { useState, useMemo } from "react";
import { Search, MapPin, X } from "lucide-react";
import { LINE_KEY_COLORS, LINE_KEY_NAMES } from "@/config/metro-lines";
import { cn } from "@/lib/utils/cn";
import type { Station } from "@/types/metro";

interface Props {
  stations: Station[];
  value: Station | null;
  onChange: (s: Station | null) => void;
  placeholder: string;
  emoji: string;
  excludeId?: string;
}

function normalize(s: string) {
  return s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "");
}

export function StationPicker({
  stations,
  value,
  onChange,
  placeholder,
  emoji,
  excludeId,
}: Props) {
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState(false);

  const filtered = useMemo(() => {
    const list = stations.filter((s) => s.id !== excludeId);
    if (!query) return list;
    const q = normalize(query);
    return list.filter(
      (s) => normalize(s.nombre).includes(q) || normalize(s.linea).includes(q)
    );
  }, [stations, query, excludeId]);

  if (value) {
    const color = LINE_KEY_COLORS[value.linea];
    return (
      <div className="flex items-center gap-3 rounded-[var(--radius-lg)] border-2 border-[var(--border)] bg-[var(--card)] p-3">
        <span className="text-2xl">{emoji}</span>
        <div className="min-w-0 flex-1">
          <p className="text-[10px] font-bold uppercase tracking-wider" style={{ color }}>
            {LINE_KEY_NAMES[value.linea]}
          </p>
          <p className="truncate font-bold">{value.nombre}</p>
        </div>
        <button
          type="button"
          onClick={() => onChange(null)}
          className="rounded-full p-1 text-[var(--muted-foreground)] hover:bg-[var(--muted)]"
          aria-label="Quitar selección"
        >
          <X className="h-4 w-4" />
        </button>
      </div>
    );
  }

  return (
    <div className="relative">
      <div className="flex items-center gap-2 rounded-[var(--radius-lg)] border-2 border-[var(--border)] bg-[var(--card)] px-3 py-2.5 focus-within:border-[var(--brand-primary)] transition-colors">
        <span className="text-xl">{emoji}</span>
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onFocus={() => setOpen(true)}
          onBlur={() => setTimeout(() => setOpen(false), 150)}
          placeholder={placeholder}
          className="flex-1 bg-transparent text-sm outline-none placeholder:text-[var(--muted-foreground)]"
        />
        <Search className="h-4 w-4 text-[var(--muted-foreground)]" />
      </div>

      {open && filtered.length > 0 && (
        <div className="absolute left-0 right-0 top-full z-20 mt-1 max-h-72 overflow-y-auto rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--card)] shadow-[var(--shadow-panel)] animate-fade-in">
          {filtered.map((s) => {
            const color = LINE_KEY_COLORS[s.linea];
            return (
              <button
                key={s.id}
                type="button"
                onMouseDown={(e) => e.preventDefault()}
                onClick={() => {
                  onChange(s);
                  setQuery("");
                  setOpen(false);
                }}
                className={cn(
                  "flex w-full items-center gap-3 px-3 py-2 text-left transition-colors",
                  "hover:bg-[var(--muted)] focus-visible:bg-[var(--muted)] focus-visible:outline-none"
                )}
              >
                <span
                  className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-xs font-bold text-white"
                  style={{ backgroundColor: color }}
                >
                  {s.linea.replace("linea", "L")}
                </span>
                <span className="flex-1 truncate text-sm font-medium">{s.nombre}</span>
                <MapPin className="h-3.5 w-3.5 shrink-0 text-[var(--muted-foreground)]" />
              </button>
            );
          })}
        </div>
      )}

      {open && filtered.length === 0 && (
        <div className="absolute left-0 right-0 top-full z-20 mt-1 rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--card)] p-4 text-center text-sm text-[var(--muted-foreground)] shadow-[var(--shadow-panel)]">
          Sin resultados
        </div>
      )}
    </div>
  );
}
