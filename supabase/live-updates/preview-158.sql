-- Staff Portal · © cmeproject. All rights reserved.
-- PREVIEW for update 158 (program enrolments). READ ONLY.
--
-- One SELECT statement: it changes no records, schema, permissions or database
-- objects. Run it on Dev BEFORE update 158 and check the rows marked REVIEW.
-- It shows what update 158 would create for existing clients:
--   section 1  SUMMARY: counts.
--   section 2  ENROLMENT: one row per proposed enrolment, with its source,
--              status, dates (Sydney dates), main-program choice and any flag.
--   section 3  REVIEW: clients and shifts that need a person to look at them.
-- Rules (as approved): one enrolment per client and named program; built from
-- the client's services (any status) and their "Funded by"; a discharged
-- client's enrolments are ended at the discharge date; an end date is never
-- before the start; main = the open enrolment under "Funded by" (earliest),
-- otherwise the earliest-started open enrolment; no open enrolment = "No
-- active program". Nothing about shifts is changed: shifts are only listed.
with
sydney as (select (now() at time zone 'Australia/Sydney')::date as today),
svc as (  -- each client's services, grouped by named program
  select s.client_id, s.program_id, p.name as program, p.scheme, p.active as program_on,
         min(s.start_date) as first_start,
         count(*) as services,
         count(*) filter (where s.status <> 'ended' and (s.end_date is null or s.end_date >= (select today from sydney))) as open_services,
         max(coalesce(s.end_date, (s.updated_at at time zone 'Australia/Sydney')::date)) as last_end
    from public.client_services s
    join public.client_programs p on p.id = s.program_id
   group by 1, 2, 3, 4, 5
),
fb as (   -- "Funded by" with no service under that scheme: which named program would it be?
  select c.id as client_id, c.scheme,
         count(p.id) filter (where p.active) as active_programs,
         (array_agg(p.id order by p.sort_order) filter (where p.active))[1] as program_id
    from public.car_clients c
    left join public.client_programs p on p.scheme = c.scheme
   where c.scheme is not null
     and not exists (select 1 from svc where svc.client_id = c.id and svc.scheme = c.scheme)
   group by 1, 2
),
proposed as (
  select c.id as client_id, svc.program_id, svc.program, svc.scheme,
         'services (' || svc.services || ', ' || svc.open_services || ' open)' as source,
         svc.first_start as starts_on,
         case when c.status = 'discharged' or svc.open_services = 0 then 'ended' else 'active' end as status,
         case when c.status = 'discharged'
                then greatest(svc.first_start, coalesce((c.archived_at at time zone 'Australia/Sydney')::date, svc.last_end))
              when svc.open_services = 0 then greatest(svc.first_start, svc.last_end) end as ends_on,
         concat_ws('; ',
           case when not svc.program_on then 'program switched off (kept for history)' end,
           case when c.status = 'discharged' and svc.open_services > 0
                then 'CONFLICT: discharged client still has ' || svc.open_services || ' open service(s); enrolment ended, services left as they are' end) as flag
    from svc join public.car_clients c on c.id = svc.client_id
  union all
  select c.id, fb.program_id, p.name, fb.scheme,
         'Funded by (no services yet)',
         (c.created_at at time zone 'Australia/Sydney')::date,
         case when c.status = 'discharged' then 'ended' else 'active' end,
         case when c.status = 'discharged' then greatest((c.created_at at time zone 'Australia/Sydney')::date, (c.archived_at at time zone 'Australia/Sydney')::date) end,
         concat_ws('; ',
           case when fb.active_programs > 1
                then 'AMBIGUOUS: "Funded by" scheme has ' || fb.active_programs || ' active programs; the first (' || p.name || ') would be used' end,
           case when exists (select 1 from svc where svc.client_id = c.id)
                then 'CONFLICT: "Funded by" differs from the programs of their services; this enrolment comes from "Funded by" only' end)
    from fb join public.car_clients c on c.id = fb.client_id
    join public.client_programs p on p.id = fb.program_id
),
ranked as (
  select pr.*,
         row_number() over (partition by pr.client_id
                            order by (pr.status = 'active') desc,
                                     (pr.scheme is not distinct from c.scheme) desc,
                                     pr.starts_on, pr.program) as pick
    from proposed pr join public.car_clients c on c.id = pr.client_id
),
main as (
  select r.client_id, r.program_id,
         case when r.status <> 'active' then null
              when r.scheme is not distinct from c.scheme then 'main: matches "Funded by"'
              when c.scheme is null then 'main: earliest open (no "Funded by")'
              else 'main: earliest open; REVIEW: "Funded by" (' || c.scheme || ') has no open enrolment' end as why
    from ranked r join public.car_clients c on c.id = r.client_id
   where r.pick = 1
),
already as (  -- on a re-run after update 158: enrolments already there (read with a SELECT only)
  select c.id as client_id,
         case when to_regclass('public.client_enrolments') is null then 0
              else (xpath('/row/n/text()', query_to_xml(format('select count(*) as n from public.client_enrolments where client_id = %L', c.id), false, true, '')))[1]::text::int end as n
    from public.car_clients c
),
upcoming as (  -- rostered client shifts from today on (listed only; never changed)
  select sh.client_id,
         count(*) filter (where sh.service_id is null) as no_service,
         count(*) filter (where sh.service_id is not null and not exists (
           select 1 from public.client_services s join ranked r on r.client_id = sh.client_id and r.program_id = s.program_id
            where s.id = sh.service_id
              and (sh.starts_at at time zone 'Australia/Sydney')::date >= r.starts_on
              and (r.ends_on is null or (sh.starts_at at time zone 'Australia/Sydney')::date <= r.ends_on))) as outside_dates
    from public.shifts sh
   where sh.client_id is not null and sh.status <> 'cancelled'
     and sh.starts_at >= (select today from sydney)::timestamp at time zone 'Australia/Sydney'
   group by 1
),
rows as (
  -- 1. SUMMARY
  select 1 as section, 'SUMMARY' as kind, '' as ref, '' as client, '' as client_status, '' as funded_by,
         'Clients' as program, (select count(*) from public.car_clients)::text as source, '' as enrolment, null::date as starts_on, null::date as ends_on, '' as main, '' as flag
  union all select 1, 'SUMMARY', '', '', '', '', 'Proposed enrolments (active / ended)',
         (select count(*) filter (where status = 'active') || ' / ' || count(*) filter (where status = 'ended') from proposed), '', null, null, '', ''
  union all select 1, 'SUMMARY', '', '', '', '', 'Clients with no active program after update 158',
         (select count(*) from public.car_clients c where not exists (select 1 from proposed p where p.client_id = c.id and p.status = 'active'))::text, '', null, null, '', ''
  union all select 1, 'SUMMARY', '', '', '', '', 'Clients needing review (section 3)',
         (select count(distinct c.id) from public.car_clients c
           where not exists (select 1 from proposed p where p.client_id = c.id)
              or exists (select 1 from proposed p where p.client_id = c.id and (p.flag like '%CONFLICT%' or p.flag like '%AMBIGUOUS%'))
              or exists (select 1 from main m where m.client_id = c.id and m.why like '%REVIEW%')
              or exists (select 1 from upcoming u where u.client_id = c.id and (u.no_service > 0 or u.outside_dates > 0)))::text, '', null, null, '', ''
  -- 2. ENROLMENT
  union all
  select 2, 'ENROLMENT', c.client_ref, c.name, c.status, coalesce(c.scheme, '-'),
         r.program || ' (' || r.scheme || ')', r.source, r.status, r.starts_on, r.ends_on,
         coalesce(case when m.program_id = r.program_id then m.why end, ''),
         concat_ws('; ', nullif(r.flag, ''), case when a.n > 0 then 'ALREADY THERE: client has ' || a.n || ' enrolment(s); update 158 adds only missing open ones' end)
    from ranked r join public.car_clients c on c.id = r.client_id
    left join main m on m.client_id = r.client_id
    left join already a on a.client_id = r.client_id
  -- 3. REVIEW
  union all
  select 3, 'REVIEW', c.client_ref, c.name, c.status, coalesce(c.scheme, '-'), '', '', '', null, null, '',
         case when c.scheme is not null and not exists (select 1 from public.client_programs p where p.scheme = c.scheme and p.active)
              then 'AMBIGUOUS: "Funded by" scheme has no active program; no enrolment can be made from it'
              else 'NO PROGRAM: no "Funded by" and no services; no enrolment; shown as "No active program" (To check item)' end
    from public.car_clients c
   where not exists (select 1 from proposed p where p.client_id = c.id)
  union all
  select 3, 'REVIEW', c.client_ref, c.name, c.status, coalesce(c.scheme, '-'), r.program || ' (' || r.scheme || ')', '', r.status, r.starts_on, r.ends_on, '', r.flag
    from ranked r join public.car_clients c on c.id = r.client_id
   where r.flag like '%CONFLICT%' or r.flag like '%AMBIGUOUS%'
  union all
  select 3, 'REVIEW', c.client_ref, c.name, c.status, coalesce(c.scheme, '-'), '', '', '', null, null, m.why, 'main program chosen without a matching "Funded by"'
    from main m join public.car_clients c on c.id = m.client_id
   where m.why like '%REVIEW%'
  union all
  select 3, 'REVIEW', c.client_ref, c.name, c.status, coalesce(c.scheme, '-'), '', '', '', null, null, '',
         concat_ws('; ',
           case when u.no_service > 0 then u.no_service || ' upcoming shift(s) with no Approved Service (allowed to stay; a change to them will need a service once update 158 runs)' end,
           case when u.outside_dates > 0 then u.outside_dates || ' upcoming shift(s) dated outside the proposed enrolment dates (left as they are; changes to them would be refused)' end)
    from upcoming u join public.car_clients c on c.id = u.client_id
   where u.no_service > 0 or u.outside_dates > 0
)
select section, kind, ref, client, client_status, funded_by, program, source, enrolment, starts_on, ends_on, main, flag
  from rows
 order by section, ref, starts_on nulls first, program;
