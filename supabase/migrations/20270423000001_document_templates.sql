-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 168): document templates for invoices, statements, receipts and credit notes
-- (owner, 23 Nov 2026; D-072). Documents use the current logo, theme colours and business details;
-- each kind has template settings (layout, which sections show, logo position, colours, header and
-- footer text). Templates are saved as versions (never changed); each issued document records the
-- version it used, so it can always be explained. The business name, ABN and address always print;
-- "Tax invoice" wording and GST print only when they apply (GST-registered business and a taxable
-- line, decided when the invoice is issued). No template setting changes either (review C5).
-- No new security definer function. Safe to run again.

create table if not exists public.document_templates (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  kind text not null check (kind in ('invoice', 'statement', 'receipt', 'credit_note')),
  version integer not null default 1,
  settings jsonb not null default '{}' check (jsonb_typeof(settings) = 'object'),
  note text not null default '' check (length(note) <= 300),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (kind, version)
);

-- Which template version each issued document used (added when the document's PDF is made).
create table if not exists public.document_issues (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null default public.default_org_id(),
  kind text not null check (kind in ('invoice', 'statement', 'receipt', 'credit_note')),
  document_id uuid not null,
  template_id uuid references public.document_templates (id),
  template_version integer,
  checksum text not null default '',
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  unique (kind, document_id)
);

create or replace function public.guard_document_template() returns trigger
language plpgsql set search_path = '' as $$
declare
  v_layout text;
begin
  if tg_op <> 'INSERT' then raise exception 'A template version never changes. Save a new version.'; end if;
  if public.from_portal() and not (public.billing_can('prices') or public.billing_can('approve') or public.is_system_admin()) then
    raise exception 'Only someone with the Billing prices or approve right changes document templates.';
  end if;
  v_layout := coalesce(new.settings ->> 'layout', 'full');
  if v_layout not in ('full', 'compact') then raise exception 'Choose the full or compact layout.'; end if;
  if coalesce(new.settings ->> 'logo_position', 'left') not in ('left', 'centre', 'right', 'none') then raise exception 'Choose where the logo goes.'; end if;
  if coalesce(new.settings ->> 'colour_source', 'theme') not in ('theme', 'custom') then raise exception 'Choose theme or custom colours.'; end if;
  if (new.settings ? 'primary' and coalesce(new.settings ->> 'primary', '') !~ '^#[0-9A-Fa-f]{6}$') or (new.settings ? 'accent' and coalesce(new.settings ->> 'accent', '') !~ '^#[0-9A-Fa-f]{6}$') then
    raise exception 'Colours are written like #134F8E.';
  end if;
  if length(coalesce(new.settings ->> 'header_note', '')) > 300 or length(coalesce(new.settings ->> 'footer_text', '')) > 300 or length(coalesce(new.settings ->> 'payment_note', '')) > 500 then
    raise exception 'Keep header and footer text short (300 characters; payment note 500).';
  end if;
  new.version := coalesce((select max(version) from public.document_templates where kind = new.kind), 0) + 1;
  new.created_by := auth.uid(); new.created_at := now();
  return new;
end;
$$;
create or replace function public.guard_document_issue() returns trigger
language plpgsql set search_path = '' as $$
begin
  if tg_op <> 'INSERT' then raise exception 'A document''s template record never changes.'; end if;
  new.created_by := auth.uid(); new.created_at := now();
  if new.template_id is not null then new.template_version := (select version from public.document_templates where id = new.template_id); end if;
  return new;
end;
$$;
drop trigger if exists guard_document_template on public.document_templates;
create trigger guard_document_template before insert or update or delete on public.document_templates for each row execute function public.guard_document_template();
drop trigger if exists guard_document_issue on public.document_issues;
create trigger guard_document_issue before insert or update or delete on public.document_issues for each row execute function public.guard_document_issue();
drop trigger if exists log_billing_setup on public.document_templates;
create trigger log_billing_setup after insert on public.document_templates for each row execute function public.log_car_setup('document_template');
drop trigger if exists stamp_billing_setup on public.document_templates;
create trigger stamp_billing_setup before insert on public.document_templates for each row execute function public.stamp_billing_updated();

alter table public.document_templates enable row level security;
drop policy if exists "billing see document_templates" on public.document_templates;
create policy "billing see document_templates" on public.document_templates for select to authenticated using (public.billing_can('view') or public.is_system_admin());
drop policy if exists "billing add document_templates" on public.document_templates;
create policy "billing add document_templates" on public.document_templates for insert to authenticated with check (public.billing_can('prices') or public.billing_can('approve') or public.is_system_admin());
grant select, insert on public.document_templates to authenticated;
revoke all on public.document_templates from anon;
alter table public.document_issues enable row level security;
drop policy if exists "billing see document_issues" on public.document_issues;
create policy "billing see document_issues" on public.document_issues for select to authenticated using (public.billing_can('view'));
drop policy if exists "billing add document_issues" on public.document_issues;
create policy "billing add document_issues" on public.document_issues for insert to authenticated
  with check (public.billing_can('invoice_issue') or public.billing_can('payment_record') or public.billing_can('invoice_prepare'));
grant select, insert on public.document_issues to authenticated;
revoke all on public.document_issues from anon;
revoke execute on function public.guard_document_template() from public, anon, authenticated;
revoke execute on function public.guard_document_issue() from public, anon, authenticated;

-- A first template of each kind: the full layout in the portal's theme.
insert into public.document_templates (kind, settings, note)
select k, jsonb_build_object('layout', 'full', 'logo_position', 'left', 'colour_source', 'theme', 'sections', '{}'::jsonb, 'header_note', '', 'footer_text', '', 'payment_note', ''), 'Starting template'
  from unnest(array['invoice', 'statement', 'receipt', 'credit_note']) k
 where not exists (select 1 from public.document_templates t where t.kind = k);
