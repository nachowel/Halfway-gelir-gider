begin;

insert into public.profiles (id, email, full_name)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data ->> 'full_name', u.raw_user_meta_data ->> 'name')
from auth.users u
on conflict (id) do nothing;

insert into public.business_settings (user_id)
select u.id
from auth.users u
on conflict (user_id) do nothing;

do $$
declare
  v_user record;
begin
  for v_user in
    select id
    from auth.users
  loop
    perform public.seed_default_categories(v_user.id);
  end loop;
end;
$$;

commit;
