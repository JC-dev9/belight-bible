import type { Metadata } from "next";

import { PageHeader } from "@/components/layout/page-header";
import { Container } from "@/components/ui/container";
import { site } from "@/lib/site";

const supportEmail = "juanloza.dev@gmail.com";
const developer = "Juan Loza";

export const metadata: Metadata = {
  title: "Eliminação de Conta",
  description: `Como eliminar a sua conta ${site.name} e os dados associados.`,
};

export default function DeleteAccountPage() {
  return (
    <>
      <PageHeader
        title={`Eliminação de Conta — ${site.name}`}
        subtitle={`App desenvolvida por ${developer}`}
      />
      <Container className="mx-auto max-w-2xl space-y-8 pb-20 text-foreground/90 lg:pb-28">
        <Section title="Eliminar a conta na app">
          <p>
            Pode eliminar a sua conta {site.name} a qualquer momento, diretamente na app,
            em <strong>Definições → Eliminar Conta</strong>. A ação é imediata e não requer
            qualquer pedido adicional.
          </p>
        </Section>
        <Section title="O que é eliminado">
          <p>Ao eliminar a conta, apagamos de forma permanente:</p>
          <ul className="list-disc space-y-1 pl-5">
            <li>Os dados de perfil (nome e preferências de conta).</li>
            <li>As suas notas pessoais.</li>
            <li>Os destaques e versículos favoritos.</li>
            <li>Os marcadores e o progresso de leitura guardados.</li>
          </ul>
          <p>
            Os dados de autenticação (conta Google/OAuth ou email e palavra-passe) são também
            removidos do <strong>Supabase</strong>, o serviço que usamos para autenticação e
            armazenamento.
          </p>
        </Section>
        <Section title="Prazo de retenção">
          <p>
            A conta e o acesso são desativados de imediato. As cópias residuais que possam
            existir em backups do sistema são eliminadas de forma permanente no prazo máximo de
            30 dias. Não há qualquer período de retenção adicional para além deste.
          </p>
        </Section>
        <Section title="Pedidos manuais de eliminação">
          <p>
            Se não conseguir aceder à app, pode pedir a eliminação da conta e dos dados
            associados por email para{" "}
            <a
              className="underline underline-offset-4 hover:text-foreground"
              href={`mailto:${supportEmail}?subject=Eliminação de conta — ${site.name}`}
            >
              {supportEmail}
            </a>
            . Indique o email associado à conta para podermos confirmar o pedido.
          </p>
        </Section>
        <Section title="Privacidade — em resumo">
          <p>
            O {site.name} recolhe apenas o <strong>email</strong> e o <strong>nome</strong>
            {" "}(via Google OAuth ou registo por email), além das notas, destaques e favoritos
            que escolhe guardar. Estes dados servem apenas para fornecer e sincronizar o serviço.
          </p>
          <p>
            Não vendemos nem partilhamos os seus dados, exceto com os prestadores essenciais ao
            funcionamento da app: o <strong>Supabase</strong> (autenticação e armazenamento, com
            servidores na União Europeia) e o <strong>Sentry</strong> (relatórios de erros para
            manter a app estável). Toda a comunicação é encriptada em trânsito por HTTPS/TLS.
          </p>
          <p>
            Para mais detalhes, consulte a{" "}
            <a className="underline underline-offset-4 hover:text-foreground" href="/privacidade">
              Política de Privacidade
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
