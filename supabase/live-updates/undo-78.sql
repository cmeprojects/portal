-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 78: Contracts go back to Staff details access only. Safe to run again.
begin;
drop policy if exists "sign as yourself, at the right step" on public.contract_signatures;
create policy "sign as yourself, at the right step" on public.contract_signatures
  for insert to authenticated
  with check (((signer_id = ( SELECT auth.uid() AS uid)) AND ( SELECT is_member() AS is_member) AND (EXISTS ( SELECT 1
   FROM contracts c
  WHERE ((c.id = contract_signatures.contract_id) AND (c.content_hash = contract_signatures.content_hash) AND (((contract_signatures.party = 'employee'::text) AND (c.user_id = ( SELECT auth.uid() AS uid)) AND (c.status = 'awaiting_employee'::text) AND ((c.sign_by IS NULL) OR (c.sign_by >= local_today()))) OR ((contract_signatures.party = 'employer'::text) AND (c.user_id <> ( SELECT auth.uid() AS uid)) AND (c.status = 'awaiting_employer'::text) AND has_access('staff_details'::text, c.user_id))))))));

drop policy if exists "contracts: drafts can be deleted" on public.contracts;
create policy "contracts: drafts can be deleted" on public.contracts
  for delete to authenticated
  using (((status = 'draft'::text) AND (user_id <> ( SELECT auth.uid() AS uid)) AND has_access('staff_details'::text, user_id)));

drop policy if exists "contracts: people with access prepare them" on public.contracts;
create policy "contracts: people with access prepare them" on public.contracts
  for insert to authenticated
  with check ((( SELECT is_member() AS is_member) AND (status = 'draft'::text) AND (user_id <> ( SELECT auth.uid() AS uid)) AND has_access('staff_details'::text, user_id)));

drop policy if exists "contracts: people with access, or the employee signing" on public.contracts;
create policy "contracts: people with access, or the employee signing" on public.contracts
  for update to authenticated
  using ((( SELECT is_member() AS is_member) AND (((user_id <> ( SELECT auth.uid() AS uid)) AND has_access('staff_details'::text, user_id)) OR ((user_id = ( SELECT auth.uid() AS uid)) AND (status = 'awaiting_employee'::text)))))
  with check ((( SELECT is_member() AS is_member) AND (((user_id <> ( SELECT auth.uid() AS uid)) AND has_access('staff_details'::text, user_id)) OR (user_id = ( SELECT auth.uid() AS uid)))));

drop policy if exists "contracts: the employee and people with access" on public.contracts;
create policy "contracts: the employee and people with access" on public.contracts
  for select to authenticated
  using ((( SELECT is_member() AS is_member) AND (((user_id = ( SELECT auth.uid() AS uid)) AND (status <> 'draft'::text)) OR has_access('staff_details'::text, user_id))));

do $do$
begin
  if to_regclass('storage.objects') is null then
    return;
  end if;
  execute $q$drop policy if exists "contracts: the employee and people with access add files" on storage.objects$q$;
  execute $q$create policy "contracts: the employee and people with access add files" on storage.objects
  for insert to authenticated
  with check (((bucket_id = 'contracts'::text) AND ( SELECT is_member() AS is_member) AND (((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text) OR has_access('staff_details'::text, ((storage.foldername(name))[1])::uuid))))$q$;
  execute $q$drop policy if exists "contracts: the employee and people with access read" on storage.objects$q$;
  execute $q$create policy "contracts: the employee and people with access read" on storage.objects
  for select to authenticated
  using (((bucket_id = 'contracts'::text) AND (((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text) OR has_access('staff_details'::text, ((storage.foldername(name))[1])::uuid))))$q$;
end $do$;

CREATE OR REPLACE FUNCTION public.guard_contract()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  v_by uuid := auth.uid();
  v_holder boolean;
begin
  if tg_op = 'INSERT' then
    new.status := 'draft';
    new.created_by := v_by;
    new.content_hash := '';
    new.signed_pdf_path := '';
    new.signed_pdf_hash := '';
    new.sent_at := null;
    new.sent_by := null;
    new.completed_at := null;
    if new.supersedes is not null then
      if not exists (select 1 from public.contracts o where o.id = new.supersedes and o.user_id = new.user_id) then
        raise exception 'A new version must be for the same person.';
      end if;
      new.version := (select max(version) + 1 from public.contracts where id = new.supersedes or supersedes = new.supersedes);
    else
      new.version := 1;
    end if;
    return new;
  end if;

  new.updated_at := now();
  if v_by is null then
    return new; -- the daily job (expiring unsigned contracts)
  end if;
  v_holder := new.user_id <> v_by and public.has_access('staff_details', new.user_id);

  -- Once sent, the wording and who it's for never change.
  if old.status <> 'draft' and (new.title is distinct from old.title or new.body is distinct from old.body or new.user_id is distinct from old.user_id
      or new.version is distinct from old.version or new.supersedes is distinct from old.supersedes or new.content_hash is distinct from old.content_hash
      or new.sign_by is distinct from old.sign_by) then
    raise exception 'A sent contract can''t be changed. Make a new version instead.';
  end if;
  if new.signed_pdf_path is distinct from old.signed_pdf_path or new.signed_pdf_hash is distinct from old.signed_pdf_hash then
    if not (old.status = 'awaiting_employer' and new.status = 'fully_signed' and v_holder and old.signed_pdf_path = '') then
      raise exception 'The signed copy can only be added when the contract is fully signed.';
    end if;
  end if;

  if new.status is distinct from old.status then
    if old.status = 'draft' and new.status = 'awaiting_employee' and v_holder then
      new.content_hash := encode(sha256(convert_to(new.title || E'\n' || new.body, 'UTF8')), 'hex');
      new.sent_at := now();
      new.sent_by := v_by;
    elsif old.status in ('draft', 'awaiting_employee', 'awaiting_employer') and new.status = 'cancelled' and v_holder then
      null;
    elsif old.status = 'awaiting_employee' and new.status = 'expired' and v_holder and new.sign_by < public.local_today() then
      null;
    elsif old.status = 'awaiting_employee' and new.status = 'awaiting_employer'
          and exists (select 1 from public.contract_signatures s where s.contract_id = new.id and s.party = 'employee' and s.content_hash = new.content_hash) then
      null;
    elsif old.status = 'awaiting_employer' and new.status = 'fully_signed' and v_holder
          and new.signed_pdf_path <> '' and new.signed_pdf_hash ~ '^[0-9a-f]{64}$'
          and exists (select 1 from public.contract_signatures s where s.contract_id = new.id and s.party = 'employer' and s.content_hash = new.content_hash) then
      new.completed_at := now();
    elsif old.status = 'fully_signed' and new.status = 'superseded' and v_holder
          and exists (select 1 from public.contracts n where n.supersedes = new.id and n.status = 'fully_signed') then
      null;
    else
      raise exception 'That step isn''t allowed for this contract right now.';
    end if;
  elsif old.status <> 'draft' and (to_jsonb(new) - 'updated_at') is distinct from (to_jsonb(old) - 'updated_at') then
    raise exception 'A sent contract can''t be changed. Make a new version instead.';
  end if;
  if old.status = 'draft' and not v_holder then
    raise exception 'You don''t have access to prepare contracts for this person.';
  end if;
  return new;
end;
$function$;
drop function if exists public.contract_access(text, uuid);
commit;
