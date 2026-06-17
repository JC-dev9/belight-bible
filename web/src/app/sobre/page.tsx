import type { Metadata } from "next";

import { PageHeader } from "@/components/layout/page-header";
import { Container } from "@/components/ui/container";
import { site } from "@/lib/site";

export const metadata: Metadata = {
  title: "Sobre",
  description: `Conheça o ${site.name}: uma forma simples e bonita de ler e estudar a Bíblia.`,
};

export default function SobrePage() {
  return (
    <>
      <PageHeader
        eyebrow="Sobre"
        title="Mais luz para a sua leitura"
        subtitle={`O ${site.name} nasceu para tornar a leitura e o estudo da Bíblia simples, bonitos e acessíveis em qualquer ecrã.`}
      />
      <Container className="prose-section mx-auto max-w-2xl space-y-6 pb-20 text-foreground/90 lg:pb-28">
        <p>
          A app móvel é o coração do projeto: leitura em várias traduções,
          destaques, anotações, planos de leitura, devocionais diários e um
          assistente de estudo com IA. Tudo pensado para o acompanhar no dia a
          dia.
        </p>
        <p>
          Este site estende essa experiência ao navegador, com leitura livre e
          sincronização opcional dos seus destaques e notas — para que o seu
          estudo o acompanhe, esteja onde estiver.
        </p>
        <p>
          O nome <strong>Belight</strong> é um convite: <em>be light</em>,
          “seja luz”. Que a Palavra ilumine cada passo do seu caminho.
        </p>
      </Container>
    </>
  );
}
