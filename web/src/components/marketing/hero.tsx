import { Check } from "lucide-react";

import { Container } from "@/components/ui/container";
import { hero } from "@/lib/site";

import { PhoneFrame } from "./phone-frame";
import { StoreButtons } from "./store-buttons";

/**
 * Hero da landing. Entrada em fade-in-up via utility `animate-rise` (CSS puro,
 * sem JS), escalonada com [animation-delay:*] para guiar o olhar de cima para
 * baixo. Mobile-first: empilha no telemóvel, duas colunas a partir de lg.
 */
export function Hero() {
  return (
    <section className="relative overflow-hidden">
      {/* Brilho de fundo subtil (decorativo, não interativo). */}
      <div
        aria-hidden
        className="pointer-events-none absolute -top-32 left-1/2 size-[36rem] -translate-x-1/2 rounded-full bg-brand/10 blur-3xl"
      />

      <Container className="relative grid items-center gap-12 py-20 lg:grid-cols-2 lg:gap-8 lg:py-28">
        {/* Texto */}
        <div className="flex flex-col items-center text-center lg:items-start lg:text-left">
          <span className="animate-rise inline-flex items-center gap-2 rounded-full border border-border bg-muted/50 px-3 py-1 text-xs font-medium text-muted-foreground">
            <span className="relative flex size-1.5">
              <span className="absolute inline-flex size-full animate-ping rounded-full bg-brand opacity-75 motion-reduce:animate-none" />
              <span className="relative inline-flex size-1.5 rounded-full bg-brand" />
            </span>
            {hero.badge}
          </span>

          <h1 className="animate-rise mt-6 max-w-xl text-balance font-serif text-[2.6rem] font-medium leading-[1.05] tracking-tight [animation-delay:80ms] sm:text-5xl lg:text-6xl">
            {hero.title}
          </h1>

          <p className="animate-rise mt-5 max-w-lg text-pretty text-lg leading-relaxed text-muted-foreground [animation-delay:160ms]">
            {hero.subtitle}
          </p>

          <div className="animate-rise mt-8 flex flex-col items-center gap-4 [animation-delay:240ms] lg:items-start">
            <StoreButtons />
            <p className="flex flex-wrap items-center justify-center gap-x-2 gap-y-1 text-sm text-muted-foreground">
              <Check className="size-4 text-brand" strokeWidth={2.25} />
              Grátis · iOS e Android · sincroniza com o site
            </p>
          </div>
        </div>

        {/* Ecrã real da app */}
        <div className="animate-rise flex justify-center [animation-delay:200ms] lg:justify-end">
          <PhoneFrame
            src="/app-biblia.png"
            alt="Leitor da Bíblia na app Belight Bible, com versículo destacado e ações de anotar, partilhar e IA"
            priority
            className="animate-float motion-reduce:animate-none"
          />
        </div>
      </Container>
    </section>
  );
}
