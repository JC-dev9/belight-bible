import type { Metadata } from "next";

import { PageHeader } from "@/components/layout/page-header";
import { Container } from "@/components/ui/container";
import { site } from "@/lib/site";

export const metadata: Metadata = {
  title: "Termos de Utilização",
  description: `Termos de utilização do ${site.name}.`,
};

export default function TermosPage() {
  return (
    <>
      <PageHeader title="Termos de Utilização" subtitle="Última atualização: junho de 2026" />
      <Container className="mx-auto max-w-2xl space-y-8 pb-20 text-foreground/90 lg:pb-28">
        <Section title="Aceitação">
          Ao utilizar o {site.name}, concorda com estes termos. Se não
          concordar, por favor não utilize o serviço.
        </Section>
        <Section title="Utilização do serviço">
          O serviço destina-se à leitura e ao estudo pessoal da Bíblia.
          Compromete-se a não o utilizar para fins ilícitos nem a tentar
          comprometer a sua segurança ou disponibilidade.
        </Section>
        <Section title="Conta">
          É responsável por manter a confidencialidade das suas credenciais e
          por toda a atividade realizada na sua conta.
        </Section>
        <Section title="Conteúdo bíblico">
          As traduções disponibilizadas são fornecidas para uso pessoal e
          devocional, respeitando os respetivos direitos de cada tradução.
        </Section>
        <Section title="Alterações">
          Podemos atualizar estes termos. As alterações entram em vigor após a
          sua publicação nesta página.
        </Section>
      </Container>
    </>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section>
      <h2 className="font-serif text-xl font-medium tracking-tight">{title}</h2>
      <p className="mt-3 leading-relaxed text-muted-foreground">{children}</p>
    </section>
  );
}
