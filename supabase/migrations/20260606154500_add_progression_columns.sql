-- Add progression columns for engagement systems
alter table public.profiles
  add column if not exists win_streak integer default 0 not null,
  add column if not exists best_win_streak integer default 0 not null;

