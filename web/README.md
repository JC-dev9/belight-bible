# Belight Bible — Website

Landing de divulgação da marca + leitor bíblico, em **Next.js 16 (App Router) + Tailwind v4**.
Partilha o **mesmo projeto Supabase** da app Flutter (auth, RLS, dados). A app mobile é o produto principal.

## Stack

- **Next.js 16** (App Router, Turbopack) + **React 19**
- **Tailwind CSS v4** — tokens da marca em `src/app/globals.css`
- **Supabase** (`@supabase/ssr`) — auth e dados, projeto partilhado com a app
- Deploy: **Vercel**

## Estrutura

```
src/
  app/                      Rotas (App Router)
    layout.tsx              Layout raiz: metadata, header, footer
    page.tsx                Landing
    globals.css             Tokens da marca (cores, raios)
  components/
    layout/                 SiteHeader, SiteFooter
    ui/                     Primitivos reutilizáveis (Button, Container)
  lib/
    env.ts                  Acesso validado a variáveis de ambiente
    site.ts                 Constantes da marca, navegação, links das lojas
    cn.ts                   Utilitário de classes
    supabase/
      client.ts             Cliente para Componentes de Cliente (browser)
      server.ts             Cliente para Server Components/Actions (cookies async)
      proxy.ts              Renovação de sessão (usado pelo proxy raiz)
  proxy.ts                  Proxy do Next 16 (ex-middleware): renova a sessão
```

Convenções: TypeScript em tudo, imports via alias `@/*`, constantes centralizadas
em `lib/site.ts` (DRY), componentes pequenos e reutilizáveis.

> **Nota Next 16:** o antigo `middleware.ts` chama-se agora `proxy.ts` e exporta
> uma função `proxy`. `cookies()` é assíncrono.

## Desenvolvimento

```bash
npm run dev      # servidor de dev (http://localhost:3000)
npm run build    # build de produção (corre TypeScript)
npm run lint     # ESLint
```

## Variáveis de ambiente

Copiar `.env.example` para `.env.local` e preencher (a `.env.local` já existe
localmente, gerada a partir do `.env` da raiz):

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` (publishable key — pública; o RLS protege os dados)

## Deploy (Vercel)

1. Importar o repositório na Vercel e definir **Root Directory = `web/`**.
2. Configurar as duas variáveis de ambiente acima no projeto Vercel.
3. Apontar o domínio nas definições do projeto.

Build/Output são detetados automaticamente (Next.js).
