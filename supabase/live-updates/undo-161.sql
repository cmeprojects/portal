-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 161 (billing set-up). Safe to run again.
-- Nothing is lost: every record update 161 added is first copied to a locked schema,
-- undo_161_kept, that only the database owner can read (price lists, versions, bands,
-- prices, public holidays, scheme rules and checks, contribution rates, billing terms,
-- cancellation details). Change-log entries stay. Undo does NOT restore anything later;
-- bringing records back is a separate, manual decision.
-- Then the new tables, rules and the "Billing" access part are removed (the part is
-- kept as retired if anyone was given it on the Access page). Nothing that existed
-- before update 161 is changed: services, shifts, funding, agreements and enrolments
-- stay exactly as they are.
begin;
create schema if not exists undo_161_kept;
revoke all on schema undo_161_kept from public;
do $$
declare
  t text;
begin
  foreach t in array array['billing_scheme_rules', 'billing_rule_checks', 'price_lists', 'price_list_versions', 'price_list_bands', 'price_items',
                           'public_holidays', 'client_contribution_rates', 'client_service_terms', 'shift_cancellations'] loop
    if to_regclass('public.' || t) is not null then
      if to_regclass('undo_161_kept.' || t) is null then
        execute format('create table undo_161_kept.%I as table public.%I', t, t);
      elsif t = 'shift_cancellations' then
        execute format('insert into undo_161_kept.%I select * from public.%I p where not exists (select 1 from undo_161_kept.%I k where k.shift_id = p.shift_id and k.updated_at = p.updated_at)', t, t, t);
      else
        execute format('insert into undo_161_kept.%I select * from public.%I p where not exists (select 1 from undo_161_kept.%I k where k.id = p.id and k.updated_at = p.updated_at)', t, t, t);
      end if;
    end if;
  end loop;
end $$;
revoke all on all tables in schema undo_161_kept from public;
do $$ begin
  execute 'revoke all on schema undo_161_kept from anon, authenticated';
  execute 'revoke all on all tables in schema undo_161_kept from anon, authenticated';
exception when undefined_object then null;
end $$;

drop table if exists public.shift_cancellations;
drop table if exists public.client_service_terms;
drop table if exists public.client_contribution_rates;
drop table if exists public.public_holidays;
drop table if exists public.price_items;
drop table if exists public.price_list_bands;
drop table if exists public.price_list_versions;
drop table if exists public.price_lists;
drop table if exists public.billing_rule_checks;
drop table if exists public.billing_scheme_rules;
drop function if exists public.price_list_new_version(uuid);
drop function if exists public.guard_billing_rules();
drop function if exists public.guard_billing_check_scheme();
drop function if exists public.guard_price_list();
drop function if exists public.guard_price_version();
drop function if exists public.guard_price_part();
drop function if exists public.guard_public_holiday();
drop function if exists public.guard_contribution_rate();
drop function if exists public.guard_service_terms();
drop function if exists public.guard_shift_cancellation();
drop function if exists public.stamp_billing_updated();
drop function if exists public.billing_can(text, uuid);

update public.access_baselines set revoked_at = now() where module_id = 'clients.billing' and revoked_at is null;
update public.app_modules set status = 'retired' where id in ('clients.billing', 'system.settings.billing')
   and (exists (select 1 from public.access_baselines b where b.module_id = app_modules.id) or exists (select 1 from public.access_grants g where g.module_id = app_modules.id));
delete from public.app_modules where id in ('clients.billing', 'system.settings.billing')
   and not exists (select 1 from public.access_baselines b where b.module_id = app_modules.id) and not exists (select 1 from public.access_grants g where g.module_id = app_modules.id);
commit;
