begin;

create table if not exists public.suppliers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  expense_category_id uuid not null references public.categories(id) on delete restrict,
  name text not null,
  notes text,
  is_archived boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint suppliers_name_trimmed_check check (btrim(name) <> ''),
  constraint suppliers_notes_trimmed_check check (notes is null or btrim(notes) <> '')
);

drop trigger if exists trg_suppliers_updated_at on public.suppliers;
create trigger trg_suppliers_updated_at
before update on public.suppliers
for each row
execute function public.set_updated_at();

drop index if exists public.uq_suppliers_user_category_name_active;
create unique index uq_suppliers_user_category_name_active
  on public.suppliers (user_id, expense_category_id, lower(name))
  where is_archived = false;

create index if not exists idx_suppliers_user_category_archived_sort
  on public.suppliers (user_id, expense_category_id, is_archived, sort_order, created_at);

create or replace function public.ensure_supplier_category_consistency()
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
  where c.id = new.expense_category_id;

  if category_owner is null then
    raise exception 'Invalid expense_category_id: %', new.expense_category_id;
  end if;

  if category_owner <> new.user_id then
    raise exception 'Category does not belong to the same user as supplier';
  end if;

  if category_type <> 'expense'::public.category_type then
    raise exception 'Supplier must reference an expense category, got (%)', category_type;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_suppliers_category_consistency on public.suppliers;
create trigger trg_suppliers_category_consistency
before insert or update of user_id, expense_category_id
on public.suppliers
for each row
execute function public.ensure_supplier_category_consistency();

alter table public.transactions
  add column if not exists supplier_id uuid;

alter table public.transactions
  drop constraint if exists transactions_supplier_id_fkey;

alter table public.transactions
  add constraint transactions_supplier_id_fkey
  foreign key (supplier_id)
  references public.suppliers(id)
  on delete set null;

create index if not exists idx_transactions_user_supplier_id
  on public.transactions (user_id, supplier_id)
  where deleted_at is null and supplier_id is not null;

create or replace function public.ensure_transaction_supplier_consistency()
returns trigger
language plpgsql
as $$
declare
  supplier_owner uuid;
  supplier_category uuid;
  transaction_category_type public.category_type;
begin
  if new.supplier_id is null then
    return new;
  end if;

  select s.user_id, s.expense_category_id
    into supplier_owner, supplier_category
  from public.suppliers s
  where s.id = new.supplier_id;

  if supplier_owner is null then
    raise exception 'Invalid supplier_id: %', new.supplier_id;
  end if;

  if supplier_owner <> new.user_id then
    raise exception 'Supplier does not belong to the same user as transaction';
  end if;

  select c.type
    into transaction_category_type
  from public.categories c
  where c.id = new.category_id;

  if transaction_category_type is null or transaction_category_type <> 'expense'::public.category_type then
    raise exception 'Supplier can only be attached to expense transactions';
  end if;

  if supplier_category <> new.category_id then
    raise exception 'Supplier category (%) does not match transaction category (%)',
      supplier_category, new.category_id;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_transactions_supplier_consistency on public.transactions;
create trigger trg_transactions_supplier_consistency
before insert or update of user_id, supplier_id, category_id
on public.transactions
for each row
execute function public.ensure_transaction_supplier_consistency();

alter table public.suppliers enable row level security;

drop policy if exists "suppliers_own_all" on public.suppliers;
create policy "suppliers_own_all"
on public.suppliers
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

commit;
