import { cn } from "@/lib/cn";
import { appScreens } from "@/lib/site";
import { Container } from "@/components/ui/container";
import { Reveal } from "@/components/ui/reveal";

import { PhoneFrame } from "./phone-frame";

/**
 * Galeria de ecrãs reais da app (Chat IA, Devocional, Planos). O ecrã central
 * sobe ligeiramente em desktop para dar profundidade, ao estilo App Store.
 */
export function Showcase() {
  return (
    <section className="overflow-hidden border-t border-border py-20 lg:py-28">
      <Container>
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="text-balance font-serif text-3xl font-medium tracking-tight sm:text-4xl">
            Feita para o seu dia a dia
          </h2>
          <p className="mt-4 text-pretty text-muted-foreground">
            Estudo com IA, devocionais e planos de leitura — numa experiência
            simples e bonita.
          </p>
        </Reveal>

        <div className="mt-16 flex flex-wrap items-start justify-center gap-x-10 gap-y-14">
          {appScreens.map((screen, i) => (
            <Reveal
              key={screen.src}
              delay={i * 120}
              className={cn(
                "flex max-w-[280px] flex-col items-center text-center",
                i === 1 && "lg:-translate-y-8",
              )}
            >
              <PhoneFrame src={screen.src} alt={screen.title} />
              <h3 className="mt-7 text-lg font-semibold tracking-tight">
                {screen.title}
              </h3>
              <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                {screen.caption}
              </p>
            </Reveal>
          ))}
        </div>
      </Container>
    </section>
  );
}
