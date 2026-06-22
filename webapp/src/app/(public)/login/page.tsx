import type { Metadata } from "next";
import { LoginForm } from "@/features/auth/components/LoginForm";

export const metadata: Metadata = { title: "Iniciar sesión" };

export default function LoginPage() {
  return (
    <main className="relative flex min-h-[100dvh] items-center justify-center overflow-hidden bg-[#0A1628]">
      {/* Animated metro lines background */}
      <div className="absolute inset-0 opacity-20" aria-hidden="true">
        <div className="absolute top-[20%] left-0 right-0 h-[2px] bg-gradient-to-r from-transparent via-[var(--metro-line-1)] to-transparent animate-[slide-line_8s_ease-in-out_infinite]" />
        <div className="absolute top-[45%] left-0 right-0 h-[2px] bg-gradient-to-r from-transparent via-[var(--metro-line-2)] to-transparent animate-[slide-line_10s_ease-in-out_infinite_1s]" />
        <div className="absolute top-[70%] left-0 right-0 h-[2px] bg-gradient-to-r from-transparent via-[var(--metro-line-3)] to-transparent animate-[slide-line_12s_ease-in-out_infinite_2s]" />
      </div>

      {/* Radial glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full bg-[var(--metro-line-1)]/8 blur-[100px]" aria-hidden="true" />

      <LoginForm />
    </main>
  );
}
