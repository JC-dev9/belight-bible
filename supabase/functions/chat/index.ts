import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY") ?? "";
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const DAILY_LIMIT = 50;

// Limites de input — protegem contra abuso de custo e prompt injection.
const MAX_MESSAGES = 20; // nº máx. de mensagens aceites por pedido
const MAX_MESSAGE_CHARS = 4000; // tamanho máx. de cada mensagem
const MAX_TOTAL_CHARS = 16000; // tamanho máx. agregado do histórico
const ALLOWED_ROLES = new Set(["user", "assistant"]);

// Timeout das chamadas aos modelos — evita funções penduradas.
const LLM_TIMEOUT_MS = 25_000;

const SUGGEST_DELIMITER = "###PERGUNTAS###";

type ChatMessage = { role: string; content: string };

/// Valida e sanitiza o array de mensagens vindo do cliente.
/// Rejeita roles não permitidos (em especial "system", que só o servidor
/// define), conteúdos vazios ou demasiado longos, e payloads excessivos.
function validateMessages(
  raw: unknown,
): { messages: ChatMessage[] } | { error: string } {
  if (!Array.isArray(raw) || raw.length === 0) {
    return { error: "É necessário um array 'messages' não vazio." };
  }
  if (raw.length > MAX_MESSAGES) {
    return { error: `Demasiadas mensagens (máximo ${MAX_MESSAGES}).` };
  }

  const messages: ChatMessage[] = [];
  let totalChars = 0;

  for (const item of raw) {
    if (typeof item !== "object" || item === null) {
      return { error: "Cada mensagem tem de ser um objeto." };
    }
    const role = (item as Record<string, unknown>).role;
    const content = (item as Record<string, unknown>).content;

    if (typeof role !== "string" || !ALLOWED_ROLES.has(role)) {
      return {
        error: "Cada mensagem tem de ter role 'user' ou 'assistant'.",
      };
    }
    if (typeof content !== "string") {
      return { error: "O conteúdo de cada mensagem tem de ser texto." };
    }
    const trimmed = content.trim();
    if (trimmed.length === 0) {
      return { error: "As mensagens não podem ser vazias." };
    }
    if (trimmed.length > MAX_MESSAGE_CHARS) {
      return {
        error: `Mensagem demasiado longa (máximo ${MAX_MESSAGE_CHARS} caracteres).`,
      };
    }
    totalChars += trimmed.length;
    if (totalChars > MAX_TOTAL_CHARS) {
      return { error: "Histórico de conversa demasiado longo." };
    }
    messages.push({ role, content: trimmed });
  }

  return { messages };
}

const BASE_SYSTEM_PROMPT = `Você é um guia de estudo bíblico — parte erudito, parte conselheiro pastoral. Domina as Escrituras, a teologia cristã, o contexto histórico-cultural e as línguas originais (Hebraico e Grego). Acompanha quem quer compreender e viver a Palavra.

## Fundamento
- Baseie TUDO nas Escrituras Sagradas e na fé cristã. Não invente versículos nem factos.
- Responda SEMPRE em Português de Portugal, com um tom caloroso, humilde e encorajador — nunca académico a frio nem distante.
- Se a pergunta for vaga, responda ao essencial e convide a aprofundar; não despeje tudo de uma vez.

## Como estruturar respostas de estudo
Quando a pergunta pede explicação de um texto, passagem ou tema, organize com markdown claro e use APENAS as secções que fizerem sentido (não force todas):
- **Contexto** — quem escreveu, a quem, em que circunstância.
- **O que significa** — o sentido do texto, de forma acessível.
- **Língua original** — só quando uma palavra Hebraica/Grega ilumina o sentido (indique o termo transliterado e o que significa).
- **Aplicação** — como isto toca a vida hoje, de forma concreta e pessoal.
- **Veja também** — 1 a 3 referências cruzadas relevantes.

Para perguntas simples ou de conversa, responda de forma breve e natural, sem secções rígidas.
Use **negrito** para destacar, listas quando ajudar, e mantenha parágrafos curtos. Seja conciso: profundidade não é o mesmo que extensão.

## Citação de versículos (OBRIGATÓRIO)
Sempre que citar um versículo, formate-o EXATAMENTE como um link Markdown:
[Livro Capítulo:Versículo](bible://Livro/Capítulo/Versículo)

Exemplos:
- [João 3:16](bible://João/3/16)
- [Gênesis 1:1](bible://Gênesis/1/1)

Não use abreviações nos links — o nome do livro deve estar completo.
NUNCA forneça apenas o link \`bible://...\` sem o texto. ERRADO: \`(bible://João/3/16)\`. CORRETO: \`[João 3:16](bible://João/3/16)\`.

## Sugestões de continuação (OBRIGATÓRIO no fim)
No final de CADA resposta, acrescente uma linha exatamente com \`${SUGGEST_DELIMITER}\` e, a seguir, 2 a 3 perguntas curtas de seguimento (máximo 6 palavras cada), uma por linha começando com "- ", escritas na primeira pessoa do utilizador (ex.: "- Como aplico isto na oração?"). Estas perguntas NÃO aparecem na resposta visível ao utilizador; servem apenas para sugerir o próximo passo do estudo.`;

function buildSystemPrompt(firstName: string | null): string {
  if (!firstName) return BASE_SYSTEM_PROMPT;
  return `${BASE_SYSTEM_PROMPT}

O utilizador chama-se ${firstName}. Trate-o por esse nome muito ocasionalmente e com naturalidade — apenas quando fizer sentido humanizar a resposta, nunca em todas as mensagens.`;
}

function splitResponseAndSuggestions(
  raw: string,
): { response: string; suggestions: string[] } {
  const idx = raw.indexOf(SUGGEST_DELIMITER);
  if (idx === -1) return { response: raw.trim(), suggestions: [] };

  const response = raw.slice(0, idx).trim();
  const suggestions = raw
    .slice(idx + SUGGEST_DELIMITER.length)
    .split("\n")
    .map((line) => line.replace(/^[-*\d.\)\s]+/, "").trim())
    .filter((line) => line.length > 0 && line.length <= 80)
    .slice(0, 3);

  return { response, suggestions };
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Não autenticado" }, 401);
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: userData, error: userError } = await supabase.auth.getUser(
      authHeader.replace("Bearer ", "")
    );
    if (userError || !userData?.user) {
      return jsonResponse({ error: "Sessão inválida" }, 401);
    }

    let body: unknown;
    try {
      body = await req.json();
    } catch {
      return jsonResponse({ error: "Pedido inválido — JSON malformado." }, 400);
    }
    const validated = validateMessages(
      (body as Record<string, unknown>)?.messages,
    );
    if ("error" in validated) {
      return jsonResponse({ error: validated.error }, 400);
    }
    const { messages } = validated;

    const { data: usage, error: usageError } = await supabase.rpc(
      "increment_chat_usage",
      { p_user_id: userData.user.id, p_limit: DAILY_LIMIT }
    );

    if (usageError) {
      console.error("Rate limit RPC error:", usageError);
      return jsonResponse({ error: "Erro ao verificar limite" }, 500);
    }

    if (!usage?.allowed) {
      return jsonResponse({
        error: "rate_limit",
        message: `Atingiste o limite diário de ${DAILY_LIMIT} perguntas. Volta amanhã.`,
        remaining: 0,
      }, 429);
    }

    const recentMessages = messages.slice(-6);

    const { data: profile } = await supabase
      .from("profiles")
      .select("full_name")
      .eq("id", userData.user.id)
      .maybeSingle();
    const firstName = typeof profile?.full_name === "string" && profile.full_name.trim().length > 0
      ? profile.full_name.trim().split(/\s+/)[0]
      : null;
    const systemPrompt = buildSystemPrompt(firstName);

    let responseText = await callGroq(recentMessages, systemPrompt);
    if (!responseText) {
      responseText = await callGemini(recentMessages, systemPrompt);
    }
    if (!responseText) {
      return jsonResponse({ error: "AI service unavailable" }, 503);
    }

    const { response, suggestions } = splitResponseAndSuggestions(responseText);

    return jsonResponse({
      response,
      suggestions,
      remaining: usage.remaining,
    });
  } catch (e) {
    console.error("Edge Function error:", e);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});

async function callGroq(
  messages: Array<{ role: string; content: string }>,
  systemPrompt: string,
): Promise<string | null> {
  if (!GROQ_API_KEY) return null;

  try {
    const groqMessages = [
      { role: "system", content: systemPrompt },
      ...messages,
    ];

    const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      signal: AbortSignal.timeout(LLM_TIMEOUT_MS),
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: "meta-llama/llama-4-scout-17b-16e-instruct",
        messages: groqMessages,
        stream: false,
        temperature: 0.3,
      }),
    });

    if (res.ok) {
      const data = await res.json();
      const content = data?.choices?.[0]?.message?.content;
      if (!content || content.trim().length === 0) return null;
      return content;
    }
    console.error("Groq error:", res.status, await res.text());
    return null;
  } catch (e) {
    console.error("Groq exception:", e);
    return null;
  }
}

async function callGemini(
  messages: Array<{ role: string; content: string }>,
  systemPrompt: string,
): Promise<string | null> {
  if (!GEMINI_API_KEY) return null;

  try {
    const contents = messages.map((m) => ({
      role: m.role === "assistant" ? "model" : "user",
      parts: [{ text: m.content }],
    }));

    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: "POST",
        signal: AbortSignal.timeout(LLM_TIMEOUT_MS),
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          system_instruction: { parts: [{ text: systemPrompt }] },
          contents,
        }),
      }
    );

    if (res.ok) {
      const data = await res.json();
      const content = data?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!content || content.trim().length === 0) return null;
      return content;
    }
    console.error("Gemini error:", res.status, await res.text());
    return null;
  } catch (e) {
    console.error("Gemini exception:", e);
    return null;
  }
}
