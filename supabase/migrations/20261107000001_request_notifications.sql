-- Staff Portal · © cmeproject. All rights reserved.
--
-- The bell also tells staff admins when a manager approves or declines a
-- role or team change they asked for. Opening Staff & roles or Teams, or
-- "Mark all as seen", clears it.

alter table public.people_change_requests add column requester_seen_at timestamptz;

-- Old decisions don't suddenly appear in the bell.
update public.people_change_requests set requester_seen_at = now() where status <> 'pending';

-- Decided requests the signed-in person asked for and hasn't seen yet.
create function public.my_request_updates()
returns table (
  request_id uuid,
  kind text,
  status text,
  subject text,
  change text,
  decided_by_name text,
  decided_at timestamptz,
  note text
)
language sql
stable
security definer
set search_path = ''
as $$
  select r.id,
         r.kind,
         r.status,
         case when r.kind = 'team' then coalesce(t.name, 'A team')
              else coalesce(nullif(p.full_name, ''), p.email, 'Someone') end,
         case when r.kind = 'role'
              then coalesce((select j.name from public.job_titles j where j.id = (r.to_value ->> 'title')::uuid),
                            initcap(replace(r.to_value ->> 'role', '_', ' ')))
              else 'who is in the team' end,
         -- System admins stay hidden from other staff.
         case when d.role = 'system_admin' then 'Admin' else coalesce(nullif(d.full_name, ''), d.email, 'A manager') end,
         r.decided_at,
         r.decision_note
    from public.people_change_requests r
    left join public.profiles p on p.id = r.user_id
    left join public.teams t on t.id = r.team_id
    left join public.profiles d on d.id = r.decided_by
   where public.is_member()
     and r.requested_by = auth.uid()
     and r.status in ('approved', 'declined')
     and r.requester_seen_at is null
   order by r.decided_at desc
$$;

-- p_kind: 'role', 'team', or null for all.
create function public.mark_request_updates_seen(p_kind text default null)
returns void
language sql
security definer
set search_path = ''
as $$
  update public.people_change_requests
     set requester_seen_at = now()
   where requested_by = auth.uid()
     and status in ('approved', 'declined')
     and requester_seen_at is null
     and (p_kind is null or kind = p_kind)
$$;

revoke execute on function public.my_request_updates() from public, anon;
revoke execute on function public.mark_request_updates_seen(text) from public, anon;
grant execute on function public.my_request_updates() to authenticated;
grant execute on function public.mark_request_updates_seen(text) to authenticated;
