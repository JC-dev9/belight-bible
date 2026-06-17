"use client";

import { Moon, Sun } from "lucide-react";
import { useSyncExternalStore } from "react";

import { cn } from "@/lib/cn";

/**
 * Alterna tema claro/escuro. Usa useSyncExternalStore para ler o tema efetivo
 * (atributo data-theme ou preferência do sistema) sem setState em efeito.
 * O toggle escreve data-theme + localStorage e emite "themechange" para
 * notificar a store.
 */
const EVENT = "themechange";

function subscribe(callback: () => void) {
  const media = window.matchMedia("(prefers-color-scheme: dark)");
  media.addEventListener("change", callback);
  window.addEventListener(EVENT, callback);
  return () => {
    media.removeEventListener("change", callback);
    window.removeEventListener(EVENT, callback);
  };
}

function getSnapshot(): "light" | "dark" {
  const forced = document.documentElement.dataset.theme;
  if (forced === "light" || forced === "dark") return forced;
  return window.matchMedia("(prefers-color-scheme: dark)").matches
    ? "dark"
    : "light";
}

export function ThemeToggle({ className }: { className?: string }) {
  const theme = useSyncExternalStore(subscribe, getSnapshot, () => "light");
  const isDark = theme === "dark";

  function toggle() {
    const next = isDark ? "light" : "dark";
    document.documentElement.dataset.theme = next;
    try {
      localStorage.setItem("theme", next);
    } catch {}
    window.dispatchEvent(new Event(EVENT));
  }

  return (
    <button
      type="button"
      onClick={toggle}
      aria-label={isDark ? "Mudar para tema claro" : "Mudar para tema escuro"}
      className={cn(
        "inline-flex size-9 items-center justify-center rounded-full border border-border text-foreground transition-colors hover:bg-muted",
        className,
      )}
    >
      <Sun className={cn("size-[1.15rem]", isDark && "hidden")} strokeWidth={1.75} />
      <Moon className={cn("size-[1.15rem]", !isDark && "hidden")} strokeWidth={1.75} />
    </button>
  );
}
