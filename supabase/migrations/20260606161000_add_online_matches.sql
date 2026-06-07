create extension if not exists pgcrypto;

create table if not exists public.online_matches (
  id uuid primary key default gen_random_uuid(),
  status text not null default 'waiting' check (status in ('waiting', 'active', 'finished')),
  board_size integer not null default 10,
  player_x_id uuid not null references auth.users on delete cascade,
  player_x_name text not null,
  player_o_id uuid references auth.users on delete cascade,
  player_o_name text,
  current_player text not null default 'X' check (current_player in ('X', 'O')),
  board jsonb not null default '[]',
  winner text,
  winning_line jsonb not null default '[]',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.online_matches enable row level security;

create policy "Authenticated users can read matches"
on public.online_matches
for select
using (auth.uid() is not null);

create policy "Player X can create matches"
on public.online_matches
for insert
with check (auth.uid() = player_x_id);

create policy "Participants can update matches"
on public.online_matches
for update
using (auth.uid() = player_x_id or auth.uid() = player_o_id);

create policy "Participants can delete matches"
on public.online_matches
for delete
using (auth.uid() = player_x_id or auth.uid() = player_o_id);

create index if not exists online_matches_queue_idx
on public.online_matches (status, board_size, created_at);

create or replace function public.find_or_create_online_match(p_board_size integer)
returns public.online_matches
language plpgsql
security definer
set search_path = public
as $$
declare
  v_username text;
  v_match public.online_matches;
begin
  select coalesce(
    (select username from public.profiles where id = auth.uid()),
    'Player_' || substring(auth.uid()::text from 1 for 6)
  )
  into v_username;

  select *
  into v_match
  from public.online_matches
  where status = 'waiting'
    and board_size = p_board_size
    and player_x_id <> auth.uid()
  order by created_at asc
  limit 1
  for update skip locked;

  if found then
    update public.online_matches
    set
      player_o_id = auth.uid(),
      player_o_name = v_username,
      status = 'active',
      updated_at = timezone('utc'::text, now())
    where id = v_match.id
    returning * into v_match;
    return v_match;
  end if;

  insert into public.online_matches (
    status,
    board_size,
    player_x_id,
    player_x_name,
    player_o_id,
    player_o_name,
    current_player,
    board,
    winner,
    winning_line
  )
  values (
    'waiting',
    p_board_size,
    auth.uid(),
    v_username,
    null,
    null,
    'X',
    to_jsonb(array_fill(null::text, array[p_board_size * p_board_size])),
    null,
    '[]'::jsonb
  )
  returning * into v_match;

  return v_match;
end;
$$;
