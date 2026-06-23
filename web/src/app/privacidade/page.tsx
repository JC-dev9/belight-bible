import type { Metadata } from "next";

import { PageHeader } from "@/components/layout/page-header";
import { Container } from "@/components/ui/container";
import { site } from "@/lib/site";

const supportEmail = "juanloza.dev@gmail.com";

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
          <p>Ao criar conta, recolhemos os dados que nos fornece diretamente:</p>
          <ul className="list-disc space-y-1 pl-5">
            <li>
              <strong>Email</strong> — para criar e gerir a sua conta.
            </li>
            <li>
              <strong>Nome</strong> (opcional) — para personalizar o seu perfil.
            </li>
          </ul>
          <p>E os dados que escolhe guardar à medida que usa a app, para os sincronizar entre a app e o site:</p>
          <ul className="list-disc space-y-1 pl-5">
            <li>Destaques de versículos e notas pessoais.</li>
            <li>Progresso de leitura e sequência de dias (streak).</li>
            <li>Planos de leitura em que se inscreveu e devocionais guardados.</li>
          </ul>
          <p>
            As preferências locais (tema, idioma) e as notificações do versículo diário ficam apenas no
            seu dispositivo e nunca são enviadas para os nossos servidores.
          </p>
        </Section>
        <Section title="Como usamos os dados">
          <p>
            Os dados servem apenas para fornecer o serviço: autenticar a sua conta, sincronizar o seu
            estudo entre dispositivos e mostrar as suas estatísticas pessoais. Não vendemos os seus dados
            nem os usamos para publicidade, marketing ou análise comportamental.
          </p>
        </Section>
        <Section title="Diagnóstico e erros">
          <p>
            Para manter a app estável, usamos o <strong>Sentry</strong> para recolher relatórios de erros
            e dados técnicos de diagnóstico (por exemplo, o tipo de dispositivo e o registo de uma falha)
            quando algo corre mal. Estes dados ajudam-nos a corrigir problemas e não são usados para o
            identificar nem para publicidade.
          </p>
        </Section>
        <Section title="Com quem partilhamos">
          <p>
            Não vendemos nem alugamos os seus dados. Recorremos apenas a prestadores de serviços
            essenciais, que processam os dados em conformidade com o RGPD:
          </p>
          <ul className="list-disc space-y-1 pl-5">
            <li>
              <strong>Supabase</strong> — armazenamento e autenticação, com servidores na União Europeia.
            </li>
            <li>
              <strong>Sentry</strong> — relatórios de erros e diagnóstico.
            </li>
          </ul>
        </Section>
        <Section title="Armazenamento e segurança">
          <p>
            Toda a comunicação é feita por HTTPS com encriptação TLS. A autenticação usa tokens seguros do
            Supabase Auth, e o acesso aos dados é protegido por regras de Row Level Security (RLS) que
            garantem que só você acede ao seu próprio conteúdo.
          </p>
        </Section>
        <Section title="Retenção dos dados">
          <p>
            Mantemos os seus dados enquanto a conta estiver ativa. Se eliminar a conta, todos os dados
            pessoais associados são apagados de forma permanente dos nossos servidores no prazo de 30 dias.
          </p>
        </Section>
        <Section title="Os seus direitos (RGPD)">
          <p>Ao abrigo do RGPD, pode a qualquer momento:</p>
          <ul className="list-disc space-y-1 pl-5">
            <li>Aceder a uma cópia dos seus dados e solicitá-los num formato portável.</li>
            <li>Corrigir os seus dados no ecrã de perfil da app.</li>
            <li>Eliminar a conta e todos os dados associados, diretamente a partir da app.</li>
            <li>Opor-se ao tratamento dos seus dados.</li>
          </ul>
        </Section>
        <Section title="Dados de menores">
          <p>
            A app não é dirigida a menores de 13 anos e não recolhemos intencionalmente os seus dados. Se
            tiver conhecimento de que um menor nos forneceu dados, contacte-nos para os eliminarmos.
          </p>
        </Section>
        <Section title="Contacto">
          <p>
            Para qualquer questão sobre privacidade, contacte-nos em{" "}
            <a className="underline underline-offset-4 hover:text-foreground" href={`mailto:${supportEmail}`}>
              {supportEmail}
            </a>
            .
          </p>
        </Section>
      </Container>
    </>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="space-y-3">
      <h2 className="font-serif text-xl font-medium tracking-tight">{title}</h2>
      <div className="space-y-3 leading-relaxed text-muted-foreground">{children}</div>
    </section>
  );
}
