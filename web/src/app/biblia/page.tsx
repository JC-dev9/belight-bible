import type { Metadata } from "next";

import { PageHeader } from "@/components/layout/page-header";
import { Button } from "@/components/ui/button";
import { Container } from "@/components/ui/container";
import { translations } from "@/lib/site";

export const metadata: Metadata = {
  title: "Bíblia",
  description:
    "Leia a Bíblia em várias traduções no Belight Bible. Leitor web em breve.",
};

export default function BibliaPage() {
  return (
    <>
      <PageHeader
        eyebrow="Leitor"
        title="A Bíblia, para ler no navegador"
        subtitle="Estamos a preparar o leitor web com leitura livre e sincronização. Por agora, escolha já a app para a experiência completa."
      />
      <Container className="pb-20 lg:pb-28">
        <div className="mx-auto grid max-w-3xl gap-4 sm:grid-cols-3">
          {translations.map((t) => (
            <div
              key={t.code}
              className="rounded-[var(--radius-base)] border border-border bg-card p-6 text-center"
            >
              <div className="font-serif text-2xl font-medium text-brand">
                {t.label}
              </div>
              <p className="mt-2 text-sm text-muted-foreground">{t.name}</p>
            </div>
          ))}
        </div>
        <div className="mt-12 flex justify-center">
          <Button href="/app" size="lg">
            Obter a app
          </Button>
        </div>
      </Container>
    </>
  );
}
