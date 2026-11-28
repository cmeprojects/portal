-- Staff Portal · © cmeproject. All rights reserved.
-- Update 171 (Zero Trust review): four internal functions (apply_request, notify_many, resolve_people,
-- escalate_requests) can no longer be called directly by signed-in people; the database functions that
-- use them, and the scheduler, still can. Closes self-approval of requests and fake notices. Signed-out
-- visitors can no longer call rule_on (its error showed members-only settings), setting_roles or
-- can_take_tasks. Changes no data. Safe to run again. Undo: undo-171.sql.
begin;
revoke execute on function public.apply_request(uuid) from public, anon, authenticated;
revoke execute on function public.notify_many(uuid[], text, text, text, text) from public, anon, authenticated;
revoke execute on function public.resolve_people(text[], uuid) from public, anon, authenticated;
revoke execute on function public.escalate_requests() from public, anon, authenticated;
grant execute on function public.escalate_requests() to service_role;
revoke execute on function public.rule_on(text) from public, anon;
revoke execute on function public.setting_roles(text) from public, anon;
revoke execute on function public.can_take_tasks(uuid) from public, anon;
commit;
