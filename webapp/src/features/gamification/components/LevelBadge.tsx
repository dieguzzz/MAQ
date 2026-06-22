import { cn } from "@/lib/utils/cn";

interface Props {
  level: number;
  size?: "sm" | "md" | "lg";
  progress?: number;
  className?: string;
}

export function LevelBadge({ level, size = "md", progress, className }: Props) {
  const sizeClasses = {
    sm: "h-6 w-6 text-xs",
    md: "h-9 w-9 text-sm",
    lg: "h-14 w-14 text-lg",
  };

  const ringSize = { sm: 28, md: 40, lg: 60 };
  const strokeWidth = { sm: 2, md: 3, lg: 4 };
  const r = (ringSize[size] - strokeWidth[size]) / 2;
  const circ = 2 * Math.PI * r;

  return (
    <div className={cn("relative flex items-center justify-center", sizeClasses[size], className)}>
      {progress !== undefined && (
        <svg
          className="absolute inset-0"
          viewBox={`0 0 ${ringSize[size]} ${ringSize[size]}`}
          aria-hidden="true"
        >
          <circle
            cx={ringSize[size] / 2}
            cy={ringSize[size] / 2}
            r={r}
            fill="none"
            stroke="var(--muted)"
            strokeWidth={strokeWidth[size]}
          />
          <circle
            cx={ringSize[size] / 2}
            cy={ringSize[size] / 2}
            r={r}
            fill="none"
            stroke="var(--brand-accent)"
            strokeWidth={strokeWidth[size]}
            strokeDasharray={circ}
            strokeDashoffset={circ * (1 - progress)}
            strokeLinecap="round"
            transform={`rotate(-90 ${ringSize[size] / 2} ${ringSize[size] / 2})`}
            className="transition-[stroke-dashoffset] duration-700"
          />
        </svg>
      )}
      <span
        className={cn(
          "flex items-center justify-center rounded-full font-black text-white",
          "bg-gradient-to-br from-[var(--brand-primary)] to-blue-700 shadow-md",
          progress !== undefined ? (size === "sm" ? "h-4 w-4 text-[7px]" : size === "md" ? "h-6 w-6 text-[10px]" : "h-10 w-10 text-sm") : "h-full w-full"
        )}
        aria-label={`Nivel ${level}`}
      >
        {level}
      </span>
    </div>
  );
}
