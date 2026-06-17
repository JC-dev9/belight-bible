import { BookOpen, Highlighter, Sparkles, Waypoints } from "lucide-react";
import type { LucideIcon } from "lucide-react";

import type { FeatureIcon } from "@/lib/site";

/**
 * Ícones das funcionalidades a partir do lucide (set consistente, grelha 24px,
 * traço uniforme). Indexados pela chave `icon` de site.ts.
 */
export const featureIcons: Record<FeatureIcon, LucideIcon> = {
  book: BookOpen,
  highlight: Highlighter,
  ai: Sparkles,
  connections: Waypoints,
};

/** Logótipos das lojas (o lucide não inclui marcas — desenhados à mão, limpos). */
type IconProps = { className?: string };

export function AppleIcon({ className }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" className={className} aria-hidden fill="currentColor">
      <path d="M16.37 12.78c.02 2.46 2.16 3.28 2.18 3.29-.02.06-.34 1.17-1.12 2.31-.67.99-1.37 1.97-2.47 1.99-1.08.02-1.43-.64-2.66-.64-1.24 0-1.62.62-2.64.66-1.06.04-1.87-1.07-2.55-2.05-1.39-2.01-2.45-5.67-1.02-8.15.71-1.23 1.97-2.01 3.35-2.03 1.04-.02 2.02.7 2.66.7.63 0 1.83-.87 3.08-.74.53.02 2 .21 2.95 1.62-.08.05-1.76 1.03-1.74 3.07M14.4 6.1c.56-.68.94-1.62.84-2.56-.81.03-1.79.54-2.37 1.22-.52.6-.97 1.56-.85 2.48.9.07 1.82-.46 2.38-1.14" />
    </svg>
  );
}

export function PlayIcon({ className }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" className={className} aria-hidden fill="currentColor">
      <path d="M4 3.5 19 12 4 20.5V3.5Z" />
    </svg>
  );
}
