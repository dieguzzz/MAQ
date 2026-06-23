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
  type DocumentData,
} from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import type { SimplifiedReport, ReportStatus } from "@/types/metro";
import { userProfileService } from "@/features/gamification/services/user-profile.service";

const POINTS_PER_REPORT = 10;

// Firestore collection name as used by the Flutter app
const COLLECTION = "reports";

function docToReport(id: string, data: DocumentData): SimplifiedReport {
  return {
    id,
    scope: data.scope ?? "station",
    stationId: data.stationId ?? "",
    userId: data.userId ?? "",
    stationOperational: data.stationOperational,
    stationCrowd: data.stationCrowd,
    stationIssues: data.stationIssues
      ? (data.stationIssues as string[])
      : undefined,
    issueType: data.issueType,
    issueLocation: data.issueLocation,
    issueStatus: data.issueStatus,
    parentReportId: data.parentReportId,
    isSpecificIssue: data.isSpecificIssue ?? false,
    trainCrowd: data.trainCrowd,
    trainLine: data.trainLine,
    direction: data.direction,
    etaBucket: data.etaBucket,
    trainStatus: data.trainStatus,
    isPanelTime: data.isPanelTime,
    createdAt: data.createdAt?.toDate?.() ?? new Date(),
    basePoints: data.basePoints ?? 0,
    bonusPoints: data.bonusPoints ?? 0,
    totalPoints: data.totalPoints ?? 0,
    status: (data.status as ReportStatus) ?? "active",
    confirmations: data.confirmations ?? 0,
    confidence: typeof data.confidence === "number" ? data.confidence : undefined,
    confirmedBy: data.confirmedBy ? (data.confirmedBy as string[]) : undefined,
  };
}

export const reportsService = {
  /** Submit a station report and award points to the user. */
  submitStationReport: async (params: {
    userId: string;
    stationId: string;
    linea: string;
    stationOperational: "yes" | "partial" | "no";
    stationCrowd: number;
    stationIssues?: string[];
  }) => {
    await addDoc(collection(db, COLLECTION), {
      scope: "station",
      stationId: params.stationId,
      userId: params.userId,
      stationOperational: params.stationOperational,
      stationCrowd: params.stationCrowd,
      stationIssues: params.stationIssues ?? [],
      isSpecificIssue: false,
      status: "active",
      confirmations: 0,
      basePoints: POINTS_PER_REPORT,
      bonusPoints: 0,
      totalPoints: POINTS_PER_REPORT,
      createdAt: serverTimestamp(),
    });

    await userProfileService.addReportPoints(
      params.userId,
      params.linea,
      POINTS_PER_REPORT
    );
  },

  /** Subscribe to active reports for a station */
  subscribeByStation: (
    stationId: string,
    callback: (reports: SimplifiedReport[]) => void
  ): Unsubscribe => {
    const q = query(
      collection(db, COLLECTION),
      where("stationId", "==", stationId),
      where("status", "==", "active"),
      orderBy("createdAt", "desc"),
      limit(50)
    );
    return onSnapshot(q, (snap) => {
      callback(snap.docs.map((d) => docToReport(d.id, d.data())));
    });
  },

  /** Subscribe to recent active reports (all stations) */
  subscribeRecent: (
    callback: (reports: SimplifiedReport[]) => void,
    count = 20
  ): Unsubscribe => {
    const q = query(
      collection(db, COLLECTION),
      where("status", "==", "active"),
      orderBy("createdAt", "desc"),
      limit(count)
    );
    return onSnapshot(q, (snap) => {
      callback(snap.docs.map((d) => docToReport(d.id, d.data())));
    });
  },
};
