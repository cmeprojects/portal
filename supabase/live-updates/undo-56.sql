-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 56: removes My requests, their history, leave periods and shift
-- changes. Safe to run again.
begin;
drop table if exists public.shift_changes;
drop table if exists public.leave_periods;
drop table if exists public.request_events;
drop table if exists public.requests;
drop table if exists public.request_types;
drop function if exists public.escalate_requests();
drop function if exists public.request_action(uuid, text, text);
drop function if exists public.apply_request(uuid);
drop function if exists public.submit_request(text, text, jsonb, date, date, uuid);
drop function if exists public.notify_many(uuid[], text, text, text, text);
drop function if exists public.request_ref(uuid);
drop function if exists public.can_act_on_request(uuid);
drop function if exists public.request_approvers(uuid);
drop function if exists public.resolve_people(text[], uuid);
commit;
