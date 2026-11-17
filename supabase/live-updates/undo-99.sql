-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 99: staff requests go back to the built-in "managers, staff
-- admins and the system admin" rule. Copied defaults are kept (no effect).
-- Safe to run again.
begin;
update public.app_modules set grant_ready = false where id = 'hr.requests' and grant_ready;
drop policy if exists "the person and people managers see leave" on public.leave_periods;
create policy "the person and people managers see leave" on public.leave_periods for SELECT to authenticated using (((user_id = ( SELECT auth.uid() AS uid)) OR ( SELECT can_manage_people() AS can_manage_people) OR ( SELECT is_system_admin() AS is_system_admin) OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = ( SELECT auth.uid() AS uid)) AND (tm.user_id = leave_periods.user_id))))));
drop policy if exists "the person and people managers see shift changes" on public.shift_changes;
create policy "the person and people managers see shift changes" on public.shift_changes for SELECT to authenticated using (((user_id = ( SELECT auth.uid() AS uid)) OR ( SELECT can_manage_people() AS can_manage_people) OR ( SELECT is_system_admin() AS is_system_admin) OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = ( SELECT auth.uid() AS uid)) AND (tm.user_id = shift_changes.user_id))))));
drop policy if exists "people involved see a request" on public.requests;
create policy "people involved see a request" on public.requests for SELECT to authenticated using ((( SELECT feature_enabled('hr_requests'::text) AS feature_enabled) AND ((requester = ( SELECT auth.uid() AS uid)) OR (swap_with = ( SELECT auth.uid() AS uid)) OR ( SELECT can_manage_people() AS can_manage_people) OR ( SELECT is_system_admin() AS is_system_admin) OR can_act_on_request(id))));
CREATE OR REPLACE FUNCTION public.request_action(p_request uuid, p_action text, p_comment text DEFAULT ''::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  r public.requests;
  t public.request_types;
  v_ref text;
  note text := left(coalesce(trim(p_comment), ''), 2000);
  title text;
begin
  select * into r from public.requests where id = p_request for update;
  if r.id is null then raise exception 'That request doesn''t exist.'; end if;
  select * into t from public.request_types where key = r.type;
  v_ref := public.request_ref(r.id);
  title := t.label || ' request ' || v_ref;
  if not public.feature_live('hr_requests') then raise exception 'My requests are switched off.'; end if;

  if p_action = 'comment' then
    if note = '' then raise exception 'Write a comment first.'; end if;
    if not (r.requester = auth.uid() or r.swap_with = auth.uid() or public.can_act_on_request(r.id) or public.can_manage_people()) then
      raise exception 'You can''t comment on this request.';
    end if;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'comment', note);
    -- A reply from the person answers "more information needed".
    if r.requester = auth.uid() and r.status = 'info_needed' then
      update public.requests set status = 'pending', updated_at = now() where id = r.id;
      perform public.notify_many(array(select public.request_approvers(r.id)), 'request_submitted', title || ' has more information', note, '/requests/' || r.id);
    elsif r.requester <> auth.uid() then
      perform public.notify(r.requester, 'request_decided', 'New comment on ' || title, note, '/requests/' || r.id, false);
    end if;
    return 'Comment added.';
  end if;

  if p_action = 'withdraw' then
    if r.requester <> auth.uid() then raise exception 'Only the person who sent it can withdraw it.'; end if;
    if r.status not in ('pending', 'info_needed') then raise exception 'It''s already been decided.'; end if;
    update public.requests set status = 'withdrawn', updated_at = now(), decided_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'withdrawn', note);
    return 'Request withdrawn.';
  end if;

  if p_action in ('partner_accept', 'partner_decline') then
    if r.swap_with is distinct from auth.uid() then raise exception 'Only the person asked to swap can answer this.'; end if;
    if r.partner_ok is not null or r.status <> 'pending' then raise exception 'You''ve already answered.'; end if;
    if p_action = 'partner_accept' then
      update public.requests set partner_ok = true, updated_at = now() where id = r.id;
      insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'partner_accepted', note);
      perform public.notify_many(array(select public.request_approvers(r.id)), 'request_submitted', title || ' is ready to approve', 'Both people agreed to the swap.', '/requests/' || r.id);
      perform public.notify(r.requester, 'request_decided', 'Your swap was accepted', v_ref || ' now goes for approval.', '/requests/' || r.id, false);
      return 'Thanks. It now goes for approval.';
    end if;
    update public.requests set partner_ok = false, status = 'declined', updated_at = now(), decided_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'partner_declined', note);
    perform public.notify(r.requester, 'request_decided', 'Your swap was declined', coalesce(nullif(note, ''), v_ref), '/requests/' || r.id, true);
    return 'Swap declined.';
  end if;

  -- Approver actions
  if not public.can_act_on_request(r.id) then raise exception 'You''re not an approver for this request.'; end if;
  if r.status not in ('pending', 'info_needed') then raise exception 'It''s already been decided.'; end if;
  if r.type = 'swap' and r.partner_ok is not true then raise exception 'Wait until the other person accepts the swap.'; end if;

  if p_action = 'info' then
    if note = '' then raise exception 'Say what information you need.'; end if;
    update public.requests set status = 'info_needed', updated_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'info_requested', note);
    perform public.notify(r.requester, 'request_decided', 'More information needed for ' || title, note, '/requests/' || r.id, true);
    return 'Asked for more information.';
  elsif p_action = 'decline' then
    if note = '' then raise exception 'Give a reason for declining.'; end if;
    update public.requests set status = 'declined', updated_at = now(), decided_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'declined', note);
    perform public.notify(r.requester, 'request_decided', title || ' was declined', note, '/requests/' || r.id, true);
    return 'Request declined.';
  elsif p_action = 'approve' then
    -- Two-step approval means two people, unless nobody else can give the final one.
    if r.stage = 2 and not public.is_system_admin()
       and exists (select 1 from public.request_events where request_id = r.id and type = 'approved_first' and actor = auth.uid())
       and exists (select 1 from public.request_approvers(r.id) a where a <> auth.uid()) then
      raise exception 'You gave the first approval. Someone else needs to give the final one.';
    end if;
    if r.stage = 1 and cardinality(t.second_approvers) > 0 and exists (select 1 from public.resolve_people(t.second_approvers, r.requester)) then
      update public.requests set stage = 2, status = 'pending', updated_at = now(), escalated_at = null where id = r.id;
      insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'approved_first', note);
      perform public.notify_many(array(select public.request_approvers(r.id)), 'request_submitted', title || ' needs final approval', 'First approval done.', '/requests/' || r.id);
      perform public.notify(r.requester, 'request_decided', title || ': first approval done', 'It now goes for final approval.', '/requests/' || r.id, false);
      return 'Approved. It now goes for final approval.';
    end if;
    update public.requests set status = 'approved', updated_at = now(), decided_at = now() where id = r.id;
    insert into public.request_events (request_id, actor, type, comment) values (r.id, auth.uid(), 'approved', note);
    perform public.apply_request(r.id);
    perform public.notify(r.requester, 'request_decided', title || ' was approved', coalesce(nullif(note, ''), 'Approved.'), '/requests/' || r.id, true);
    if r.swap_with is not null then
      perform public.notify(r.swap_with, 'request_decided', 'The shift swap ' || v_ref || ' was approved', '', '/requests/' || r.id, true);
    end if;
    return 'Request approved.';
  end if;
  raise exception 'Unknown action.';
end;
$function$;
commit;
