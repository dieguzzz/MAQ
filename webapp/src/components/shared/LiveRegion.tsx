"use client";

import { useEffect, useRef } from "react";

interface Props {
  message: string;
  politeness?: "polite" | "assertive";
}

/** Announces dynamic content changes to screen readers */
export function LiveRegion({ message, politeness = "polite" }: Props) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!ref.current || !message) return;
    // Reset then set to trigger re-announcement
    ref.current.textContent = "";
    const t = setTimeout(() => {
      if (ref.current) ref.current.textContent = message;
    }, 50);
    return () => clearTimeout(t);
  }, [message]);

  return (
    <div
      ref={ref}
      role="status"
      aria-live={politeness}
      aria-atomic="true"
      className="sr-only"
    />
  );
}
