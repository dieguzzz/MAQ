import type { Station, LineKey } from "@/types/metro";
import { STATIC_STATIONS } from "@/config/stations-static";

export interface RouteSegment {
  linea: LineKey;
  stations: Station[];
  timeMin: number;
}

export interface CalculatedRoute {
  origin: Station;
  destination: Station;
  segments: RouteSegment[];
  totalTimeMin: number;
  transfers: number;
  hasClosedStation: boolean;
  status: "optima" | "congestionada" | "interrumpida";
}

// Average travel time between consecutive stations
const TIME_BETWEEN_STATIONS_MIN = 2.5;
const TRANSFER_TIME_MIN = 5;

// Crowd factor: 1 (vacía) → 1.0x, 5 (muy alta) → 1.6x
function crowdFactor(aglomeracion: number): number {
  return 1 + (Math.max(1, aglomeracion) - 1) * 0.15;
}

// Build a station fallback from static list when not in live data
function asStation(id: string, live: Station[]): Station | null {
  const found = live.find((s) => s.id === id);
  if (found) return found;
  const stat = STATIC_STATIONS.find((s) => s.id === id);
  if (!stat) return null;
  return {
    ...stat,
    estado_actual: "normal",
    aglomeracion: 1,
    ultima_actualizacion: new Date(),
  };
}

// Static line order from canonical data
function lineOrder(linea: LineKey): string[] {
  return STATIC_STATIONS.filter((s) => s.linea === linea).map((s) => s.id);
}

function findConnectionStation(linea: LineKey, all: Station[]): Station | null {
  // San Miguelito connects L1 and L2
  const id = linea === "linea1" ? "l1_san_miguelito" : "l2_san_miguelito";
  return asStation(id, all);
}

function directSegment(
  origin: Station,
  destination: Station,
  all: Station[]
): RouteSegment | null {
  if (origin.linea !== destination.linea) return null;

  const order = lineOrder(origin.linea);
  const orderMap = new Map(order.map((id, i) => [id, i]));
  const oIdx = orderMap.get(origin.id);
  const dIdx = orderMap.get(destination.id);

  if (oIdx === undefined || dIdx === undefined) {
    return { linea: origin.linea, stations: [origin, destination], timeMin: TIME_BETWEEN_STATIONS_MIN };
  }

  const range = oIdx <= dIdx ? order.slice(oIdx, dIdx + 1) : order.slice(dIdx, oIdx + 1).reverse();
  const stations = range.map((id) => asStation(id, all)).filter((s): s is Station => s !== null);

  // Time considering crowd at each station
  const hops = Math.max(1, stations.length - 1);
  const avgCrowd =
    stations.reduce((sum, s) => sum + s.aglomeracion, 0) / Math.max(1, stations.length);
  const timeMin = Math.round(hops * TIME_BETWEEN_STATIONS_MIN * crowdFactor(avgCrowd));

  return { linea: origin.linea, stations, timeMin };
}

export function calculateRoute(
  origin: Station,
  destination: Station,
  liveStations: Station[]
): CalculatedRoute | null {
  if (origin.id === destination.id) return null;

  let segments: RouteSegment[] = [];

  if (origin.linea === destination.linea) {
    const seg = directSegment(origin, destination, liveStations);
    if (seg) segments = [seg];
  } else {
    // Transfer via San Miguelito
    const connOrigin = findConnectionStation(origin.linea, liveStations);
    const connDest = findConnectionStation(destination.linea, liveStations);
    if (!connOrigin || !connDest) return null;

    const seg1 = directSegment(origin, connOrigin, liveStations);
    const seg2 = directSegment(connDest, destination, liveStations);
    if (!seg1 || !seg2) return null;
    segments = [seg1, seg2];
  }

  const allRouteStations = segments.flatMap((s) => s.stations);
  const hasClosedStation = allRouteStations.some((s) => s.estado_actual === "cerrado");
  const hasFullStation = allRouteStations.some((s) => s.estado_actual === "lleno");

  const transfers = Math.max(0, segments.length - 1);
  const totalTimeMin =
    segments.reduce((sum, s) => sum + s.timeMin, 0) + transfers * TRANSFER_TIME_MIN;

  const status: CalculatedRoute["status"] = hasClosedStation
    ? "interrumpida"
    : hasFullStation
    ? "congestionada"
    : "optima";

  return {
    origin,
    destination,
    segments,
    totalTimeMin,
    transfers,
    hasClosedStation,
    status,
  };
}
