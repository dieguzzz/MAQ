import { z } from "zod";

export const reportSchema = z.object({
  stationId: z.string().min(1, "Selecciona una estación"),
  type: z.enum([
    "crowded",
    "empty",
    "delay",
    "incident",
    "station_closed",
    "good_service",
  ]),
  comment: z.string().max(280).optional(),
});

export type ReportFormValues = z.infer<typeof reportSchema>;
