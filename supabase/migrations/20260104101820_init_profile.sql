create table if not exists public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  email text not null unique
);

alter table public.profiles enable row level security;

create policy "Profiles are viewable by owner"
  on public.profiles
  for select
  using (auth.uid() = user_id);

create policy "Profiles can be inserted by owner"
  on public.profiles
  for insert
  with check (auth.uid() = user_id);

create policy "Profiles can be updated by owner"
  on public.profiles
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (user_id, email)
  values (new.id, new.email);
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();
