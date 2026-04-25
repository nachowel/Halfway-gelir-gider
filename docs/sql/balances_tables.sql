-- Balances module table documentation.
-- These tables already exist in Supabase for this project.
-- Do not run this file automatically; keep it as the local schema contract.

create table if not exists public.balance_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  direction text not null check (direction in ('payable', 'receivable')),
  name text not null check (btrim(name) <> ''),
  counterparty_name text,
  type text not null check (
    type in ('personal', 'bank', 'supplier', 'customer', 'other')
  ),
  opened_at date not null,
  status text not null default 'active' check (status in ('active', 'closed')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.balance_movements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  account_id uuid not null references public.balance_accounts (id) on delete cascade,
  type text not null check (type in ('increase', 'decrease', 'adjustment')),
  amount_minor integer not null check (amount_minor > 0),
  occurred_at date not null,
  payment_method text not null check (
    payment_method in ('cash', 'card', 'bank', 'other')
  ),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists balance_accounts_user_id_opened_at_idx
  on public.balance_accounts (user_id, opened_at desc, created_at desc);

create index if not exists balance_accounts_user_id_direction_idx
  on public.balance_accounts (user_id, direction);

create index if not exists balance_movements_user_id_account_id_idx
  on public.balance_movements (user_id, account_id);

create index if not exists balance_movements_account_id_occurred_at_idx
  on public.balance_movements (account_id, occurred_at desc, created_at desc);

alter table public.balance_accounts enable row level security;
alter table public.balance_movements enable row level security;

create policy "balance_accounts_select_own"
  on public.balance_accounts for select
  using (auth.uid() = user_id);

create policy "balance_accounts_insert_own"
  on public.balance_accounts for insert
  with check (auth.uid() = user_id);

create policy "balance_accounts_update_own"
  on public.balance_accounts for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "balance_accounts_delete_own"
  on public.balance_accounts for delete
  using (auth.uid() = user_id);

create policy "balance_movements_select_own"
  on public.balance_movements for select
  using (auth.uid() = user_id);

create policy "balance_movements_insert_own"
  on public.balance_movements for insert
  with check (auth.uid() = user_id);

create policy "balance_movements_update_own"
  on public.balance_movements for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "balance_movements_delete_own"
  on public.balance_movements for delete
  using (auth.uid() = user_id);
