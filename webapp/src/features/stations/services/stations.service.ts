import {
  collection,
  doc,
  onSnapshot,
  query,
  where,
  type Unsubscribe,
} from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import type { Station, MetroLine } from "@/types/metro";

const COLLECTION = "stations";

function docToStation(id: string, data: Record<string, unknown>): Station {
  return {
    id,
    name: data.name as string,
    line: data.line as MetroLine,
    lat: data.lat as number,
    lng: data.lng as number,
    status: (data.status as Station["status"]) ?? "unknown",
    crowdLevel: (data.crowdLevel as number) ?? 0,
    isTerminal: (data.isTerminal as boolean) ?? false,
    connectedLines: (data.connectedLines as MetroLine[]) ?? [],
    updatedAt: (data.updatedAt as { toDate(): Date })?.toDate() ?? new Date(),
  };
}

export const stationsService = {
  subscribeAll: (callback: (stations: Station[]) => void): Unsubscribe => {
    const q = query(collection(db, COLLECTION));
    return onSnapshot(q, (snap) => {
      const stations = snap.docs.map((d) =>
        docToStation(d.id, d.data() as Record<string, unknown>)
      );
      callback(stations);
    });
  },

  subscribeByLine: (
    line: MetroLine,
    callback: (stations: Station[]) => void
  ): Unsubscribe => {
    const q = query(collection(db, COLLECTION), where("line", "==", line));
    return onSnapshot(q, (snap) => {
      const stations = snap.docs.map((d) =>
        docToStation(d.id, d.data() as Record<string, unknown>)
      );
      callback(stations);
    });
  },

  subscribeOne: (
    stationId: string,
    callback: (station: Station | null) => void
  ): Unsubscribe => {
    return onSnapshot(doc(db, COLLECTION, stationId), (snap) => {
      if (!snap.exists()) {
        callback(null);
        return;
      }
      callback(docToStation(snap.id, snap.data() as Record<string, unknown>));
    });
  },
};
