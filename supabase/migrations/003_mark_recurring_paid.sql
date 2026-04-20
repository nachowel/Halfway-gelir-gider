begin;

create or replace function public.advance_recurring_due_on(
  current_due_on date,
  frequency public.recurring_frequency_type
)
returns date
language sql
immutable
as $$
  select case frequency
    when 'weekly'::public.recurring_frequency_type then current_due_on + interval '1 week'
    when 'monthly'::public.recurring_frequency_type then current_due_on + interval '1 month'
    when 'quarterly'::public.recurring_frequency_type then current_due_on + interval '3 months'
    when 'yearly'::public.recurring_frequency_type then current_due_on + interval '1 year'
  end::date
$$;

create or replace function public.mark_recurring_expense_paid(
  p_recurring_expense_id uuid,
  p_paid_on date,
  p_amount_minor integer,
  p_payment_method public.payment_method_type
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_recurring public.recurring_expenses%rowtype;
  v_transaction_id uuid := gen_random_uuid();
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if p_amount_minor <= 0 then
    raise exception 'Amount must be positive';
  end if;

  select *
    into v_recurring
  from public.recurring_expenses
  where id = p_recurring_expense_id
    and user_id = v_user_id
    and is_active = true
  for update;

  if not found then
    raise exception 'Recurring expense not found';
  end if;

  insert into public.transactions (
    id,
    user_id,
    type,
    occurred_on,
    amount_minor,
    currency,
    category_id,
    payment_method,
    note,
    recurring_expense_id
  ) values (
    v_transaction_id,
    v_user_id,
    'expense'::public.transaction_type,
    p_paid_on,
    p_amount_minor,
    'GBP',
    v_recurring.category_id,
    p_payment_method,
    v_recurring.note,
    v_recurring.id
  );

  update public.recurring_expenses
  set next_due_on = public.advance_recurring_due_on(v_recurring.next_due_on, v_recurring.frequency),
      updated_at = timezone('utc', now())
  where id = v_recurring.id;

  return v_transaction_id;
end;
$$;

commit;
