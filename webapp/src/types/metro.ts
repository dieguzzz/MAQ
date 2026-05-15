export type MetroLine = 1 | 2 | 3;

export type StationStatus = "normal" | "crowded" | "closed" | "unknown";
export type TrainStatus = "on_time" | "delayed" | "out_of_service";
export type ReportType =
  | "crowded"
  | "empty"
  | "delay"
  | "incident"
  | "station_closed"
  | "good_service";

export interface Station {
  id: string;
  name: string;
  line: MetroLine;
  lat: number;
  lng: number;
  status: StationStatus;
  crowdLevel: number; // 0-100
  isTerminal: boolean;
  connectedLines?: MetroLine[];
  updatedAt: Date;
}

export interface Train {
  id: string;
  line: MetroLine;
  currentStationId: string;
  nextStationId: string;
  status: TrainStatus;
  direction: "forward" | "backward";
  lat: number;
  lng: number;
  updatedAt: Date;
}

export interface SimplifiedReport {
  id: string;
  stationId: string;
  userId: string;
  type: ReportType;
  confidence: number; // 0-1
  createdAt: Date;
  expiresAt: Date;
}

export interface EtaGroup {
  id: string;
  stationId: string;
  line: MetroLine;
  estimatedArrivalMin: number;
  confidence: number;
  reportCount: number;
  updatedAt: Date;
}

export interface Route {
  id: string;
  segments: RouteSegment[];
  totalTimeMin: number;
  transfers: number;
}

export interface RouteSegment {
  fromStationId: string;
  toStationId: string;
  line: MetroLine;
  stopsCount: number;
  estimatedTimeMin: number;
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

export interface Badge {
  id: string;
  name: string;
  description: string;
  iconUrl: string;
  category: "reports" | "accuracy" | "explorer" | "premium";
  pointsRequired: number;
}
