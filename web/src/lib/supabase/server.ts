import { cookies } from "next/headers";

import { createServerClient } from "@supabase/ssr";

import { env } from "@/lib/env";

/**
 * Cliente Supabase para Server Components, Server Actions e Route Handlers.
 * No Next 16, cookies() é assíncrono — daí o await.
 * O setAll pode ser chamado durante o render de um Server Component (cookies
 * só de leitura); nesse caso ignoramos — a sessão é renovada no proxy.
 */
export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(env.supabaseUrl, env.supabaseAnonKey, {
    cookies: {
      getAll() {
        return cookieStore.getAll();
      },
      setAll(cookiesToSet) {
        try {
          for (const { name, value, options } of cookiesToSet) {
            cookieStore.set(name, value, options);
          }
        } catch {
          // Chamado a partir de um Server Component — sem write de cookies.
          // O proxy.ts trata da renovação da sessão.
        }
      },
    },
  });
}
