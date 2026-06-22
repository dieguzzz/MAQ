import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils/cn";

const badgeVariants = cva(
  "inline-flex items-center gap-1.5 rounded-[var(--radius-full)] border px-2.5 py-0.5 text-xs font-semibold transition-colors",
  {
    variants: {
      variant: {
        default:
          "border-transparent bg-[var(--brand-primary)] text-white",
        secondary:
          "border-transparent bg-[var(--muted)] text-[var(--muted-foreground)]",
        destructive:
          "border-transparent bg-[var(--destructive)] text-white",
        warning:
          "border-transparent bg-[var(--warning)] text-white",
        success:
          "border-transparent bg-[var(--success)] text-white",
        outline:
          "border-[var(--border)] text-[var(--foreground)]",
        "status-normal":
          "border-transparent bg-[var(--status-normal-bg)] text-[var(--status-normal)]",
        "status-moderado":
          "border-transparent bg-[var(--status-moderado-bg)] text-[var(--status-moderado)]",
        "status-lleno":
          "border-transparent bg-[var(--status-lleno-bg)] text-[var(--status-lleno)]",
        "status-cerrado":
          "border-transparent bg-[var(--status-cerrado-bg)] text-[var(--status-cerrado)]",
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {
  icon?: React.ReactNode;
}

function Badge({ className, variant, icon, children, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props}>
      {icon && <span className="shrink-0 [&>svg]:h-3 [&>svg]:w-3">{icon}</span>}
      {children}
    </div>
  );
}

export { Badge, badgeVariants };
