// Seed da Bíblia: lê os JSON em assets/bible e povoa as tabelas do schema
// `bible` no Supabase (bible.versions, bible.books, bible.verses). Operação
// ÚNICA e idempotente (usa upsert — correr duas vezes não duplica nada).
//
// Pré-requisitos:
//   1. Aplicar primeiro a migration supabase/migrations/20260604_bible_tables.sql.
//   2. Exportar a SERVICE ROLE KEY (Supabase > Settings > API > service_role).
//      A service_role ignora o RLS — necessária para inserir. NUNCA a uses no
//      site nem a versiones; é só para este script, corrido localmente.
//
// Como correr (a partir de web/):
//   SUPABASE_SERVICE_ROLE_KEY=sb_secret_xxx node scripts/seed-bible.mjs
//
// A NEXT_PUBLIC_SUPABASE_URL é lida de web/.env.local automaticamente.

import { readFileSync } from "node:fs";

import { createClient } from "@supabase/supabase-js";

const ROOT = new URL("../../", import.meta.url); // raiz do repositório
const ASSETS = new URL("assets/bible/", ROOT);

// --- Metadados das traduções (ordem de apresentação no site) ---
const VERSIONS = [
  { code: "acf", name: "Almeida Corrigida Fiel", sort_order: 0 },
  { code: "arc", name: "Almeida Revista e Corrigida", sort_order: 1 },
  { code: "ntlh", name: "Nova Tradução na Linguagem de Hoje", sort_order: 2 },
];

// Contagem de versículos esperada por tradução (sanity check final).
const EXPECTED_VERSES = { acf: 31102, arc: 31105, ntlh: 31102 };

const BATCH = 1000;

// --- Helpers ---
const readBible = (code) =>
  JSON.parse(readFileSync(new URL(`${code}.json`, ASSETS), "utf8"));

const slugify = (s) =>
  s
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");

const verseText = (v) => (Array.isArray(v) ? v.join(" ") : String(v));

function loadEnv() {
  const url = parseEnvFile(new URL("web/.env.local", ROOT))?.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url) throw new Error("NEXT_PUBLIC_SUPABASE_URL não encontrada em web/.env.local");
  if (!key) throw new Error("Falta SUPABASE_SERVICE_ROLE_KEY no ambiente (ver topo do ficheiro).");
  return { url, key };
}

function parseEnvFile(fileUrl) {
  try {
    const out = {};
    for (const line of readFileSync(fileUrl, "utf8").split("\n")) {
      const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
      if (m) out[m[1]] = m[2].trim();
    }
    return out;
  } catch {
    return null;
  }
}

async function upsert(supabase, table, rows, onConflict) {
  for (let i = 0; i < rows.length; i += BATCH) {
    const chunk = rows.slice(i, i + BATCH);
    const { error } = await supabase.from(table).upsert(chunk, { onConflict });
    if (error) throw new Error(`Erro em ${table} [${i}]: ${error.message}`);
    process.stdout.write(`\r  ${table}: ${Math.min(i + BATCH, rows.length)}/${rows.length}`);
  }
  process.stdout.write("\n");
}

async function main() {
  const { url, key } = loadEnv();
  // db.schema: as tabelas vivem no schema `bible`, não em `public`.
  const supabase = createClient(url, key, {
    auth: { persistSession: false },
    db: { schema: "bible" },
  });

  // A ACF é a fonte canónica para nomes, ordem e contagem de capítulos.
  const canonical = readBible("acf");

  // 1) Traduções
  console.log("→ Traduções");
  await upsert(supabase, "versions", VERSIONS, "code");

  // 2) Livros
  console.log("→ Livros (66)");
  const books = canonical.map((b, i) => ({
    abbrev: b.abbrev,
    name: b.name,
    slug: slugify(b.name),
    testament: i < 39 ? "AT" : "NT",
    position: i + 1,
    chapter_count: b.chapters.length,
  }));
  await upsert(supabase, "books", books, "abbrev");

  // 3) Versículos (por tradução)
  for (const { code } of VERSIONS) {
    console.log(`→ Versículos: ${code}`);
    const bible = readBible(code);
    const rows = [];
    for (const book of bible) {
      book.chapters.forEach((chapter, ci) => {
        chapter.forEach((v, vi) => {
          rows.push({
            version_code: code,
            book_abbrev: book.abbrev,
            chapter: ci + 1,
            verse: vi + 1,
            text: verseText(v),
          });
        });
      });
    }
    await upsert(supabase, "verses", rows, "version_code,book_abbrev,chapter,verse");
  }

  // 4) Validação
  console.log("→ Validação de contagens");
  let ok = true;
  for (const { code } of VERSIONS) {
    const { count, error } = await supabase
      .from("verses")
      .select("*", { count: "exact", head: true })
      .eq("version_code", code);
    if (error) throw error;
    const expected = EXPECTED_VERSES[code];
    const mark = count === expected ? "✓" : "✗";
    if (count !== expected) ok = false;
    console.log(`  ${mark} ${code}: ${count} (esperado ${expected})`);
  }
  console.log(ok ? "\n✅ Seed concluído com sucesso." : "\n⚠️  Contagens não batem — verificar.");
  if (!ok) process.exitCode = 1;
}

main().catch((e) => {
  console.error("\n❌", e.message);
  process.exit(1);
});
