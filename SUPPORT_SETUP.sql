-- KL NAASIR EXCHANGE: Telegram Support Chat
-- Run once in Supabase SQL Editor.

create table if not exists public.support_conversations (
  id uuid primary key default gen_random_uuid(),
  telegram_user_id bigint not null,
  telegram_chat_id bigint not null,
  customer_name text,
  language text not null default 'so',
  status text not null default 'open' check (status in ('open','closed')),
  last_message text,
  last_message_at timestamptz not null default now(),
  unread_admin boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (telegram_user_id)
);

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.support_conversations(id) on delete cascade,
  sender text not null check (sender in ('customer','admin')),
  message_text text,
  telegram_file_id text,
  telegram_file_type text,
  created_at timestamptz not null default now()
);

create index if not exists support_conversations_last_message_idx
  on public.support_conversations(last_message_at desc);
create index if not exists support_messages_conversation_created_idx
  on public.support_messages(conversation_id, created_at);

alter table public.support_conversations enable row level security;
alter table public.support_messages enable row level security;

drop policy if exists "Super admins read support conversations" on public.support_conversations;
create policy "Super admins read support conversations"
on public.support_conversations for select to authenticated
using (exists (
  select 1 from public.admin_users a
  where a.user_id = auth.uid() and a.role = 'super_admin'
));

drop policy if exists "Super admins update support conversations" on public.support_conversations;
create policy "Super admins update support conversations"
on public.support_conversations for update to authenticated
using (exists (
  select 1 from public.admin_users a
  where a.user_id = auth.uid() and a.role = 'super_admin'
))
with check (exists (
  select 1 from public.admin_users a
  where a.user_id = auth.uid() and a.role = 'super_admin'
));

drop policy if exists "Super admins read support messages" on public.support_messages;
create policy "Super admins read support messages"
on public.support_messages for select to authenticated
using (exists (
  select 1 from public.admin_users a
  where a.user_id = auth.uid() and a.role = 'super_admin'
));

-- Customers do not access these tables directly. The Telegram Edge Function uses
-- the server-side service role key to create/read messages and send bot replies.
