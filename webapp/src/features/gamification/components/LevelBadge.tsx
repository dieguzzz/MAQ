import { cn } from "@/lib/utils/cn";

interface Props {
  level: number;
  size?: "sm" | "md" | "lg";
  className?: string;
}

export function LevelBadge({ level, size = "md", className }: Props) {
  const sizeClasses = {
    sm: "h-6 w-6 text-xs",
    md: "h-9 w-9 text-sm",
    lg: "h-12 w-12 text-base",
  };

  return (
    <div
      className={cn(
        "flex items-center justify-center rounded-full font-black text-white",
        "bg-gradient-to-br from-[var(--brand-primary)] to-blue-700 shadow-md",
        sizeClasses[size],
        className
      )}
      aria-label={`Nivel ${level}`}
    >
      {level}
    </div>
  );
}
