-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 171 (internal functions locked). Safe to run again. Update 171 stores no data, so nothing
-- is kept (no undo_171_kept schema). WARNING: undoing reopens the two weaknesses update 171 closed
-- (a worker putting their own request into effect, anyone sending notices to anyone, and signed-out
-- visitors reading members-only settings).
begin;
grant execute on function public.apply_request(uuid) to authenticated;
grant execute on function public.notify_many(uuid[], text, text, text, text) to authenticated;
grant execute on function public.resolve_people(text[], uuid) to authenticated;
grant execute on function public.escalate_requests() to authenticated;
grant execute on function public.rule_on(text) to public, anon;
grant execute on function public.setting_roles(text) to public, anon;
grant execute on function public.can_take_tasks(uuid) to public, anon;
commit;
