"use client";

import { APIProvider, Map } from "@vis.gl/react-google-maps";
import { useStations } from "@/features/stations/hooks/useStations";
import { useMapStore } from "@/stores/map-store";
import { StationMarker } from "./StationMarker";
import { StationPanel } from "./StationPanel";
import { LineFilter } from "./LineFilter";
import { MapLoadingOverlay } from "./MapLoadingOverlay";

const MAPS_API_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY!;
const MAP_ID = process.env.NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID ?? "DEMO_MAP_ID";


export function MapView() {
  const { stations, loading } = useStations();
  const { center, zoom, selectedStation, activeLines, selectStation } =
    useMapStore();

  const visibleStations = stations.filter((s) =>
    activeLines.includes(s.linea)
  );

  return (
    <div className="relative flex h-full w-full">
      <APIProvider apiKey={MAPS_API_KEY}>
        <Map
          mapId={MAP_ID}
          defaultCenter={center}
          defaultZoom={zoom}
          gestureHandling="greedy"
          disableDefaultUI={false}
          className="map-container"
        >
          {visibleStations.map((station) => (
            <StationMarker
              key={station.id}
              station={station}
              isSelected={selectedStation?.id === station.id}
              onClick={() =>
                selectStation(selectedStation?.id === station.id ? null : station)
              }
            />
          ))}
        </Map>
      </APIProvider>

      {/* Loading skeleton */}
      {loading && <MapLoadingOverlay />}

      {/* Overlay UI */}
      <div className="pointer-events-none absolute inset-0 flex flex-col justify-between p-4">
        <div className="flex items-start justify-between">
          <LineFilter className="pointer-events-auto" />
          <div className="pointer-events-auto rounded-[var(--radius-lg)] border border-[var(--border)] bg-[var(--background)]/90 px-3 py-1.5 text-xs text-[var(--muted-foreground)] shadow backdrop-blur-sm">
            {visibleStations.length} estaciones
          </div>
        </div>

        {selectedStation && (
          <StationPanel
            station={selectedStation}
            onClose={() => selectStation(null)}
            onReport={() => {
              // TODO Fase 2: open report form
            }}
            className="pointer-events-auto"
          />
        )}
      </div>
    </div>
  );
}
