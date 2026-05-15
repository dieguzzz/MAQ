"use client";

import { useAuthListener } from "@/features/auth/hooks/useAuthListener";
import type { ReactNode } from "react";

interface Props {
  children: ReactNode;
}

export function AuthProvider({ children }: Props) {
  useAuthListener();
  return <>{children}</>;
}
