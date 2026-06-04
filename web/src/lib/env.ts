/**
 * Acesso centralizado e validado às variáveis de ambiente.
 * Falha cedo e com mensagem clara se faltar configuração, em vez de erros
 * obscuros em runtime. Importar daqui — nunca ler process.env espalhado.
 */
function required(name: string, value: string | undefined): string {
  if (!value) {
    throw new Error(
      `Variável de ambiente em falta: ${name}. Define-a em web/.env.local (ver .env.example).`,
    );
  }
  return value;
}

export const env = {
  supabaseUrl: required(
    "NEXT_PUBLIC_SUPABASE_URL",
    process.env.NEXT_PUBLIC_SUPABASE_URL,
  ),
  supabaseAnonKey: required(
    "NEXT_PUBLIC_SUPABASE_ANON_KEY",
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  ),
} as const;
