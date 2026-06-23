"use client";

import { useTheme } from "next-themes";
import { Sun, Moon, Contrast } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useEffect, useState } from "react";

export function ThemeToggle() {
  const { theme, setTheme } = useTheme();
  // Avoid hydration mismatch: render null until client mounts
  const [mounted, setMounted] = useState(false);
  // eslint-disable-next-line react-hooks/set-state-in-effect
  useEffect(() => { setMounted(true); }, []);
  if (!mounted) return null;

  const next = theme === "light" ? "dark" : theme === "dark" ? "high-contrast" : "light";
  const icon =
    theme === "light" ? <Sun className="h-4 w-4" /> :
    theme === "dark" ? <Moon className="h-4 w-4" /> :
    <Contrast className="h-4 w-4" />;

  return (
    <Button
      variant="ghost"
      size="icon"
      onClick={() => setTheme(next)}
      aria-label="Cambiar tema"
    >
      {icon}
    </Button>
  );
}
