"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { authService } from "../services/auth.service";
import { Button } from "@/components/ui/button";
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";

export function LoginForm() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleGoogle = async () => {
    setLoading(true);
    setErrorMsg(null);
    try {
      await authService.signInWithGoogle();
      router.replace("/map");
    } catch {
      setErrorMsg("Error al iniciar sesión. Intenta de nuevo.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card className="w-full max-w-sm">
      <CardHeader className="text-center">
        <div className="mb-2 text-5xl">🚇</div>
        <CardTitle className="text-2xl">MetroPTY</CardTitle>
        <CardDescription>
          Estado del Metro de Panamá en tiempo real
        </CardDescription>
      </CardHeader>

      <CardContent>
        {errorMsg && (
          <p className="mb-4 rounded-[var(--radius)] bg-red-50 p-3 text-sm text-red-600">
            {errorMsg}
          </p>
        )}
        <Button
          className="w-full"
          onClick={handleGoogle}
          disabled={loading}
        >
          {loading ? "Iniciando..." : "Continuar con Google"}
        </Button>
      </CardContent>

      <CardFooter>
        <p className="w-full text-center text-xs text-[var(--muted-foreground)]">
          Al continuar aceptas los términos de uso y política de privacidad.
        </p>
      </CardFooter>
    </Card>
  );
}
