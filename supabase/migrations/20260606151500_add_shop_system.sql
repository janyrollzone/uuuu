-- Alter profiles table to add shop columns
alter table public.profiles add column if not exists unlocked_items text[] default array['theme_cyberpunk', 'marker_cyan_magenta'] not null;
alter table public.profiles add column if not exists selected_theme text default 'theme_cyberpunk' not null;
alter table public.profiles add column if not exists selected_marker text default 'marker_cyan_magenta' not null;

-- Recreate trigger function to initialize new profiles with default shop settings
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (
    id, 
    username, 
    gems, 
    x_wins, 
    o_wins, 
    draws, 
    unlocked_items, 
    selected_theme, 
    selected_marker
  )
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'username',
      'Player_' || substring(new.id::text from 1 for 6)
    ),
    coalesce((new.raw_user_meta_data->>'gems')::integer, 20),
    coalesce((new.raw_user_meta_data->>'x_wins')::integer, 0),
    coalesce((new.raw_user_meta_data->>'o_wins')::integer, 0),
    coalesce((new.raw_user_meta_data->>'draws')::integer, 0),
    array['theme_cyberpunk', 'marker_cyan_magenta'],
    'theme_cyberpunk',
    'marker_cyan_magenta'
  );
  return new;
end;
$$ language plpgsql security definer;
