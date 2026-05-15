import {
  collection,
  addDoc,
  query,
  where,
  orderBy,
  limit,
  onSnapshot,
  serverTimestamp,
  type Unsubscribe,
} from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import type { SimplifiedReport, ReportType } from "@/types/metro";

const COLLECTION = "simplified_reports";

export const reportsService = {
  submitReport: async (
    userId: string,
    stationId: string,
    type: ReportType,
    comment?: string
  ) => {
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 30);

    await addDoc(collection(db, COLLECTION), {
      userId,
      stationId,
      type,
      comment: comment ?? null,
      confidence: 0.5,
      createdAt: serverTimestamp(),
      expiresAt,
    });
  },

  subscribeByStation: (
    stationId: string,
    callback: (reports: SimplifiedReport[]) => void
  ): Unsubscribe => {
    const now = new Date();
    const q = query(
      collection(db, COLLECTION),
      where("stationId", "==", stationId),
      where("expiresAt", ">", now),
      orderBy("expiresAt", "desc"),
      limit(50)
    );
    return onSnapshot(q, (snap) => {
      const reports = snap.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          stationId: data.stationId,
          userId: data.userId,
          type: data.type as ReportType,
          confidence: data.confidence ?? 0.5,
          createdAt: data.createdAt?.toDate() ?? new Date(),
          expiresAt: data.expiresAt?.toDate() ?? new Date(),
        } satisfies SimplifiedReport;
      });
      callback(reports);
    });
  },
};
