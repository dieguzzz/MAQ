import {
  collection,
  doc,
  updateDoc,
  query,
  orderBy,
  limit,
  where,
  onSnapshot,
  getCountFromServer,
  type Unsubscribe,
  type DocumentData,
  serverTimestamp,
  getDocs,
} from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import type { Station, StationStatus } from "@/types/metro";
import type { SimplifiedReport } from "@/types/metro";
import type { UserProfile } from "@/features/gamification/services/user-profile.service";

// ── Overview stats ────────────────────────────────────────────────

export interface AdminStats {
  totalUsers: number;
  reportsToday: number;
  activeReports: number;
  stationsClosed: number;
  stationsWithIssues: number;
}

export async function fetchAdminStats(stations: Station[]): Promise<AdminStats> {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const [usersSnap, activeSnap] = await Promise.all([
    getCountFromServer(collection(db, "users")),
    getCountFromServer(
      query(collection(db, "reports"), where("status", "==", "active"))
    ),
  ]);

  // Reports today — try createdAt field (simplified reports)
  let reportsToday = 0;
  try {
    const todaySnap = await getCountFromServer(
      query(
        collection(db, "reports"),
        where("createdAt", ">=", today),
        where("status", "==", "active")
      )
    );
    reportsToday = todaySnap.data().count;
  } catch {
    // Index may not exist yet; fallback to 0
    reportsToday = 0;
  }

  const stationsClosed = stations.filter((s) => s.estado_actual === "cerrado").length;
  const stationsWithIssues = stations.filter(
    (s) => s.estado_actual === "lleno" || s.estado_actual === "moderado"
  ).length;

  return {
    totalUsers: usersSnap.data().count,
    activeReports: activeSnap.data().count,
    reportsToday,
    stationsClosed,
    stationsWithIssues,
  };
}

// ── Stations management ───────────────────────────────────────────

export const adminStationsService = {
  updateStatus: async (
    stationId: string,
    status: StationStatus,
    aglomeracion: number
  ) => {
    await updateDoc(doc(db, "stations", stationId), {
      estado_actual: status,
      aglomeracion,
      ultima_actualizacion: serverTimestamp(),
    });
  },
};

// ── Reports moderation ────────────────────────────────────────────

function docToReport(id: string, data: DocumentData): SimplifiedReport {
  return {
    id,
    scope: data.scope ?? "station",
    stationId: data.stationId ?? "",
    userId: data.userId ?? "",
    stationOperational: data.stationOperational,
    stationCrowd: data.stationCrowd,
    stationIssues: data.stationIssues ?? [],
    isSpecificIssue: data.isSpecificIssue ?? false,
    trainLine: data.trainLine,
    direction: data.direction,
    etaBucket: data.etaBucket,
    trainStatus: data.trainStatus,
    createdAt: data.createdAt?.toDate?.() ?? new Date(),
    basePoints: data.basePoints ?? 0,
    bonusPoints: data.bonusPoints ?? 0,
    totalPoints: data.totalPoints ?? 0,
    status: data.status ?? "active",
    confirmations: data.confirmations ?? 0,
    confidence: typeof data.confidence === "number" ? data.confidence : undefined,
  };
}

export const adminReportsService = {
  subscribeRecent: (
    cb: (reports: SimplifiedReport[]) => void,
    count = 50
  ): Unsubscribe => {
    const q = query(
      collection(db, "reports"),
      orderBy("createdAt", "desc"),
      limit(count)
    );
    return onSnapshot(q, (snap) =>
      cb(snap.docs.map((d) => docToReport(d.id, d.data())))
    );
  },

  resolveReport: (id: string) =>
    updateDoc(doc(db, "reports", id), { status: "resolved" }),

  expireReport: (id: string) =>
    updateDoc(doc(db, "reports", id), { status: "expired" }),
};

// ── Users management ──────────────────────────────────────────────

function docToUser(id: string, data: DocumentData): UserProfile {
  const g = (data.gamification ?? {}) as Record<string, unknown>;
  return {
    uid: id,
    email: (data.email as string) ?? "",
    nombre: (data.nombre as string) ?? id,
    fotoUrl: data.foto_url as string | undefined,
    reputacion: (data.reputacion as number) ?? 50,
    reportesCount: (data.reportes_count as number) ?? 0,
    precision: (data.precision as number) ?? 0,
    creadoEn: data.creado_en?.toDate?.() ?? new Date(),
    gamification: {
      puntos: (g.puntos as number) ?? 0,
      nivel: (g.nivel as number) ?? 1,
      streak: (g.streak as number) ?? 0,
      badges: [],
      puntosPorLinea: (g.puntos_por_linea as Record<string, number>) ?? {},
      ranking: g.ranking as number | undefined,
    },
  };
}

export const adminUsersService = {
  subscribeTopUsers: (
    cb: (users: UserProfile[]) => void,
    count = 30
  ): Unsubscribe => {
    const q = query(
      collection(db, "users"),
      orderBy("gamification.puntos", "desc"),
      limit(count)
    );
    return onSnapshot(q, (snap) =>
      cb(snap.docs.map((d) => docToUser(d.id, d.data())))
    );
  },

  searchUsers: async (term: string): Promise<UserProfile[]> => {
    // Firestore doesn't support full-text; we fetch top 100 and filter client-side
    const snap = await getDocs(
      query(collection(db, "users"), orderBy("nombre"), limit(100))
    );
    const q = term.toLowerCase();
    return snap.docs
      .map((d) => docToUser(d.id, d.data()))
      .filter(
        (u) =>
          u.nombre.toLowerCase().includes(q) ||
          u.email.toLowerCase().includes(q)
      );
  },
};
