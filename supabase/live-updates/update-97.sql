-- Staff Portal · © cmeproject. All rights reserved.
-- Update 97: Forms switched over to the one permission check (Stage 3b).
-- Today's settings are copied once into access-level defaults on the Access
-- page, so nobody's access changes. Safe to run again. Undo: undo-97.sql.
-- Run update 96 first.
begin;
-- cmeprojects (update 97; function-based access, Stage 3b; D-047, D-049):
-- Forms (making and managing forms) switched over to the one permission
-- check `can()`.
--
--   * Who makes forms now comes only from `can('workflows.forms', 'create')`
--     (with Forms and the form builder switched on, as before). The system
--     admin always can, as before.
--   * Today's System setting "Who can make forms" is copied once into
--     access-level defaults (full Forms access for each role ticked), so
--     nobody's access changes. After this it's changed on the Access page; the
--     old setting is kept but no longer used.
--   * Filling in forms (My forms) is unchanged.

update public.app_modules set grant_ready = true where id = 'workflows.forms' and not grant_ready;

do $$
begin
  if exists (select 1 from public.access_baselines
              where module_id = 'workflows.forms' and access_level is not null and revoked_at is null) then
    return;
  end if;
  insert into public.access_baselines (access_level, module_id, actions, scope, note)
  select distinct r, 'workflows.forms', '{}'::text[], 'all', 'Set at switch-over from "Who can make forms"'
    from unnest(public.setting_roles('forms.maker_roles')) r
   where r not in ('system_admin', 'new_starter', 'external');
end $$;

create or replace function public.can_make_forms()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_member() and public.feature_enabled('forms')
     and (public.is_system_admin()
          or (public.feature_enabled('form_builder') and public.can('workflows.forms', 'create')))
$$;
commit;
