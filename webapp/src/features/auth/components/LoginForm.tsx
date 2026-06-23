"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { authService } from "../services/auth.service";
import { setSessionCookie } from "../utils/session-cookie";
import { Button } from "@/components/ui/button";

export function LoginForm() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleGoogle = async () => {
    setLoading(true);
    setErrorMsg(null);
    try {
      const cred = await authService.signInWithGoogle();
      const token = await cred.user.getIdToken();
      setSessionCookie(token);
      router.replace("/map");
    } catch {
      setErrorMsg("Error al iniciar sesión. Intenta de nuevo.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="relative z-10 flex flex-col items-center gap-8 px-6 py-12 w-full max-w-sm animate-fade-in">
      {/* Logo + tagline */}
      <div className="flex flex-col items-center gap-3 text-center">
        <span className="text-6xl" aria-hidden="true">🚇</span>
        <h1 className="text-3xl font-black tracking-tight text-white">MetroPTY</h1>
        <p className="text-[#8ba3c4] text-sm">Tu metro, en tiempo real</p>
      </div>

      {/* Error */}
      {errorMsg && (
        <p className="w-full rounded-[var(--radius)] bg-[var(--destructive)]/15 border border-[var(--destructive)]/30 p-3 text-sm text-red-400 text-center">
          {errorMsg}
        </p>
      )}

      {/* Google sign-in */}
      <Button
        className="w-full h-12 rounded-[var(--radius-full)] bg-white text-[#0f172a] font-semibold text-base hover:bg-gray-100 shadow-[var(--shadow-float)] active:scale-[0.97]"
        onClick={handleGoogle}
        disabled={loading}
      >
        <svg className="mr-2 h-5 w-5" viewBox="0 0 24 24" aria-hidden="true">
          <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/>
          <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
          <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
          <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
        </svg>
        {loading ? "Iniciando..." : "Continuar con Google"}
      </Button>

      {/* Terms */}
      <p className="text-center text-xs text-[#8ba3c4]">
        Al continuar aceptas los términos de uso y política de privacidad.
      </p>
    </div>
  );
}
