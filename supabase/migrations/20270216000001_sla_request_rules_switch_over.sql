-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 102; function-based access, Stage 3b; D-047, D-049):
-- Due dates (SLA settings) and Request approvals follow the one permission
-- check `can()`.
--
--   * Request approvals: already decided by the HR settings area everywhere
--     (page and database). It's now catalogued as part of that settings area,
--     so `can('workflows.request_rules', ...)` gives the same answer and it's
--     given with the HR settings area on the Access page. No access changes.
--   * Due dates (SLA): "managers always" becomes a grant,
--     `can('workflows.sla', 'configure')`, with a default for managers (today's
--     rule). Whoever looks after the Tasks settings area still can, as before.
--     Nobody's access changes.

update public.app_modules set legacy_kind = 'settings', legacy_area = 'hr'
 where id = 'workflows.request_rules' and legacy_kind is null;

update public.app_modules set grant_ready = true where id = 'workflows.sla' and not grant_ready;

do $$
begin
  if exists (select 1 from public.access_baselines
              where module_id = 'workflows.sla' and access_level is not null and revoked_at is null) then
    return;
  end if;
  insert into public.access_baselines (access_level, module_id, actions, scope, note)
  values ('manager', 'workflows.sla', '{}', 'all', 'Set at switch-over: managers set the due dates');
end $$;

drop policy if exists "managers change the SLA" on public.app_settings;
create policy "managers change the SLA" on public.app_settings
  for update to authenticated
  using (key like 'tasks.sla%' and (select public.can('workflows.sla', 'configure')))
  with check (key like 'tasks.sla%' and (select public.can('workflows.sla', 'configure')));
