-- Persistência de conversas do chat bíblico (schema normalizado, escalável).
-- Uma linha por conversa (metadados) + uma linha por mensagem.

-- 1. Conversas (apenas metadados)
create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Mensagens (uma linha por mensagem)
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  tokens_used integer, -- opcional: útil para calcular custos
  created_at timestamptz not null default now()
);

-- Índices de performance
create index if not exists chat_conversations_user_updated_idx
  on public.chat_conversations (user_id, updated_at desc);
create index if not exists chat_messages_conversation_idx
  on public.chat_messages (conversation_id, created_at asc);

-- RLS: conversas
alter table public.chat_conversations enable row level security;
drop policy if exists "users manage own conversations" on public.chat_conversations;
create policy "users manage own conversations" on public.chat_conversations
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- RLS: mensagens (herdam a segurança da conversa via subquery)
alter table public.chat_messages enable row level security;
drop policy if exists "users manage messages of their conversations" on public.chat_messages;
create policy "users manage messages of their conversations" on public.chat_messages
  for all using (
    exists (
      select 1 from public.chat_conversations
      where chat_conversations.id = chat_messages.conversation_id
        and chat_conversations.user_id = auth.uid()
    )
  ) with check (
    exists (
      select 1 from public.chat_conversations
      where chat_conversations.id = chat_messages.conversation_id
        and chat_conversations.user_id = auth.uid()
    )
  );
