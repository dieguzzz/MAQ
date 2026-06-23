import type { Metadata } from "next";
import { ProfileView } from "@/features/gamification/components/ProfileView";

export const metadata: Metadata = { title: "Mi Perfil" };

export default function ProfilePage() {
  return (
    <div className="mx-auto max-w-xl px-4 py-6">
      <div className="mb-6">
        <h1 className="text-2xl font-black tracking-tight">👤 Mi Perfil</h1>
        <p className="mt-1 text-sm text-[var(--muted-foreground)]">
          Tus logros y contribuciones al Metro de Panamá
        </p>
      </div>
      <ProfileView />
    </div>
  );
}
