import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY") ?? "";
const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const DAILY_LIMIT = 50;

const BASE_SYSTEM_PROMPT = `Você é um especialista em Bíblia, teologia cristã e princípios do cristianismo.
Todas as suas respostas devem ser baseadas nas Escrituras Sagradas, na fé cristã e em valores bíblicos.
Responda sempre em Português de Portugal.

IMPORTANTE:
Sempre que citar um versículo, formate-o EXATAMENTE como um link Markdown da seguinte forma:
[Livro Capítulo:Versículo](bible://Livro/Capítulo/Versículo)

Exemplos:
- [João 3:16](bible://João/3/16)
- [Gênesis 1:1](bible://Gênesis/1/1)

Não use abreviações nos links. O nome do livro deve estar completo.
NUNCA forneça apenas o link \`bible://...\` sem o texto do link. Exemplo ERRADO: \`(bible://João/3/16)\`. Exemplo CORRETO: \`[João 3:16](bible://João/3/16)\`.`;

function buildSystemPrompt(firstName: string | null): string {
  if (!firstName) return BASE_SYSTEM_PROMPT;
  return `${BASE_SYSTEM_PROMPT}

O utilizador chama-se ${firstName}. Trate-o por esse nome muito ocasionalmente e com naturalidade — apenas quando fizer sentido humanizar a resposta, nunca em todas as mensagens.`;
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

    const { messages } = await req.json();
    if (!messages || !Array.isArray(messages) || messages.length === 0) {
      return jsonResponse({ error: "messages array is required" }, 400);
    }

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

    return jsonResponse({ response: responseText, remaining: usage.remaining });
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
