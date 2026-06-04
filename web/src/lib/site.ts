/**
 * Constantes da marca e navegação do site.
 * Fonte única — componentes (header, footer, metadata, SEO) leem daqui.
 */
export const site = {
  name: "Belight Bible",
  tagline: "Leia, destaque e estude a Bíblia em Português.",
  description:
    "Leia a Bíblia em várias traduções, destaque versículos, faça anotações e estude com IA. Sincroniza com a app Belight Bible no seu telemóvel.",
  url: "https://belightbible.com", // ajustar no deploy
  locale: "pt_PT",
} as const;

/** Links das lojas para a secção "Obter a app". Preencher no lançamento. */
export const appStores = {
  appStore: "", // https://apps.apple.com/app/...
  playStore: "", // https://play.google.com/store/apps/details?id=...
} as const;

/** Navegação principal do site. */
export const mainNav = [
  { label: "Bíblia", href: "/biblia" },
  { label: "Obter a app", href: "/app" },
  { label: "Sobre", href: "/sobre" },
] as const;

/** Ligações do rodapé. */
export const footerNav = [
  { label: "Privacidade", href: "/privacidade" },
  { label: "Termos", href: "/termos" },
] as const;
