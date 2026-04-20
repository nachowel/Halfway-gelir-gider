begin;

create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business_name text := coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    nullif(btrim(new.raw_user_meta_data ->> 'name'), '')
  );
begin
  begin
    insert into public.profiles (id, email, full_name)
    values (new.id, new.email, v_business_name)
    on conflict (id) do update
      set email = excluded.email,
          full_name = coalesce(public.profiles.full_name, excluded.full_name);
  exception
    when others then
      raise warning 'handle_new_user_profile profile bootstrap failed for user %: %', new.id, sqlerrm;
  end;

  begin
    insert into public.business_settings (user_id, business_name)
    values (new.id, v_business_name)
    on conflict (user_id) do update
      set business_name = coalesce(public.business_settings.business_name, excluded.business_name);
  exception
    when others then
      raise warning 'handle_new_user_profile business settings bootstrap failed for user %: %', new.id, sqlerrm;
  end;

  begin
    perform public.seed_default_categories(new.id);
  exception
    when others then
      raise warning 'handle_new_user_profile category bootstrap failed for user %: %', new.id, sqlerrm;
  end;

  return new;
end;
$$;

commit;
