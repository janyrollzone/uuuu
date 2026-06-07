-- Create profiles table
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  username text unique not null,
  x_wins integer default 0 not null,
  o_wins integer default 0 not null,
  draws integer default 0 not null,
  gems integer default 20 not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable Row Level Security (RLS)
alter table public.profiles enable row level security;

-- Policies
create policy "Allow public read access" on public.profiles
  for select using (true);

create policy "Allow individual insert" on public.profiles
  for insert with check (auth.uid() = id);

create policy "Allow individual update" on public.profiles
  for update using (auth.uid() = id);

-- Function to handle new user signup and sync initial local stats
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, gems, x_wins, o_wins, draws)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'username',
      'Player_' || substring(new.id::text from 1 for 6)
    ),
    coalesce((new.raw_user_meta_data->>'gems')::integer, 20),
    coalesce((new.raw_user_meta_data->>'x_wins')::integer, 0),
    coalesce((new.raw_user_meta_data->>'o_wins')::integer, 0),
    coalesce((new.raw_user_meta_data->>'draws')::integer, 0)
  );
  return new;
end;
$$ language plpgsql security definer;

-- Trigger execution
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
