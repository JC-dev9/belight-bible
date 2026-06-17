import type { Metadata } from "next";

import { AppSection } from "@/components/marketing/app-section";
import { Showcase } from "@/components/marketing/showcase";
import { PageHeader } from "@/components/layout/page-header";

export const metadata: Metadata = {
  title: "Obter a app",
  description:
    "Descarregue a app Belight Bible para iOS e Android. Bíblia, destaques, notas, planos e estudo com IA, sincronizados com o site.",
};

export default function AppPage() {
  return (
    <>
      <PageHeader
        eyebrow="iOS e Android"
        title="Tenha a Belight Bible no seu telemóvel"
        subtitle="Grátis nas lojas. Leia, destaque, anote e estude — em qualquer lugar."
      />
      <AppSection />
      <Showcase />
    </>
  );
}
