begin;

create extension if not exists pgcrypto;

do $$
begin
  if not exists (select 1 from pg_type where typname = 'transaction_type') then
    create type public.transaction_type as enum ('income', 'expense');
  end if;

  if not exists (select 1 from pg_type where typname = 'payment_method_type') then
    create type public.payment_method_type as enum ('cash', 'card', 'bank_transfer', 'other');
  end if;

  if not exists (select 1 from pg_type where typname = 'source_platform_type') then
    create type public.source_platform_type as enum ('direct', 'uber', 'just_eat', 'other');
  end if;

  if not exists (select 1 from pg_type where typname = 'category_type') then
    create type public.category_type as enum ('income', 'expense');
  end if;

  if not exists (select 1 from pg_type where typname = 'recurring_frequency_type') then
    create type public.recurring_frequency_type as enum ('weekly', 'monthly', 'quarterly', 'yearly');
  end if;
end
$$;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create table if not exists public.business_settings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  business_name text,
  timezone text not null default 'Europe/London',
  currency text not null default 'GBP',
  week_starts_on smallint not null default 1,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint business_settings_timezone_check check (timezone = 'Europe/London'),
  constraint business_settings_currency_check check (currency = 'GBP'),
  constraint business_settings_week_starts_on_check check (week_starts_on = 1)
);

drop trigger if exists trg_business_settings_updated_at on public.business_settings;
create trigger trg_business_settings_updated_at
before update on public.business_settings
for each row
execute function public.set_updated_at();

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type public.category_type not null,
  name text not null,
  icon text,
  color_token text,
  is_archived boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint categories_name_trimmed_check check (btrim(name) <> '')
);

drop trigger if exists trg_categories_updated_at on public.categories;
create trigger trg_categories_updated_at
before update on public.categories
for each row
execute function public.set_updated_at();

drop index if exists public.uq_categories_user_type_name_active;
create unique index uq_categories_user_type_name_active
  on public.categories (user_id, type, lower(name))
  where is_archived = false;

create index if not exists idx_categories_user_type_archived_sort
  on public.categories (user_id, type, is_archived, sort_order, created_at);

create or replace function public.seed_default_categories(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.categories (
    user_id,
    type,
    name,
    icon,
    color_token,
    sort_order
  )
  select
    p_user_id,
    seed.type,
    seed.name,
    seed.icon,
    seed.color_token,
    seed.sort_order
  from (
    values
      ('income'::public.category_type, 'Cash Sales', 'storefront_rounded', 'income', 0),
      ('income'::public.category_type, 'Card Sales', 'payments_rounded', 'income', 1),
      ('income'::public.category_type, 'Uber Settlement', 'directions_car_filled_rounded', 'income', 2),
      ('income'::public.category_type, 'Just Eat Settlement', 'delivery_dining_rounded', 'income', 3),
      ('income'::public.category_type, 'Other Income', 'work_outline_rounded', 'income', 4),
      ('expense'::public.category_type, 'Rent', 'home_rounded', 'expense', 0),
      ('expense'::public.category_type, 'Utilities', 'bolt_rounded', 'expense', 1),
      ('expense'::public.category_type, 'Internet', 'wifi_rounded', 'expense', 2),
      ('expense'::public.category_type, 'Stock Purchase', 'inventory_2_outlined', 'expense', 3),
      ('expense'::public.category_type, 'Supplies', 'shopping_bag_outlined', 'expense', 4),
      ('expense'::public.category_type, 'Maintenance', 'build_circle_outlined', 'expense', 5),
      ('expense'::public.category_type, 'Delivery/Transport', 'local_shipping_outlined', 'expense', 6),
      ('expense'::public.category_type, 'Other Expense', 'receipt_long_rounded', 'expense', 7)
  ) as seed(type, name, icon, color_token, sort_order)
  where not exists (
    select 1
    from public.categories c
    where c.user_id = p_user_id
      and c.type = seed.type
      and lower(c.name) = lower(seed.name)
      and c.is_archived = false
  );
end;
$$;

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type public.transaction_type not null,
  occurred_on date not null,
  amount_minor integer not null,
  currency text not null default 'GBP',
  category_id uuid not null references public.categories(id) on delete restrict,
  payment_method public.payment_method_type not null,
  source_platform public.source_platform_type,
  note text,
  vendor text,
  attachment_path text,
  recurring_expense_id uuid,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz,
  constraint transactions_amount_positive_check check (amount_minor > 0),
  constraint transactions_currency_check check (currency = 'GBP'),
  constraint transactions_vendor_trimmed_check check (vendor is null or btrim(vendor) <> ''),
  constraint transactions_note_trimmed_check check (note is null or btrim(note) <> '')
);

drop trigger if exists trg_transactions_updated_at on public.transactions;
create trigger trg_transactions_updated_at
before update on public.transactions
for each row
execute function public.set_updated_at();

create table if not exists public.recurring_expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  category_id uuid not null references public.categories(id) on delete restrict,
  amount_minor integer not null,
  currency text not null default 'GBP',
  frequency public.recurring_frequency_type not null,
  next_due_on date not null,
  reminder_days_before integer not null default 3,
  default_payment_method public.payment_method_type,
  reserve_enabled boolean not null default false,
  is_active boolean not null default true,
  note text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint recurring_expenses_amount_positive_check check (amount_minor > 0),
  constraint recurring_expenses_currency_check check (currency = 'GBP'),
  constraint recurring_expenses_name_trimmed_check check (btrim(name) <> ''),
  constraint recurring_expenses_reminder_days_before_check check (reminder_days_before >= 0),
  constraint recurring_expenses_note_trimmed_check check (note is null or btrim(note) <> '')
);

drop trigger if exists trg_recurring_expenses_updated_at on public.recurring_expenses;
create trigger trg_recurring_expenses_updated_at
before update on public.recurring_expenses
for each row
execute function public.set_updated_at();

alter table public.transactions
  drop constraint if exists transactions_recurring_expense_id_fkey;

alter table public.transactions
  add constraint transactions_recurring_expense_id_fkey
  foreign key (recurring_expense_id)
  references public.recurring_expenses(id)
  on delete set null;

create or replace function public.ensure_transaction_ownership_consistency()
returns trigger
language plpgsql
as $$
declare
  category_owner uuid;
  category_type public.category_type;
begin
  select c.user_id, c.type
    into category_owner, category_type
  from public.categories c
  where c.id = new.category_id;

  if category_owner is null then
    raise exception 'Invalid category_id: %', new.category_id;
  end if;

  if category_owner <> new.user_id then
    raise exception 'Category does not belong to the same user as transaction';
  end if;

  if category_type::text <> new.type::text then
    raise exception 'Transaction type (%) does not match category type (%)', new.type, category_type;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_transactions_ownership_consistency on public.transactions;
create trigger trg_transactions_ownership_consistency
before insert or update of user_id, category_id, type
on public.transactions
for each row
execute function public.ensure_transaction_ownership_consistency();

create or replace function public.ensure_recurring_ownership_consistency()
returns trigger
language plpgsql
as $$
declare
  category_owner uuid;
  category_type public.category_type;
begin
  select c.user_id, c.type
    into category_owner, category_type
  from public.categories c
  where c.id = new.category_id;

  if category_owner is null then
    raise exception 'Invalid category_id: %', new.category_id;
  end if;

  if category_owner <> new.user_id then
    raise exception 'Category does not belong to the same user as recurring expense';
  end if;

  if category_type <> 'expense'::public.category_type then
    raise exception 'Recurring expense must reference an expense category, got (%)', category_type;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_recurring_ownership_consistency on public.recurring_expenses;
create trigger trg_recurring_ownership_consistency
before insert or update of user_id, category_id
on public.recurring_expenses
for each row
execute function public.ensure_recurring_ownership_consistency();

create index if not exists idx_transactions_active_user_occurred_on
  on public.transactions (user_id, occurred_on desc, created_at desc)
  where deleted_at is null;

create index if not exists idx_transactions_active_user_type_occurred_on
  on public.transactions (user_id, type, occurred_on desc, created_at desc)
  where deleted_at is null;

create index if not exists idx_transactions_active_user_category_occurred_on
  on public.transactions (user_id, category_id, occurred_on desc)
  where deleted_at is null;

create index if not exists idx_transactions_active_user_payment_method_occurred_on
  on public.transactions (user_id, payment_method, occurred_on desc)
  where deleted_at is null;

create index if not exists idx_transactions_active_user_source_platform_occurred_on
  on public.transactions (user_id, source_platform, occurred_on desc)
  where deleted_at is null;

create index if not exists idx_transactions_user_recurring_expense_id
  on public.transactions (user_id, recurring_expense_id)
  where deleted_at is null;

create index if not exists idx_recurring_expenses_user_active_due
  on public.recurring_expenses (user_id, is_active, next_due_on);

create index if not exists idx_recurring_expenses_user_category
  on public.recurring_expenses (user_id, category_id);

create index if not exists idx_recurring_expenses_user_reserve_enabled
  on public.recurring_expenses (user_id, reserve_enabled, is_active, next_due_on);

commit;
