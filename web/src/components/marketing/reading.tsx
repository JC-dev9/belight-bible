import { Check } from "lucide-react";

import { Container } from "@/components/ui/container";
import { Reveal } from "@/components/ui/reveal";

import { PhoneFrame } from "./phone-frame";

const benefits = [
  "Tipografia pensada para leitura longa, sem cansaço.",
  "Temas claro e escuro e tamanho de letra ao seu gosto.",
  "Destaque, anote ou partilhe um versículo num toque.",
];

/** Destaque da experiência de leitura — imagem real ao lado de benefícios. */
export function Reading() {
  return (
    <section className="py-20 lg:py-28">
      <Container className="grid items-center gap-12 lg:grid-cols-2 lg:gap-16">
        <Reveal className="order-2 lg:order-1">
          <span className="text-sm font-semibold uppercase tracking-wide text-brand">
            Leitura
          </span>
          <h2 className="mt-3 font-serif text-3xl font-medium tracking-tight sm:text-4xl">
            Uma leitura limpa e focada
          </h2>
          <p className="mt-4 text-pretty text-muted-foreground">
            Tudo o que distrai sai do caminho. Fica só a Palavra — bonita,
            legível e pronta para o seu momento de estudo.
          </p>
          <ul className="mt-8 space-y-4">
            {benefits.map((benefit) => (
              <li key={benefit} className="flex items-start gap-3">
                <span className="mt-0.5 inline-flex size-6 shrink-0 items-center justify-center rounded-full bg-brand/12 text-brand">
                  <Check className="size-4" strokeWidth={2.25} />
                </span>
                <span className="text-foreground/90">{benefit}</span>
              </li>
            ))}
          </ul>
        </Reveal>

        <Reveal delay={120} className="order-1 flex justify-center lg:order-2">
          <PhoneFrame src="/app-leitura.png" alt="Leitura limpa na app Belight Bible" />
        </Reveal>
      </Container>
    </section>
  );
}
