"use client";

import { useState } from "react";
import { ArrowDownUp } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useStations } from "@/features/stations/hooks/useStations";
import { useRouteCalculation } from "../hooks/useRouteCalculation";
import { StationPicker } from "./StationPicker";
import { RouteResult } from "./RouteResult";
import type { Station } from "@/types/metro";

export function RoutePlanner() {
  const { stations, loading } = useStations();
  const [origin, setOrigin] = useState<Station | null>(null);
  const [destination, setDestination] = useState<Station | null>(null);

  const route = useRouteCalculation(origin, destination, stations);

  const swap = () => {
    const o = origin;
    setOrigin(destination);
    setDestination(o);
  };

  return (
    <div className="space-y-4">
      {/* Form card */}
      <div className="metro-card space-y-3">
        <StationPicker
          stations={stations}
          value={origin}
          onChange={setOrigin}
          placeholder="¿Desde dónde sales?"
          emoji="🟢"
          excludeId={destination?.id}
        />

        <div className="flex justify-center">
          <button
            type="button"
            onClick={swap}
            disabled={!origin && !destination}
            className="rounded-full border-2 border-[var(--border)] bg-[var(--card)] p-2 text-[var(--muted-foreground)] transition-all hover:rotate-180 hover:border-[var(--brand-primary)] hover:text-[var(--brand-primary)] disabled:opacity-40 disabled:hover:rotate-0"
            aria-label="Intercambiar origen y destino"
          >
            <ArrowDownUp className="h-4 w-4" />
          </button>
        </div>

        <StationPicker
          stations={stations}
          value={destination}
          onChange={setDestination}
          placeholder="¿A dónde vas?"
          emoji="🔴"
          excludeId={origin?.id}
        />

        {origin && destination && !route && (
          <p className="rounded-[var(--radius)] bg-amber-50 p-3 text-sm text-amber-800 border border-amber-200">
            ⚠️ No se pudo calcular la ruta. Verifica las estaciones seleccionadas.
          </p>
        )}
      </div>

      {/* Result */}
      {route && <RouteResult route={route} />}

      {/* Empty state */}
      {!origin && !destination && !loading && (
        <div className="metro-card bg-gradient-to-br from-white to-[#F0F7FF] text-center py-8">
          <div className="text-5xl mb-3">🗺️</div>
          <h3 className="font-bold mb-1">Planifica tu viaje</h3>
          <p className="text-sm text-[var(--muted-foreground)] max-w-xs mx-auto">
            Selecciona origen y destino para calcular tiempo, transbordos y mejor ruta.
          </p>
        </div>
      )}

      {/* CTA when only origin */}
      {origin && !destination && (
        <div className="text-center py-4">
          <Button variant="outline" onClick={() => setOrigin(null)}>
            Limpiar
          </Button>
        </div>
      )}
    </div>
  );
}
