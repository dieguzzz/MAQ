import {
  collection,
  doc,
  onSnapshot,
  query,
  where,
  type Unsubscribe,
  type DocumentData,
} from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import type { Station, LineKey, StationStatus } from "@/types/metro";

const COLLECTION = "stations";

function docToStation(id: string, data: DocumentData): Station {
  const geo = data.ubicacion as { latitude: number; longitude: number } | null;
  return {
    id,
    nombre: (data.nombre as string) ?? id,
    linea: (data.linea as LineKey) ?? "linea1",
    lat: geo?.latitude ?? (data.lat as number) ?? 0,
    lng: geo?.longitude ?? (data.lng as number) ?? 0,
    estado_actual: (data.estado_actual as StationStatus) ?? "normal",
    aglomeracion: (data.aglomeracion as number) ?? 1,
    ultima_actualizacion:
      data.ultima_actualizacion?.toDate?.() ?? new Date(),
    confidence: data.confidence as Station["confidence"],
    is_estimated: (data.is_estimated as boolean) ?? false,
  };
}

export const stationsService = {
  subscribeAll: (callback: (stations: Station[]) => void): Unsubscribe => {
    const q = query(collection(db, COLLECTION));
    return onSnapshot(q, (snap) => {
      const stations = snap.docs.map((d) => docToStation(d.id, d.data()));
      callback(stations);
    });
  },

  subscribeByLine: (
    linea: LineKey,
    callback: (stations: Station[]) => void
  ): Unsubscribe => {
    const q = query(collection(db, COLLECTION), where("linea", "==", linea));
    return onSnapshot(q, (snap) => {
      const stations = snap.docs.map((d) => docToStation(d.id, d.data()));
      callback(stations);
    });
  },

  subscribeOne: (
    stationId: string,
    callback: (station: Station | null) => void
  ): Unsubscribe => {
    return onSnapshot(doc(db, COLLECTION, stationId), (snap) => {
      callback(snap.exists() ? docToStation(snap.id, snap.data()!) : null);
    });
  },
};
