import type { NextRequest } from "next/server";

import { updateSession } from "@/lib/supabase/proxy";

/**
 * Proxy do Next 16 (sucessor do middleware). Renova a sessão Supabase.
 * O matcher exclui assets estáticos para não correr onde não é preciso.
 */
export async function proxy(request: NextRequest) {
  return updateSession(request);
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)",
  ],
};
