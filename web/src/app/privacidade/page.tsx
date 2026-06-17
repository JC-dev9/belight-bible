import type { Metadata } from "next";

import { PageHeader } from "@/components/layout/page-header";
import { Container } from "@/components/ui/container";
import { site } from "@/lib/site";

export const metadata: Metadata = {
  title: "Política de Privacidade",
  description: `Como o ${site.name} trata os seus dados.`,
};

export default function PrivacidadePage() {
  return (
    <>
      <PageHeader title="Política de Privacidade" subtitle="Última atualização: junho de 2026" />
      <Container className="mx-auto max-w-2xl space-y-8 pb-20 text-foreground/90 lg:pb-28">
        <Section title="Dados que recolhemos">
          Ao criar conta, recolhemos o seu email e os dados que escolher
          guardar — destaques, notas e progresso de leitura — para os
          sincronizar entre a app e o site.
        </Section>
        <Section title="Como usamos os dados">
          Os dados servem apenas para fornecer o serviço: autenticação e
          sincronização do seu estudo. Não vendemos os seus dados a terceiros.
        </Section>
        <Section title="Armazenamento e segurança">
          Os dados são guardados de forma segura no Supabase, com regras de
          acesso (Row Level Security) que garantem que só você acede ao seu
          conteúdo.
        </Section>
        <Section title="Os seus direitos">
          Pode aceder, corrigir ou eliminar os seus dados a qualquer momento,
          incluindo a eliminação total da conta a partir da app.
        </Section>
        <Section title="Contacto">
          Para qualquer questão sobre privacidade, contacte-nos através do email
          de suporte indicado nas lojas de aplicações.
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
