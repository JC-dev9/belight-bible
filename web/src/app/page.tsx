import { Button } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { site } from "@/lib/site";

/**
 * Landing placeholder da Fase 0 — estrutura base e tokens da marca.
 * O hero completo, secções de features e mockup chegam na Fase 4.
 */
export default function HomePage() {
  return (
    <Container className="flex flex-col items-center gap-6 py-24 text-center">
      <span className="rounded-full border border-border px-3 py-1 text-xs text-muted-foreground">
        Em construção · Fase 0
      </span>
      <h1 className="max-w-2xl text-balance text-4xl font-semibold tracking-tight sm:text-5xl">
        {site.tagline}
      </h1>
      <p className="max-w-xl text-balance text-muted-foreground">
        {site.description}
      </p>
      <div className="flex flex-wrap items-center justify-center gap-3">
        <Button href="/biblia" size="lg">
          Abrir a Bíblia
        </Button>
        <Button href="/app" size="lg" variant="outline">
          Obter a app
        </Button>
      </div>
    </Container>
  );
}
