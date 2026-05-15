"use client";

import { APIProvider, Map } from "@vis.gl/react-google-maps";
import { useStations } from "@/features/stations/hooks/useStations";
import { useMapStore } from "@/stores/map-store";
import { StationMarker } from "./StationMarker";
import { StationPanel } from "./StationPanel";
import { LineFilter } from "./LineFilter";
import type { MetroLine } from "@/types/metro";

const MAPS_API_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY!;

const MAP_ID = process.env.NEXT_PUBLIC_GOOGLE_MAPS_MAP_ID ?? "DEMO_MAP_ID";

export function MapView() {
  const { stations, loading } = useStations();
  const { center, zoom, selectedStation, activeLines, selectStation } =
    useMapStore();

  const visibleStations = stations.filter((s) =>
    activeLines.includes(s.line as MetroLine)
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
          {!loading &&
            visibleStations.map((station) => (
              <StationMarker
                key={station.id}
                station={station}
                isSelected={selectedStation?.id === station.id}
                onClick={() =>
                  selectStation(
                    selectedStation?.id === station.id ? null : station
                  )
                }
              />
            ))}
        </Map>
      </APIProvider>

      {/* Overlay controls */}
      <div className="pointer-events-none absolute inset-0 flex flex-col justify-between p-4">
        <LineFilter className="pointer-events-auto self-start" />
        {selectedStation && (
          <StationPanel
            station={selectedStation}
            onClose={() => selectStation(null)}
            className="pointer-events-auto"
          />
        )}
      </div>
    </div>
  );
}
