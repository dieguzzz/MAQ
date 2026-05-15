// Firestore field names match the Flutter app exactly

export type MetroLine = 1 | 2 | 3;
export type LineKey = "linea1" | "linea2" | "linea3";

export type StationStatus = "normal" | "moderado" | "lleno" | "cerrado";
export type ReportScope = "station" | "train";
export type ReportStatus = "active" | "resolved" | "expired";

export interface Station {
  id: string;
  nombre: string;
  linea: LineKey;
  lat: number;
  lng: number;
  // Dynamic fields from Firestore (may be missing on static-only stations)
  estado_actual: StationStatus;
  aglomeracion: number; // 1–5
  ultima_actualizacion: Date;
  confidence?: "high" | "medium" | "low";
  is_estimated?: boolean;
}

export interface SimplifiedReport {
  id: string;
  scope: ReportScope;
  stationId: string;
  userId: string;
  // Station report fields
  stationOperational?: "yes" | "partial" | "no";
  stationCrowd?: number; // 1–5
  stationIssues?: string[];
  issueType?: string;
  issueLocation?: string;
  issueStatus?: string;
  parentReportId?: string;
  isSpecificIssue: boolean;
  // Train report fields
  trainCrowd?: number; // 1–5
  trainLine?: string;
  direction?: string;
  etaBucket?: string;
  trainStatus?: string;
  isPanelTime?: boolean;
  // Common
  createdAt: Date;
  basePoints: number;
  bonusPoints: number;
  totalPoints: number;
  status: ReportStatus;
  confirmations: number;
  confidence?: number; // 0–1
  confirmedBy?: string[];
}

export interface UserProfile {
  uid: string;
  displayName: string | null;
  email: string | null;
  photoURL: string | null;
  points: number;
  level: number;
  badges: string[];
  isPremium: boolean;
  reputationScore: number;
  totalReports: number;
  createdAt: Date;
}

export interface EtaGroup {
  id: string;
  stationId: string;
  linea: LineKey;
  estimatedArrivalMin: number;
  confidence: number;
  reportCount: number;
  updatedAt: Date;
}

// UI helper: map Firestore line key to number
export const LINE_KEY_TO_NUMBER: Record<LineKey, MetroLine> = {
  linea1: 1,
  linea2: 2,
  linea3: 3,
};

export const LINE_NUMBER_TO_KEY: Record<MetroLine, LineKey> = {
  1: "linea1",
  2: "linea2",
  3: "linea3",
};
