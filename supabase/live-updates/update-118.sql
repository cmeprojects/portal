-- Staff Portal · © cmeproject. All rights reserved.
-- Update 118: more client details (required by scheme) and archiving with a
-- reason. Safe to run again. Undo: undo-118.sql. Run update 117 first.
begin;
--
-- cmeprojects (update 118; owner chose the fields on 17 Nov 2026): more client
-- details, required by scheme, and archiving with a reason.
--
--   * Names: title, first, middle and last name. When first and last are
--     filled in, the client's name is made from them (first and last).
--   * Optional details (sensitive part "Client details": managers and the
--     client's care manager only): gender, state, time zone (Sydney unless
--     changed), living situation, about them, religion, marital status,
--     Aboriginal and/or Torres Strait Islander status, country of birth,
--     nationality, tags. Religion, marital status and cultural identity are
--     sensitive information: collected only with consent, each has
--     "Prefer not to say".
--   * Required by scheme (readiness, before a service can start): NDIS
--     services need the NDIS number; Support at Home services need the My
--     Aged Care ID (date of birth for both, as before).
--   * Archiving: a client is archived (status Discharged) with a reason
--     (transferred, moved away, no longer needs support, funding ended, passed
--     away, their choice, or other with a note); who and when are recorded.
--     They're hidden from Cars and features. Nothing is deleted; they can be
--     made active again.
--   * Not added (owner): cost calculation, day/evening/night times and SMS
--     opt-in wait for rostering and client messaging.

alter table public.car_clients add column if not exists title text not null default ''
  check (title in ('', 'mr', 'mrs', 'ms', 'miss', 'mx', 'dr'));
alter table public.car_clients add column if not exists given_name text not null default '' check (length(given_name) <= 40);
alter table public.car_clients add column if not exists middle_name text not null default '' check (length(middle_name) <= 40);
alter table public.car_clients add column if not exists family_name text not null default '' check (length(family_name) <= 40);
alter table public.car_clients add column if not exists archive_reason text
  check (archive_reason in ('transferred', 'moved_away', 'no_longer_needed', 'funding_ended', 'passed_away', 'client_choice', 'other'));
alter table public.car_clients add column if not exists archive_note text not null default '' check (length(archive_note) <= 500);
alter table public.car_clients add column if not exists archived_at timestamptz;
alter table public.car_clients add column if not exists archived_by uuid references public.profiles (id);

alter table public.client_details add column if not exists gender text not null default ''
  check (gender in ('', 'female', 'male', 'non_binary', 'different_term', 'prefer_not_to_say'));
alter table public.client_details add column if not exists state text not null default ''
  check (state in ('', 'NSW', 'VIC', 'QLD', 'SA', 'WA', 'TAS', 'NT', 'ACT'));
alter table public.client_details add column if not exists time_zone text not null default 'Australia/Sydney'
  check (time_zone in ('Australia/Sydney', 'Australia/Melbourne', 'Australia/Brisbane', 'Australia/Adelaide', 'Australia/Darwin', 'Australia/Perth', 'Australia/Hobart', 'Australia/Lord_Howe'));
alter table public.client_details add column if not exists living_situation text not null default ''
  check (living_situation in ('', 'own_home', 'with_family', 'supported_accommodation', 'residential_care', 'other'));
alter table public.client_details add column if not exists about text not null default '' check (length(about) <= 2000);
alter table public.client_details add column if not exists religion text not null default '' check (length(religion) <= 60);
alter table public.client_details add column if not exists marital_status text not null default ''
  check (marital_status in ('', 'single', 'partnered', 'married', 'separated', 'divorced', 'widowed', 'prefer_not_to_say'));
alter table public.client_details add column if not exists atsi_status text not null default ''
  check (atsi_status in ('', 'aboriginal', 'torres_strait_islander', 'both', 'neither', 'prefer_not_to_say'));
alter table public.client_details add column if not exists country_of_birth text not null default '' check (length(country_of_birth) <= 60);
alter table public.client_details add column if not exists nationality text not null default '' check (length(nationality) <= 60);
alter table public.client_details add column if not exists tags text[] not null default '{}'
  check (cardinality(tags) <= 10 and array_to_string(tags, '') !~ '[<>]');

-- Names and archiving (alongside the existing client record guard).
create or replace function public.guard_client_names_and_archive()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.given_name := trim(new.given_name);
  new.middle_name := trim(new.middle_name);
  new.family_name := trim(new.family_name);
  if (new.given_name = '') <> (new.family_name = '') then
    raise exception 'Fill in both the first and last name.';
  end if;
  if new.given_name <> '' and (tg_op = 'INSERT' or (new.given_name, new.family_name) is distinct from (old.given_name, old.family_name)) then
    new.name := left(new.given_name || ' ' || new.family_name, 80);
  end if;
  if new.status = 'discharged' and (tg_op = 'INSERT' or old.status is distinct from 'discharged') then
    if new.archive_reason is null then
      raise exception 'Choose why this client is being archived.';
    end if;
    if new.archive_reason = 'other' and length(trim(new.archive_note)) = 0 then
      raise exception 'Say why this client is being archived.';
    end if;
    new.archived_at := now();
    new.archived_by := auth.uid();
    new.active := false;
  elsif tg_op = 'UPDATE' and old.status = 'discharged' and new.status <> 'discharged' then
    -- Made active again: shown again; the last archive reason stays on record.
    new.active := true;
  elsif tg_op = 'UPDATE' then
    new.archive_reason := old.archive_reason;
    new.archive_note := old.archive_note;
    new.archived_at := old.archived_at;
    new.archived_by := old.archived_by;
  end if;
  return new;
end;
$$;
revoke execute on function public.guard_client_names_and_archive() from public, anon, authenticated;
drop trigger if exists guard_client_names_and_archive on public.car_clients;
create trigger guard_client_names_and_archive before insert or update on public.car_clients
  for each row execute function public.guard_client_names_and_archive();

-- Readiness: each scheme's own identifier (never mixed).
create or replace function public.client_gaps(p_client uuid, p_program uuid, p_location uuid, p_consent_required boolean, p_consent_given date)
returns text[]
language sql
stable
set search_path = ''
as $$
  select array_remove(array[
    case when (select status from public.car_clients where id = p_client) is distinct from 'active'
         then 'The client isn''t active yet.' end,
    case when not exists (select 1 from public.client_locations l
                           where l.id = p_location and l.client_id = p_client and l.approved
                             and (l.from_date is null or l.from_date <= public.local_today())
                             and (l.to_date is null or l.to_date >= public.local_today()))
         then 'The service location isn''t approved and current.' end,
    case when not exists (select 1 from public.client_people where client_id = p_client and kind = 'emergency' and active)
         then 'No emergency contact.' end,
    case when not exists (select 1 from public.client_alerts where client_id = p_client and active)
         then 'Safety isn''t answered (add an alert, or record "No known safety alerts").' end,
    case when coalesce((select needs_dob from public.client_programs where id = p_program), false)
              and (select date_of_birth from public.client_details where client_id = p_client) is null
         then 'Date of birth is needed for this program.' end,
    case when (select scheme from public.client_programs where id = p_program) = 'ndis'
              and coalesce((select ndis_number from public.client_details where client_id = p_client), '') = ''
         then 'The NDIS number is needed for an NDIS service.' end,
    case when (select scheme from public.client_programs where id = p_program) = 'support_at_home'
              and coalesce((select aged_care_id from public.client_details where client_id = p_client), '') = ''
         then 'The My Aged Care ID is needed for a Support at Home service.' end,
    case when p_consent_required and p_consent_given is null
         then 'Consent is needed and hasn''t been recorded.' end
  ], null)
$$;
commit;
