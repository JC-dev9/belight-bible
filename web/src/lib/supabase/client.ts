import { createBrowserClient } from "@supabase/ssr";

import { env } from "@/lib/env";

/**
 * Cliente Supabase para Componentes de Cliente (browser).
 * Usa a publishable/anon key — segura para o cliente; o RLS protege os dados.
 */
export function createClient() {
  return createBrowserClient(env.supabaseUrl, env.supabaseAnonKey);
}
