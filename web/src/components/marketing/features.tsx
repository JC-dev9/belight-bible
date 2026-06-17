import { Container } from "@/components/ui/container";
import { Reveal } from "@/components/ui/reveal";
import { features } from "@/lib/site";

import { featureIcons } from "./icons";

/**
 * Secção de funcionalidades. Cada cartão é revelado ao entrar no viewport
 * (Reveal) com stagger crescente, criando uma cascata fluida no scroll.
 */
export function Features() {
  return (
    <section className="border-t border-border bg-muted/30 py-20 lg:py-28">
      <Container>
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="text-balance font-serif text-3xl font-medium tracking-tight sm:text-4xl">
            Tudo o que precisa para estudar a Palavra
          </h2>
          <p className="mt-4 text-pretty text-muted-foreground">
            As mesmas ferramentas da app, agora também no navegador — e a
            sincronizar com o seu telemóvel.
          </p>
        </Reveal>

        <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {features.map((feature, i) => {
            const Icon = featureIcons[feature.icon];
            return (
              <Reveal key={feature.title} delay={i * 90}>
                <article className="h-full rounded-[var(--radius-base)] border border-border bg-card p-6 transition-[transform,box-shadow] duration-300 will-change-transform hover:-translate-y-1 hover:shadow-lg">
                  <span className="inline-flex size-11 items-center justify-center rounded-xl bg-brand/12 text-brand">
                    <Icon className="size-[1.35rem]" strokeWidth={1.75} />
                  </span>
                  <h3 className="mt-4 text-lg font-semibold tracking-tight">
                    {feature.title}
                  </h3>
                  <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
                    {feature.description}
                  </p>
                </article>
              </Reveal>
            );
          })}
        </div>
      </Container>
    </section>
  );
}
