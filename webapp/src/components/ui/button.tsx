import * as React from "react";
import { Slot } from "@radix-ui/react-slot";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils/cn";

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-[var(--radius)] text-sm font-medium transition-[colors,transform] duration-[var(--transition-fast)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--ring)] focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 active:scale-[0.97]",
  {
    variants: {
      variant: {
        default:
          "bg-[var(--brand-primary)] text-white shadow-[var(--shadow-sm)] hover:bg-[var(--brand-primary-hover)]",
        metro:
          "bg-gradient-to-b from-[var(--brand-primary)] to-[var(--brand-primary-hover)] text-white shadow-[var(--shadow-brand)] hover:shadow-[var(--shadow-float)]",
        accent:
          "bg-[var(--brand-accent)] text-[var(--foreground)] font-semibold shadow-[var(--shadow-sm)] hover:bg-[var(--brand-accent-hover)]",
        destructive:
          "bg-[var(--destructive)] text-white shadow-sm hover:opacity-90",
        outline:
          "border border-[var(--border)] bg-transparent shadow-sm hover:bg-[var(--muted)]",
        secondary:
          "bg-[var(--muted)] text-[var(--foreground)] shadow-sm hover:opacity-80",
        ghost: "hover:bg-[var(--muted)] hover:text-[var(--foreground)]",
        link: "text-[var(--brand-primary)] underline-offset-4 hover:underline active:scale-100",
      },
      size: {
        default: "h-11 px-4 py-2",
        sm: "h-9 rounded-[var(--radius-sm)] px-3 text-xs",
        lg: "h-12 rounded-[var(--radius-md)] px-8 text-base",
        icon: "h-11 w-11",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button";
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

export { Button, buttonVariants };
