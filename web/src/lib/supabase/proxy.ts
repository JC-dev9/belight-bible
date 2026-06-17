import { NextResponse, type NextRequest } from "next/server";

import { createServerClient } from "@supabase/ssr";

import { env } from "@/lib/env";

/**
 * Renova a sessão Supabase a cada pedido e reescreve os cookies de auth.
 * Invocado pelo proxy raiz (src/proxy.ts — o antigo middleware, renomeado
 * no Next 16). Não fazer fetch de dados pesado aqui.
 */
export async function updateSession(request: NextRequest) {
  let response = NextResponse.next({ request });

  const supabase = createServerClient(env.supabaseUrl, env.supabaseAnonKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        for (const { name, value } of cookiesToSet) {
          request.cookies.set(name, value);
        }
        response = NextResponse.next({ request });
        for (const { name, value, options } of cookiesToSet) {
          response.cookies.set(name, value, options);
        }
      },
    },
  });

  // Toca na sessão para forçar a renovação dos tokens, se necessário.
  await supabase.auth.getUser();

  return response;
}
