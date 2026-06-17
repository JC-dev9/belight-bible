"use client";

import { useEffect, useRef, useState } from "react";

import { cn } from "@/lib/cn";

/**
 * Revela o conteúdo quando entra no viewport (scroll-triggered).
 * - IntersectionObserver nativo (zero dependências, sem libs de animação).
 * - Transição apenas de opacity/transform → 60fps, não bloqueia a main thread.
 * - One-shot: desliga o observer após revelar (sem trabalho contínuo).
 * - Acessível: com prefers-reduced-motion, `transition-none` faz aparecer sem
 *   animação (snap instantâneo) assim que entra no viewport.
 *
 * `delay` (ms) permite escalonar (stagger) vários Reveal numa grelha.
 */
export function Reveal({
  children,
  className,
  delay = 0,
}: {
  children: React.ReactNode;
  className?: string;
  delay?: number;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [shown, setShown] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setShown(true);
          observer.disconnect();
        }
      },
      { threshold: 0.15, rootMargin: "0px 0px -10% 0px" },
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, []);

  return (
    <div
      ref={ref}
      style={{ transitionDelay: shown ? `${delay}ms` : "0ms" }}
      className={cn(
        "transition-[opacity,transform] duration-700 ease-[cubic-bezier(0.16,1,0.3,1)] motion-reduce:transition-none",
        shown ? "translate-y-0 opacity-100" : "translate-y-6 opacity-0",
        className,
      )}
    >
      {children}
    </div>
  );
}
