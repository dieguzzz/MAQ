// Ported from LevelService.dart — must stay in sync

const LEVEL_NAMES: Record<number, string> = {
  1: "🥚 Novato del Metro",
  2: "🥚 Novato del Metro",
  3: "🥚 Novato del Metro",
  4: "🥚 Novato del Metro",
  5: "🚶 Viajero Frecuente",
  10: "🎯 Reportero Confiable",
  20: "💪 Experto del Metro",
  30: "🌟 Leyenda Urbana",
  40: "👑 Héroe del Metro",
  50: "🇵🇦 Ícono Panameño",
};

const POINTS_REQUIRED: Record<number, number> = {
  1: 0,
  2: 100,
  3: 250,
  4: 500,
  5: 1000,
  6: 1500,
  7: 2200,
  8: 3000,
  9: 4000,
  10: 5000,
  11: 6500,
  12: 8000,
  13: 10000,
  14: 12000,
  15: 15000,
  16: 18000,
  17: 21000,
  18: 24000,
  19: 27000,
  20: 30000,
  21: 34000,
  22: 38000,
  23: 42000,
  24: 46000,
  25: 50000,
  30: 75000,
  40: 120000,
  50: 200000,
};

function getRequiredPoints(level: number): number {
  if (level in POINTS_REQUIRED) return POINTS_REQUIRED[level]!;
  // Linear interpolation for unlisted levels
  const keys = Object.keys(POINTS_REQUIRED).map(Number).sort((a, b) => a - b);
  let lo = keys[0]!, hi = keys[keys.length - 1]!;
  for (let i = 0; i < keys.length - 1; i++) {
    if (keys[i]! <= level && level <= keys[i + 1]!) {
      lo = keys[i]!;
      hi = keys[i + 1]!;
      break;
    }
  }
  const pLo = POINTS_REQUIRED[lo] ?? 0;
  const pHi = POINTS_REQUIRED[hi] ?? pLo;
  const t = (level - lo) / (hi - lo);
  return Math.round(pLo + t * (pHi - pLo));
}

export function calculateLevel(points: number): number {
  for (let l = 50; l >= 1; l--) {
    if (points >= getRequiredPoints(l)) return l;
  }
  return 1;
}

export function getLevelName(level: number): string {
  const keys = Object.keys(LEVEL_NAMES).map(Number).sort((a, b) => b - a);
  for (const k of keys) {
    if (level >= k) return LEVEL_NAMES[k]!;
  }
  return LEVEL_NAMES[1]!;
}

export function getLevelProgress(points: number, level: number): number {
  if (level >= 50) return 1;
  const current = getRequiredPoints(level);
  const next = getRequiredPoints(level + 1);
  if (next <= current) return 1;
  return Math.min(1, (points - current) / (next - current));
}

export function getPointsToNextLevel(points: number, level: number): number {
  if (level >= 50) return 0;
  return Math.max(0, getRequiredPoints(level + 1) - points);
}
