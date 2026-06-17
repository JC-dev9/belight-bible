"use client";

import { useState } from "react";

import { cn } from "@/lib/cn";
import { Container } from "@/components/ui/container";
import { compareVerses, translations } from "@/lib/site";

/**
 * Comparação de traduções lado a lado (ACF/ARC/NTLH). O utilizador escolhe o
 * versículo nas pills; as colunas atualizam com transição suave de opacidade.
 * Mobile: as colunas empilham.
 */
export function Compare() {
  const [active, setActive] = useState(0);
  const verse = compareVerses[active];

  return (
    <section className="border-t border-border bg-muted/30 py-20 lg:py-28">
      <Container>
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="font-serif text-3xl font-medium tracking-tight sm:text-4xl">
            Compare as traduções
          </h2>
          <p className="mt-4 text-pretty text-muted-foreground">
            Leia o mesmo versículo em ACF, ARC e NTLH, lado a lado.
          </p>
        </div>

        {/* Selector de versículo */}
        <div className="mt-8 flex flex-wrap justify-center gap-2">
          {compareVerses.map((v, i) => (
            <button
              key={v.ref}
              type="button"
              onClick={() => setActive(i)}
              className={cn(
                "rounded-full border px-4 py-2 text-sm font-medium transition-colors",
                i === active
                  ? "border-brand bg-brand text-brand-foreground"
                  : "border-border text-muted-foreground hover:bg-muted hover:text-foreground",
              )}
            >
              {v.ref}
            </button>
          ))}
        </div>

        {/* Colunas */}
        <div className="mt-10 grid gap-4 md:grid-cols-3">
          {translations.map((t) => (
            <article
              key={t.code}
              className="flex flex-col rounded-[var(--radius-base)] border border-border bg-card p-6"
            >
              <div className="flex items-baseline justify-between">
                <span className="text-sm font-semibold text-brand">
                  {t.label}
                </span>
                <span className="text-xs text-muted-foreground">{verse.ref}</span>
              </div>
              <p
                key={`${t.code}-${active}`}
                className="mt-4 animate-rise font-serif text-lg leading-relaxed text-foreground/90"
              >
                {verse[t.code]}
              </p>
              <span className="mt-4 text-xs text-muted-foreground">{t.name}</span>
            </article>
          ))}
        </div>
      </Container>
    </section>
  );
}
