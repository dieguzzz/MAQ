import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils/cn";

const badgeVariants = cva(
  "inline-flex items-center rounded-[var(--radius-full)] border px-2.5 py-0.5 text-xs font-semibold transition-colors",
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
      },
    },
    defaultVariants: {
      variant: "default",
    },
  }
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof badgeVariants> {}

function Badge({ className, variant, ...props }: BadgeProps) {
  return (
    <div className={cn(badgeVariants({ variant }), className)} {...props} />
  );
}

export { Badge, badgeVariants };
