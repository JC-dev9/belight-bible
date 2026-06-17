-- Conteúdo bíblico do website, isolado num schema próprio: `bible`.
-- ADITIVO E ISOLADO: cria um schema novo e tabelas novas; não altera nem lê
-- nenhuma tabela existente (notes, highlights, profiles, etc. ficam intactas).
-- A app Flutter continua a ler a Bíblia dos assets locais — não toca aqui.
--
-- Separação por schema (em vez de prefixo em `public`): deixa explícito que
--   - schema `bible`  = conteúdo de leitura pública (versões/livros/versículos)
--   - schema `public` = a app + dados de utilizador (partilhados app<->site)
--
-- Reversível: para desfazer, basta
--   drop schema if exists bible cascade;

create schema if not exists bible;

grant usage on schema bible to anon, authenticated, service_role;

-- Traduções disponíveis (acf, arc, ntlh).
create table if not exists bible.versions (
  code        text primary key,            -- 'acf'
  name        text not null,               -- 'Almeida Corrigida Fiel'
  language    text not null default 'pt',
  sort_order  int  not null default 0
);

-- Livros: 66, estáveis entre traduções.
-- name = a MESMA string que a app grava em notes.book/highlights.book
-- (ex.: 'Gênesis'), para o sync web<->app casar.
-- slug = identificador ASCII para os URLs do site (ex.: 'genesis').
create table if not exists bible.books (
  abbrev        text primary key,          -- 'Gn'
  name          text not null unique,      -- 'Gênesis'  (chave de sync)
  slug          text not null unique,      -- 'genesis'  (URLs)
  testament     text not null check (testament in ('AT', 'NT')),
  position      int  not null unique,      -- 1..66 (ordem canónica)
  chapter_count int  not null              -- contagem canónica (ACF/ARC)
);

-- Versículos.
create table if not exists bible.verses (
  version_code text not null references bible.versions(code) on delete cascade,
  book_abbrev  text not null references bible.books(abbrev)  on delete cascade,
  chapter      int  not null,
  verse        int  not null,
  text         text not null,
  primary key (version_code, book_abbrev, chapter, verse)
);

-- Índice para carregar um capítulo inteiro de uma vez.
create index if not exists verses_chapter_idx
  on bible.verses (version_code, book_abbrev, chapter);

-- Pesquisa full-text em português.
alter table bible.verses
  add column if not exists fts tsvector
  generated always as (to_tsvector('portuguese', text)) stored;
create index if not exists verses_fts_idx
  on bible.verses using gin (fts);

-- RLS: leitura pública (anónimos + autenticados). Escrita só via service_role
-- (usado pelo script de seed) — utilizadores normais não inserem/editam.
alter table bible.versions enable row level security;
alter table bible.books    enable row level security;
alter table bible.verses   enable row level security;

grant select on bible.versions, bible.books, bible.verses to anon, authenticated;

drop policy if exists "versions_public_read" on bible.versions;
create policy "versions_public_read"
  on bible.versions for select using (true);

drop policy if exists "books_public_read" on bible.books;
create policy "books_public_read"
  on bible.books for select using (true);

drop policy if exists "verses_public_read" on bible.verses;
create policy "verses_public_read"
  on bible.verses for select using (true);
