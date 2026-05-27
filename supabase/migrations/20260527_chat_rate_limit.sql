-- Rate limiting do chat: 50 perguntas por utilizador por dia.

create table if not exists public.chat_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null default current_date,
  count int not null default 0,
  primary key (user_id, day)
);

alter table public.chat_usage enable row level security;

drop policy if exists "users read own usage" on public.chat_usage;
create policy "users read own usage"
  on public.chat_usage for select
  using (auth.uid() = user_id);

create or replace function public.increment_chat_usage(
  p_user_id uuid,
  p_limit int
) returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  insert into public.chat_usage (user_id, day, count)
  values (p_user_id, current_date, 1)
  on conflict (user_id, day)
  do update set count = chat_usage.count + 1
  where chat_usage.count < p_limit
  returning count into v_count;

  if v_count is null then
    return json_build_object('allowed', false, 'count', p_limit, 'remaining', 0);
  end if;

  return json_build_object('allowed', true, 'count', v_count, 'remaining', p_limit - v_count);
end;
$$;

revoke all on function public.increment_chat_usage(uuid, int) from public;
grant execute on function public.increment_chat_usage(uuid, int) to service_role;
