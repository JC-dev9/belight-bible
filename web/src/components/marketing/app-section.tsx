import QRCode from "qrcode";

import { Container } from "@/components/ui/container";
import { Reveal } from "@/components/ui/reveal";
import { site } from "@/lib/site";

import { PhoneFrame } from "./phone-frame";
import { StoreButtons } from "./store-buttons";

/**
 * Secção "Obter a app": QR real (gerado em build, sem rede) que aponta para o
 * site, botões das lojas e um ecrã da app. Server Component assíncrono.
 */
export async function AppSection() {
  const qrSvg = await QRCode.toString(site.url, {
    type: "svg",
    margin: 0,
    color: { dark: "#1a1715", light: "#00000000" },
  });

  return (
    <section id="app" className="scroll-mt-20 border-t border-border py-20 lg:py-28">
      <Container className="grid items-center gap-12 lg:grid-cols-2 lg:gap-16">
        <Reveal>
          <span className="text-sm font-semibold uppercase tracking-wide text-brand">
            Obter a app
          </span>
          <h2 className="mt-3 font-serif text-3xl font-medium tracking-tight sm:text-4xl lg:text-5xl">
            Leve a Belight Bible consigo
          </h2>
          <p className="mt-4 max-w-md text-pretty text-muted-foreground">
            Descarregue gratuitamente e tenha a Bíblia, os seus destaques, notas
            e planos sempre à mão — sincronizados com o site.
          </p>

          <StoreButtons className="mt-8" />

          <div className="mt-8 flex items-center gap-4">
            <div className="rounded-xl border border-border bg-white p-3">
              <div
                className="size-24 [&>svg]:size-full"
                dangerouslySetInnerHTML={{ __html: qrSvg }}
              />
            </div>
            <p className="max-w-[12rem] text-sm text-muted-foreground">
              Aponte a câmara do telemóvel para descarregar.
            </p>
          </div>
        </Reveal>

        <Reveal delay={120} className="flex justify-center">
          <PhoneFrame
            src="/app-chat.png"
            alt="App Belight Bible no telemóvel"
            className="animate-float motion-reduce:animate-none"
          />
        </Reveal>
      </Container>
    </section>
  );
}
