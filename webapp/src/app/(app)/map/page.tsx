import type { Metadata } from "next";
import { MapClient } from "./MapClient";

export const metadata: Metadata = { title: "Mapa en Tiempo Real" };

export default function MapPage() {
  return (
    <div className="flex h-[calc(100vh-3.5rem)]">
      <MapClient />
    </div>
  );
}
