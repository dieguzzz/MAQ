"use client";

import { useForm, Controller } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { stationReportSchema, type StationReportFormValues } from "../schemas/report.schema";
import { useSubmitReport } from "../hooks/useSubmitReport";
import { CrowdSelector } from "./CrowdSelector";
import { OperationalSelector } from "./OperationalSelector";
import { IssueSelector } from "./IssueSelector";
import { ReportSuccess } from "./ReportSuccess";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { LINE_KEY_COLORS, LINE_KEY_NAMES } from "@/config/metro-lines";
import type { Station } from "@/types/metro";

interface Props {
  station: Station;
  onClose: () => void;
}

export function ReportForm({ station, onClose }: Props) {
  const lineColor = LINE_KEY_COLORS[station.linea];
  const { submit, state, earnedPoints, reset } = useSubmitReport();

  const { control, handleSubmit, watch, formState: { errors } } = useForm<StationReportFormValues>({
    resolver: zodResolver(stationReportSchema),
    defaultValues: {
      stationId: station.id,
      stationOperational: "yes",
      stationCrowd: 1,
      stationIssues: [],
    },
  });

  const operational = watch("stationOperational");

  const onSubmit = async (data: StationReportFormValues) => {
    await submit({
      stationId: data.stationId,
      linea: station.linea,
      stationOperational: data.stationOperational,
      stationCrowd: data.stationCrowd,
      stationIssues: data.stationIssues,
    });
  };

  if (state === "success") {
    return (
      <ReportSuccess
        points={earnedPoints}
        onClose={() => { reset(); onClose(); }}
      />
    );
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      {/* Header */}
      <div className="mb-6">
        <div className="mb-1 flex items-center gap-2">
          <span className="text-2xl">📍</span>
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider" style={{ color: lineColor }}>
              {LINE_KEY_NAMES[station.linea]}
            </p>
            <h2 className="text-xl font-black tracking-tight">{station.nombre}</h2>
          </div>
        </div>
        <p className="text-sm text-[var(--muted-foreground)]">
          Comparte el estado actual con otros usuarios 🇵🇦
        </p>
      </div>

      <div className="space-y-6">
        {/* Estado de la estación */}
        <div className="space-y-2">
          <Label>🚉 ¿Cómo está la estación?</Label>
          <Controller
            name="stationOperational"
            control={control}
            render={({ field }) => (
              <OperationalSelector value={field.value} onChange={field.onChange} />
            )}
          />
          {errors.stationOperational && (
            <p className="text-xs text-[var(--destructive)]">{errors.stationOperational.message}</p>
          )}
        </div>

        {/* Afluencia */}
        <div className="space-y-2">
          <Label>👥 Nivel de afluencia</Label>
          <Controller
            name="stationCrowd"
            control={control}
            render={({ field }) => (
              <CrowdSelector value={field.value} onChange={field.onChange} />
            )}
          />
          {errors.stationCrowd && (
            <p className="text-xs text-[var(--destructive)]">{errors.stationCrowd.message}</p>
          )}
        </div>

        {/* Problemas — solo si es parcial o cerrada */}
        {(operational === "partial" || operational === "no") && (
          <div className="space-y-2 animate-fade-in">
            <Label>⚠️ ¿Qué está fallando?</Label>
            <Controller
              name="stationIssues"
              control={control}
              render={({ field }) => (
                <IssueSelector
                  selected={field.value ?? []}
                  onChange={field.onChange}
                />
              )}
            />
          </div>
        )}

        {/* Error global */}
        {state === "error" && (
          <p className="rounded-[var(--radius)] bg-red-50 p-3 text-sm text-red-600 border border-red-200">
            Error al enviar. Verifica tu conexión e intenta de nuevo.
          </p>
        )}

        {/* Submit */}
        <Button
          type="submit"
          className="w-full"
          size="lg"
          disabled={state === "loading"}
          style={{ backgroundColor: lineColor }}
        >
          {state === "loading" ? (
            <span className="flex items-center gap-2">
              <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/30 border-t-white" />
              Enviando…
            </span>
          ) : (
            "Enviar reporte ⚡"
          )}
        </Button>
      </div>
    </form>
  );
}
