import {
  doc,
  setDoc,
  onSnapshot,
  collection,
  query,
  orderBy,
  limit,
  type Unsubscribe,
  type DocumentData,
  serverTimestamp,
} from "firebase/firestore";
import { db } from "@/lib/firebase/client";
import type { User } from "firebase/auth";
import { calculateLevel } from "./level.service";

export interface GamificationStats {
  puntos: number;
  nivel: number;
  streak: number;
  badges: BadgeEntry[];
  puntosPorLinea: Record<string, number>;
  ranking?: number;
}

export interface BadgeEntry {
  type: string;
  nombre: string;
  descripcion: string;
  icono: string;
  desbloqueadoEn?: Date;
}

export interface UserProfile {
  uid: string;
  email: string;
  nombre: string;
  fotoUrl?: string;
  reputacion: number;
  reportesCount: number;
  precision: number;
  creadoEn: Date;
  gamification: GamificationStats;
}

function docToProfile(id: string, data: DocumentData): UserProfile {
  const g = (data.gamification ?? {}) as Record<string, unknown>;
  const puntos = (g.puntos as number) ?? 0;
  const nivel =
    typeof g.nivel === "number" ? g.nivel : calculateLevel(puntos);

  const rawBadges = (g.badges as Array<Record<string, unknown>>) ?? [];
  const badges: BadgeEntry[] = rawBadges.map((b) => ({
    type: (b.type as string) ?? "",
    nombre: (b.nombre as string) ?? "",
    descripcion: (b.descripcion as string) ?? "",
    icono: (b.icono as string) ?? "🏅",
    desbloqueadoEn: b.desbloqueado_en
      ? (b.desbloqueado_en as { toDate(): Date }).toDate()
      : undefined,
  }));

  return {
    uid: id,
    email: (data.email as string) ?? "",
    nombre: (data.nombre as string) ?? "",
    fotoUrl: data.foto_url as string | undefined,
    reputacion: (data.reputacion as number) ?? 50,
    reportesCount: (data.reportes_count as number) ?? 0,
    precision: (data.precision as number) ?? 0,
    creadoEn: data.creado_en?.toDate?.() ?? new Date(),
    gamification: {
      puntos,
      nivel,
      streak: (g.streak as number) ?? 0,
      badges,
      puntosPorLinea: (g.puntos_por_linea as Record<string, number>) ?? {},
      ranking: g.ranking as number | undefined,
    },
  };
}

export const userProfileService = {
  subscribeProfile: (uid: string, cb: (p: UserProfile | null) => void): Unsubscribe =>
    onSnapshot(doc(db, "users", uid), (snap) => {
      cb(snap.exists() ? docToProfile(snap.id, snap.data()!) : null);
    }),

  /** Create initial profile for a new Firebase Auth user */
  createIfNotExists: async (user: User): Promise<void> => {
    const ref = doc(db, "users", user.uid);
    await setDoc(
      ref,
      {
        uid: user.uid,
        email: user.email ?? "",
        nombre: user.displayName ?? user.email?.split("@")[0] ?? "Usuario",
        foto_url: user.photoURL ?? null,
        reputacion: 50,
        reportes_count: 0,
        precision: 0.0,
        creado_en: serverTimestamp(),
        gamification: {
          puntos: 0,
          nivel: 1,
          streak: 0,
          badges: [],
          puntos_por_linea: {},
        },
      },
      { merge: true }
    );
  },

  subscribeLeaderboard: (
    cb: (users: UserProfile[]) => void,
    count = 20
  ): Unsubscribe => {
    const q = query(
      collection(db, "users"),
      orderBy("gamification.puntos", "desc"),
      limit(count)
    );
    return onSnapshot(q, (snap) => {
      cb(snap.docs.map((d) => docToProfile(d.id, d.data())));
    });
  },
};
