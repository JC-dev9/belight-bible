import Image from "next/image";

import { Container } from "@/components/ui/container";
import { Reveal } from "@/components/ui/reveal";
import { quote } from "@/lib/site";

/**
 * Citação de versículo em destaque (inspiração bible.com): tipografia ampla,
 * muito whitespace, símbolo da marca a flutuar como assinatura visual.
 */
export function Quote() {
  return (
    <section className="border-t border-border bg-muted/30 py-24 lg:py-32">
      <Container>
        <Reveal className="mx-auto flex max-w-3xl flex-col items-center text-center">
          <Image
            src="/logo.png"
            alt=""
            width={56}
            height={56}
            className="size-14 animate-float motion-reduce:animate-none"
          />
          <blockquote className="mt-8 text-balance font-serif text-2xl font-medium italic leading-snug tracking-tight sm:text-3xl lg:text-4xl">
            “{quote.text}”
          </blockquote>
          <cite className="mt-6 text-sm font-semibold not-italic uppercase tracking-wide text-brand">
            {quote.reference}
          </cite>
        </Reveal>
      </Container>
    </section>
  );
}
