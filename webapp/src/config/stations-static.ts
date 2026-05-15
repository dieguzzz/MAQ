import type { Station } from "@/types/metro";

// Canonical station list mirrored from StationUpdateService in the Flutter app.
// Used as fallback/skeleton while Firestore data loads.
export const STATIC_STATIONS: Omit<
  Station,
  "estado_actual" | "aglomeracion" | "ultima_actualizacion"
>[] = [
  // ── Línea 1 ──────────────────────────────────────────────────────────
  { id: "l1_albrook", nombre: "Albrook", linea: "linea1", lat: 8.973241195714332, lng: -79.54980254173279 },
  { id: "l1_5demayo", nombre: "5 de Mayo", linea: "linea1", lat: 8.96213183480186, lng: -79.53980661928654 },
  { id: "l1_loteria", nombre: "Lotería", linea: "linea1", lat: 8.967513186103329, lng: -79.53582219779491 },
  { id: "l1_santo_tomas", nombre: "Santo Tomás", linea: "linea1", lat: 8.973220000655779, lng: -79.53272726386786 },
  { id: "l1_iglesia_carmen", nombre: "Iglesia del Carmen", linea: "linea1", lat: 8.981927753730456, lng: -79.52745974063873 },
  { id: "l1_via_argentina", nombre: "Vía Argentina", linea: "linea1", lat: 8.98981336530052, lng: -79.52214729040861 },
  { id: "l1_fernandez_cordoba", nombre: "Fernández de Córdoba", linea: "linea1", lat: 8.996328833265732, lng: -79.51964445412159 },
  { id: "l1_el_ingenio", nombre: "El Ingenio", linea: "linea1", lat: 9.007804050468373, lng: -79.51892092823982 },
  { id: "l1_12_octubre", nombre: "12 de Octubre", linea: "linea1", lat: 9.016294410425926, lng: -79.51720230281353 },
  { id: "l1_pueblo_nuevo", nombre: "Pueblo Nuevo", linea: "linea1", lat: 9.023066687035316, lng: -79.51264690607786 },
  { id: "l1_san_miguelito", nombre: "San Miguelito", linea: "linea1", lat: 9.029978238432253, lng: -79.5061844587326 },
  { id: "l1_pan_de_azucar", nombre: "Pan de Azúcar", linea: "linea1", lat: 9.041112335593969, lng: -79.50831983238459 },
  { id: "l1_los_andes", nombre: "Los Andes", linea: "linea1", lat: 9.049146644684965, lng: -79.50847137719393 },
  { id: "l1_san_isidro", nombre: "San Isidro", linea: "linea1", lat: 9.065018057870349, lng: -79.51402623206377 },
  { id: "l1_villa_zaita", nombre: "Villa Zaita", linea: "linea1", lat: 9.079733650774982, lng: -79.52711541205645 },
  // ── Línea 2 ──────────────────────────────────────────────────────────
  { id: "l2_san_miguelito", nombre: "San Miguelito", linea: "linea2", lat: 9.030493462081608, lng: -79.50519606471062 },
  { id: "l2_paraiso", nombre: "Paraíso", linea: "linea2", lat: 9.02978949950754, lng: -79.49849590659142 },
  { id: "l2_cincuentenario", nombre: "Cincuentenario", linea: "linea2", lat: 9.030102408723574, lng: -79.49148159474134 },
  { id: "l2_villa_lucre", nombre: "Villa Lucre", linea: "linea2", lat: 9.037024752017816, lng: -79.48143772780895 },
  { id: "l2_el_crisol", nombre: "El Crisol", linea: "linea2", lat: 9.043775779423067, lng: -79.47162117809057 },
  { id: "l2_brisas_golf", nombre: "Brisas del Golf", linea: "linea2", lat: 9.049149955717043, lng: -79.4590650871396 },
  { id: "l2_cerro_viento", nombre: "Cerro Viento", linea: "linea2", lat: 9.050503503082927, lng: -79.45135373622179 },
  { id: "l2_san_antonio", nombre: "San Antonio", linea: "linea2", lat: 9.051866647276066, lng: -79.44489732384682 },
  { id: "l2_pedregal", nombre: "Pedregal", linea: "linea2", lat: 9.05978102130942, lng: -79.42924711318817 },
  { id: "l2_don_bosco", nombre: "Don Bosco", linea: "linea2", lat: 9.062991458890306, lng: -79.42034639418125 },
  { id: "l2_corredor_sur", nombre: "Corredor Sur", linea: "linea2", lat: 9.068797083155014, lng: -79.40713986754417 },
  { id: "l2_las_mananitas", nombre: "Las Mañanitas", linea: "linea2", lat: 9.079479054000116, lng: -79.40004374831915 },
  { id: "l2_hospital_este", nombre: "Hospital del Este", linea: "linea2", lat: 9.094394676685313, lng: -79.39394138753414 },
  { id: "l2_altos_tocumen", nombre: "Altos de Tocumen", linea: "linea2", lat: 9.103302767638866, lng: -79.38015751540661 },
  { id: "l2_24_diciembre", nombre: "24 de Diciembre", linea: "linea2", lat: 9.103358053522262, lng: -79.37086164951324 },
  { id: "l2_nuevo_tocumen", nombre: "Nuevo Tocumen", linea: "linea2", lat: 9.101879235961555, lng: -79.35344874858856 },
  { id: "l2_itse", nombre: "ITSE", linea: "linea2", lat: 9.069297108228719, lng: -79.39861995547997 },
  { id: "l2_aeropuerto", nombre: "Aeropuerto", linea: "linea2", lat: 9.065702417334673, lng: -79.3895435705781 },
];

export function mergeWithLive(
  liveStations: Station[]
): Station[] {
  if (liveStations.length > 0) return liveStations;
  // Fallback: static skeleton with default status
  return STATIC_STATIONS.map((s) => ({
    ...s,
    estado_actual: "normal" as const,
    aglomeracion: 1,
    ultima_actualizacion: new Date(),
  }));
}
