"use client";

import {
  Dialog,
  DialogContent,
} from "@/components/ui/dialog";
import { ReportForm } from "./ReportForm";
import type { Station } from "@/types/metro";

interface Props {
  station: Station | null;
  open: boolean;
  onClose: () => void;
}

export function ReportModal({ station, open, onClose }: Props) {
  if (!station) return null;

  return (
    <Dialog open={open} onOpenChange={(o) => { if (!o) onClose(); }}>
      <DialogContent>
        <ReportForm station={station} onClose={onClose} />
      </DialogContent>
    </Dialog>
  );
}
