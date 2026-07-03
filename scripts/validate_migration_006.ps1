param(
  [string]$DatabaseUrl = $env:MIGRATION_006_DATABASE_URL
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($DatabaseUrl)) {
  throw 'Set MIGRATION_006_DATABASE_URL to an already-running local Postgres/Supabase database.'
}

$psql = Get-Command psql -ErrorAction SilentlyContinue
if ($null -eq $psql) {
  $defaultPsql = 'C:\Program Files\PostgreSQL\17\bin\psql.exe'
  if (-not (Test-Path $defaultPsql)) {
    throw 'psql was not found on PATH or at C:\Program Files\PostgreSQL\17\bin\psql.exe.'
  }
  $psqlPath = $defaultPsql
} else {
  $psqlPath = $psql.Source
}

function Invoke-Psql {
  param([string[]]$Arguments)

  & $psqlPath $DatabaseUrl -w -v ON_ERROR_STOP=1 @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "psql failed with exit code $LASTEXITCODE"
  }
}

$probeSql = @'
do $$
begin
  if to_regclass('public.transactions') is null then
    raise exception 'public.transactions does not exist';
  end if;
end $$;
'@

Invoke-Psql @('-c', $probeSql) | Out-Null
Invoke-Psql @('-f', (Resolve-Path 'supabase/migrations/006_transaction_staff_name.sql').Path) | Out-Null

$validationSql = @'
do $$
declare
  test_user uuid := '90000000-0000-4000-8000-000000000006';
  test_category uuid := '90000000-0000-4000-8000-000000000106';
  legacy_tx uuid := '90000000-0000-4000-8000-000000000206';
  inserted_tx uuid := '90000000-0000-4000-8000-000000000306';
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'transactions'
      and column_name = 'staff_name'
  ) then
    raise exception 'staff_name column missing';
  end if;

  delete from public.transactions where id in (legacy_tx, inserted_tx);
  delete from public.categories where id = test_category;
  delete from auth.users where id = test_user;

  insert into auth.users (id, email)
  values (test_user, 'migration-006@example.com');

  insert into public.categories (id, user_id, type, name)
  values (test_category, test_user, 'expense', 'Migration 006 Test');

  insert into public.transactions (
    id,
    user_id,
    type,
    occurred_on,
    amount_minor,
    category_id,
    payment_method,
    vendor
  )
  values (
    legacy_tx,
    test_user,
    'expense',
    '2026-04-20',
    1000,
    test_category,
    'card',
    'Legacy Vendor'
  );

  update public.transactions
  set staff_name = 'Sam'
  where id = legacy_tx;

  insert into public.transactions (
    id,
    user_id,
    type,
    occurred_on,
    amount_minor,
    category_id,
    payment_method,
    staff_name,
    vendor
  )
  values (
    inserted_tx,
    test_user,
    'expense',
    '2026-04-21',
    2000,
    test_category,
    'cash',
    'Alex',
    'Payroll'
  );

  if (select staff_name from public.transactions where id = legacy_tx) <> 'Sam' then
    raise exception 'staff_name update/select failed';
  end if;

  if (select staff_name from public.transactions where id = inserted_tx) <> 'Alex' then
    raise exception 'staff_name insert/select failed';
  end if;
end $$;
'@

Invoke-Psql @('-c', $validationSql) | Out-Null

$blankRejected = $false
try {
  Invoke-Psql @(
    '-c',
    "insert into public.transactions (user_id, type, occurred_on, amount_minor, category_id, payment_method, staff_name) values ('90000000-0000-4000-8000-000000000006', 'expense', '2026-04-22', 100, '90000000-0000-4000-8000-000000000106', 'card', '   ');"
  ) | Out-Null
} catch {
  $blankRejected = $true
}

if (-not $blankRejected) {
  throw 'blank staff_name insert unexpectedly succeeded'
}

Invoke-Psql @(
  '-t',
  '-A',
  '-c',
  "select '006_applied=true'; select 'staff_name_column_exists=true'; select 'insert_update_select_works=true'; select 'blank_staff_name_rejected=true';"
)
