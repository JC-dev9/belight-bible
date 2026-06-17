import { Container } from "@/components/ui/container";
import { Reveal } from "@/components/ui/reveal";
import { steps } from "@/lib/site";

/**
 * "Como funciona" em 3 passos numerados. Linha-guia connecta os passos no
 * desktop, reforçando a sequência de forma minimalista.
 */
export function Steps() {
  return (
    <section className="py-20 lg:py-28">
      <Container>
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="text-balance font-serif text-3xl font-medium tracking-tight sm:text-4xl">
            Comece em três passos
          </h2>
          <p className="mt-4 text-pretty text-muted-foreground">
            Da primeira leitura ao estudo sincronizado, sem fricção.
          </p>
        </Reveal>

        <div className="relative mt-16 grid gap-12 lg:grid-cols-3 lg:gap-8">
          {/* Linha-guia (apenas desktop, decorativa). */}
          <div
            aria-hidden
            className="absolute left-0 right-0 top-6 hidden h-px bg-border lg:block"
          />
          {steps.map((step, i) => (
            <Reveal
              key={step.title}
              delay={i * 120}
              className="relative flex flex-col items-center text-center"
            >
              <span className="flex size-12 items-center justify-center rounded-full border border-border bg-background text-lg font-semibold text-brand">
                {i + 1}
              </span>
              <h3 className="mt-5 text-lg font-semibold tracking-tight">
                {step.title}
              </h3>
              <p className="mt-2 max-w-xs text-sm leading-relaxed text-muted-foreground">
                {step.description}
              </p>
            </Reveal>
          ))}
        </div>
      </Container>
    </section>
  );
}
