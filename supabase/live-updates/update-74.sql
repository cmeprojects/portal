-- Staff Portal · © cmeproject. All rights reserved.
-- Update 74: the owner (you) can't be turned off, demoted, reset or signed out
-- by any other system admin. Safe to run again. Undo: undo-74.sql. Run 73 first.
-- After running, the last line shows who the owner is: it should be you.
begin;
-- cmeprojects: the owner. One system admin (the business owner) whose account
-- no other system admin can change: nobody else can turn it off, change its
-- role, name, email or two-factor rules, reset its two-factor or password,
-- clear its car PIN, or sign it out. "Sign out everyone" leaves the owner
-- signed in. The owner is set only in the database (SQL editor), never from
-- the portal. This lets the owner add other system admins (for example an
-- outside reviewer) without the risk of being locked out.
-- No new SECURITY DEFINER function (three existing ones gain the owner check).

alter table public.profiles add column if not exists is_owner boolean not null default false;
create unique index if not exists profiles_one_owner on public.profiles ((true)) where is_owner;

-- The first active system admin becomes the owner (if there's none yet).
update public.profiles set is_owner = true
 where id = (select id from public.profiles where role = 'system_admin' and active order by created_at limit 1)
   and not exists (select 1 from public.profiles where is_owner);

create or replace function public.guard_owner()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is null then
    return new; -- the SQL editor and the portal's own jobs
  end if;
  if new.is_owner is distinct from old.is_owner then
    raise exception 'The owner can only be changed in the database (SQL editor).';
  end if;
  if old.is_owner and auth.uid() <> old.id
     and (new.role is distinct from old.role or new.active is distinct from old.active
          or new.mfa_exempt is distinct from old.mfa_exempt or new.email is distinct from old.email
          or new.full_name is distinct from old.full_name) then
    raise exception 'This is the owner''s account. Only the owner can change it.';
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_owner() from public, anon, authenticated;
drop trigger if exists profiles_guard_owner on public.profiles;
create trigger profiles_guard_owner before update on public.profiles
  for each row execute function public.guard_owner();

-- Reset two-factor, password links and car PINs: never for the owner (by others).
CREATE OR REPLACE FUNCTION public.can_help_sign_in(p_user uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.mfa_ok()
     and p_user is distinct from auth.uid()
     and exists (select 1 from public.profiles where id = p_user and not is_owner)
     and (public.my_role() = 'system_admin'
          or (public.my_role() = any (public.setting_roles('people.access_reset_roles'))
              and (select role from public.profiles where id = p_user) <> 'system_admin'))
$function$;

-- Signing one person out: never the owner.
CREATE OR REPLACE FUNCTION public.sign_out_everywhere(p_user_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_count integer;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this.';
  end if;
  if p_user_id = auth.uid() then
    raise exception 'To sign yourself out of other devices, use My account.';
  end if;
  if exists (select 1 from public.profiles where id = p_user_id and is_owner) then
    raise exception 'This is the owner''s account. Only the owner can change it.';
  end if;
  delete from auth.sessions where user_id = p_user_id;
  get diagnostics v_count = row_count;
  perform public.write_audit('signed_out_everywhere', 'profile', p_user_id::text, jsonb_build_object('devices', v_count));
  return v_count;
end;
$function$;

-- Signing everyone out: the owner stays signed in.
CREATE OR REPLACE FUNCTION public.sign_out_everyone()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_count integer;
begin
  if not public.is_system_admin() then
    raise exception 'Only the system admin can do this.';
  end if;
  delete from auth.sessions
   where id is distinct from nullif(auth.jwt() ->> 'session_id', '')::uuid
     -- cmeprojects: the owner stays signed in (unless the owner does this).
     and (user_id not in (select id from public.profiles where is_owner)
          or exists (select 1 from public.profiles where id = auth.uid() and is_owner));
  get diagnostics v_count = row_count;
  perform public.write_audit('signed_out_everyone', 'system', 'everyone', jsonb_build_object('devices', v_count));
  return v_count;
end;
$function$;
commit;
select full_name || ' (' || email || ') is the owner' as owner from public.profiles where is_owner;
