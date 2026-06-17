"use client";

import Link from "next/link";
import { useState } from "react";

import { Button } from "@/components/ui/button";
import { cn } from "@/lib/cn";
import { mainNav } from "@/lib/site";

/** Navegação mobile: botão hambúrguer que abre um painel deslizante. */
export function MobileNav() {
  const [open, setOpen] = useState(false);

  return (
    <div className="md:hidden">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        aria-label={open ? "Fechar menu" : "Abrir menu"}
        aria-expanded={open}
        className="inline-flex size-9 items-center justify-center rounded-full border border-border text-foreground transition-colors hover:bg-muted"
      >
        <span className="relative block h-3.5 w-4.5">
          <span
            className={cn(
              "absolute left-0 top-0 h-0.5 w-full rounded-full bg-current transition-transform duration-300",
              open && "top-1.5 rotate-45",
            )}
          />
          <span
            className={cn(
              "absolute left-0 top-1.5 h-0.5 w-full rounded-full bg-current transition-opacity duration-200",
              open && "opacity-0",
            )}
          />
          <span
            className={cn(
              "absolute bottom-0 left-0 h-0.5 w-full rounded-full bg-current transition-transform duration-300",
              open && "bottom-1.5 -rotate-45",
            )}
          />
        </span>
      </button>

      {/* Painel */}
      <div
        className={cn(
          "fixed inset-x-0 top-16 z-40 origin-top border-b border-border bg-background/95 backdrop-blur transition-[opacity,transform] duration-300",
          open
            ? "pointer-events-auto opacity-100"
            : "pointer-events-none -translate-y-2 opacity-0",
        )}
      >
        <nav className="flex flex-col gap-1 px-4 py-4">
          {mainNav.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              onClick={() => setOpen(false)}
              className="rounded-lg px-3 py-3 text-base font-medium text-foreground transition-colors hover:bg-muted"
            >
              {item.label}
            </Link>
          ))}
          <Button href="/app" size="lg" className="mt-2" onClick={() => setOpen(false)}>
            Obter a app
          </Button>
        </nav>
      </div>
    </div>
  );
}
