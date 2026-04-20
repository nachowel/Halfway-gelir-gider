begin;

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name')
  )
  on conflict (id) do nothing;

  insert into public.business_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  perform public.seed_default_categories(new.id);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_user_profile();

alter table public.profiles enable row level security;
alter table public.business_settings enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;
alter table public.recurring_expenses enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles
for select
using (auth.uid() = id);

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles
for insert
with check (auth.uid() = id);

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "business_settings_own_all" on public.business_settings;
create policy "business_settings_own_all"
on public.business_settings
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "categories_own_all" on public.categories;
create policy "categories_own_all"
on public.categories
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "transactions_own_all" on public.transactions;
create policy "transactions_own_all"
on public.transactions
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "recurring_expenses_own_all" on public.recurring_expenses;
create policy "recurring_expenses_own_all"
on public.recurring_expenses
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

commit;
