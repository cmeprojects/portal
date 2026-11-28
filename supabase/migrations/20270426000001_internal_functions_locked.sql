-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 171, Zero Trust review, 28 Nov 2026): four internal functions were meant to be
-- called only by other database functions (the 2026 "My requests" update revoked them from everyone
-- and granted them to no one), but Supabase gives every new function to signed-in users by default,
-- so any signed-in person could call them directly:
--   * apply_request: put a staff request into effect (leave, availability, swaps, shift changes)
--     without it being approved. A worker could record their own pending leave.
--   * notify_many: send any notice (bell and email) to anyone, with any title, text and link.
--   * resolve_people: list who is in an approval group.
--   * escalate_requests: the scheduled escalation job (only the scheduler, as the service role).
-- They're now callable only from inside the database (by the functions that use them, which run as
-- their owner) and, for the escalation job, by the scheduler. Nothing else changes: approving a
-- request still puts it into effect, notices are still sent. No data changes. No new SECURITY
-- DEFINER function. Safe to run again.

revoke execute on function public.apply_request(uuid) from public, anon, authenticated;
revoke execute on function public.notify_many(uuid[], text, text, text, text) from public, anon, authenticated;
revoke execute on function public.resolve_people(text[], uuid) from public, anon, authenticated;
revoke execute on function public.escalate_requests() from public, anon, authenticated;
grant execute on function public.escalate_requests() to service_role;
