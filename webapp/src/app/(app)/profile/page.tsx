import type { Metadata } from "next";

export const metadata: Metadata = { title: "Mi Perfil" };

export default function ProfilePage() {
  return (
    <div className="mx-auto max-w-xl p-6">
      <h1 className="mb-4 text-2xl font-bold">Mi Perfil</h1>
      <p className="text-[var(--muted-foreground)]">Puntos, badges y nivel de reputación.</p>
    </div>
  );
}
