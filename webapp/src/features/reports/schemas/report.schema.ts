import { z } from "zod";

export const stationReportSchema = z.object({
  stationId: z.string().min(1, "Selecciona una estación"),
  stationOperational: z.enum(["yes", "partial", "no"]),
  stationCrowd: z.number().int().min(1).max(5),
  stationIssues: z.array(z.string()).optional(),
});

export type StationReportFormValues = z.infer<typeof stationReportSchema>;

export const STATION_ISSUE_OPTIONS = [
  { value: "ac", label: "Aire acondicionado" },
  { value: "escalator", label: "Escalera mecánica" },
  { value: "elevator", label: "Ascensor" },
  { value: "atm", label: "ATM" },
  { value: "recharge", label: "Recarga" },
  { value: "bathroom", label: "Baños" },
  { value: "lights", label: "Iluminación" },
] as const;

export const OPERATIONAL_OPTIONS = [
  { value: "yes", label: "Operando normal" },
  { value: "partial", label: "Operando parcialmente" },
  { value: "no", label: "Cerrada / No opera" },
] as const;
