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

/** Copy do hero. Subtítulo descreve as funcionalidades reais da app. */
export const hero = {
  badge: "Disponível para iOS e Android",
  title: "Toda a Bíblia, com luz para cada dia.",
  subtitle:
    "Leia em várias traduções, destaque versículos, faça anotações e aprofunde o estudo com um assistente de IA — tudo sincronizado entre a app e o site.",
} as const;

/**
 * Funcionalidades em destaque (baseadas na app: traduções, destaques/notas,
 * estudo com IA, conexões). `icon` mapeia para um SVG em marketing/icons.
 */
export const features = [
  {
    icon: "book",
    title: "Várias traduções",
    description:
      "Leia em ACF, ARC e NTLH e compare versões da Palavra lado a lado.",
  },
  {
    icon: "highlight",
    title: "Destaques e notas",
    description:
      "Marque versículos e escreva anotações que sincronizam entre o site e a app.",
  },
  {
    icon: "ai",
    title: "Estudo com IA",
    description:
      "Tire dúvidas e aprofunde cada passagem com um assistente bíblico.",
  },
  {
    icon: "connections",
    title: "Conexões",
    description:
      "Descubra ligações entre versículos num mapa visual e estude por temas.",
  },
] as const;

export type FeatureIcon = (typeof features)[number]["icon"];

/** Números da Bíblia para a faixa de estatísticas (count-up no scroll). */
export const stats = [
  { value: 3, label: "Traduções" },
  { value: 66, label: "Livros" },
  { value: 1189, label: "Capítulos" },
  { value: 31000, label: "Versículos", suffix: "+" },
] as const;

/** Passos de "Como funciona". */
export const steps = [
  {
    title: "Descarregue a app",
    description: "Grátis na App Store e na Google Play, para iOS e Android.",
  },
  {
    title: "Leia e destaque",
    description:
      "Escolha a tradução, destaque versículos e escreva as suas anotações.",
  },
  {
    title: "Continue no site",
    description:
      "O seu estudo sincroniza e acompanha-o em qualquer ecrã, a qualquer hora.",
  },
] as const;

/** Versículo em destaque na secção de citação. */
export const quote = {
  text: "Lâmpada para os meus pés é a tua palavra, e luz para o meu caminho.",
  reference: "Salmos 119:105",
} as const;

/** Traduções disponíveis (rótulos da comparação). */
export const translations = [
  { code: "acf", label: "ACF", name: "Almeida Corrigida Fiel" },
  { code: "arc", label: "ARC", name: "Almeida Revista e Corrigida" },
  { code: "ntlh", label: "NTLH", name: "Nova Tradução na Linguagem de Hoje" },
] as const;

/**
 * Versículos para a secção de comparação (texto real dos assets da app).
 * Chaves coincidem com translations[].code.
 */
export const compareVerses = [
  {
    ref: "João 3:16",
    acf: "Porque Deus amou o mundo de tal maneira que deu o seu Filho unigênito, para que todo aquele que nele crê não pereça, mas tenha a vida eterna.",
    arc: "Porque Deus amou o mundo de tal maneira que deu o seu Filho unigênito, para que todo aquele que nele crê não pereça, mas tenha a vida eterna.",
    ntlh: "Porque Deus amou o mundo tanto, que deu o seu único Filho, para que todo aquele que nele crer não morra, mas tenha a vida eterna.",
  },
  {
    ref: "Salmos 23:1",
    acf: "O SENHOR é o meu pastor, nada me faltará.",
    arc: "O SENHOR é o meu pastor; nada me faltará.",
    ntlh: "O SENHOR é o meu pastor: nada me faltará.",
  },
  {
    ref: "Filipenses 4:13",
    acf: "Posso todas as coisas em Cristo que me fortalece.",
    arc: "Posso todas as coisas naquele que me fortalece.",
    ntlh: "Com a força que Cristo me dá, posso enfrentar qualquer situação.",
  },
] as const;

/** Capturas reais da app para a galeria (ficheiros em /public). */
export const appScreens = [
  {
    src: "/app-chat.png",
    title: "Estudo com IA",
    caption: "Pergunte e aprofunde cada passagem com o assistente bíblico.",
  },
  {
    src: "/app-devocional.png",
    title: "Devocional diário",
    caption: "Uma palavra para começar o dia com propósito.",
  },
  {
    src: "/app-planos.png",
    title: "Planos de leitura",
    caption: "Avance pela Bíblia, dia após dia, ao seu ritmo.",
  },
] as const;

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
