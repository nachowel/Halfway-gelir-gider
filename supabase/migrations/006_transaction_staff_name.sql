begin;

alter table public.transactions
  add column if not exists staff_name text;

alter table public.transactions
  drop constraint if exists transactions_staff_name_trimmed_check;

alter table public.transactions
  add constraint transactions_staff_name_trimmed_check
  check (staff_name is null or btrim(staff_name) <> '');

create index if not exists idx_transactions_user_staff_name
  on public.transactions (user_id, lower(staff_name))
  where deleted_at is null and staff_name is not null;

commit;
