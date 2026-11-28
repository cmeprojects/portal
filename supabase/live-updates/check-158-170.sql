-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: READ ONLY check of which of updates 158 to 170 this copy has (Phase 5-6 review,
-- 27 Nov 2026). One SELECT; changes nothing. Expected on Dev today: 158 to 166 "yes", 167 to 171 "no",
-- 15 Billing actions. An undo_160_kept schema may exist from the earlier undo of 160 (expected).
select n as update_no, item, result from (values
  (158, 'Program enrolments (client_enrolments)', case when to_regclass('public.client_enrolments') is not null then 'yes' else 'no' end),
  (159, 'Assessments (client_assessments)', case when to_regclass('public.client_assessments') is not null then 'yes' else 'no' end),
  (160, 'Support plans (client_support_plans)', case when to_regclass('public.client_support_plans') is not null then 'yes' else 'no' end),
  (161, 'Billing terms (client_service_terms)', case when to_regclass('public.client_service_terms') is not null then 'yes' else 'no' end),
  (162, 'Billing lines (billing_lines, billing_calc)', case when to_regclass('public.billing_lines') is not null and to_regprocedure('public.billing_calc(uuid, text)') is not null then 'yes' else 'no' end),
  (163, 'Claims and invoices (claims, invoices, business_details)', case when to_regclass('public.claims') is not null and to_regclass('public.invoices') is not null and to_regclass('public.business_details') is not null then 'yes' else 'no' end),
  (164, 'Payments and reconciliation (payments, credit_notes, billing_line_locked)', case when to_regclass('public.payments') is not null and to_regclass('public.credit_notes') is not null and to_regprocedure('public.billing_line_locked(uuid)') is not null then 'yes' else 'no' end),
  (165, 'Suppliers and charges (client_charges, supplier_invoices, pathway budgets)', case when to_regclass('public.client_charges') is not null and to_regclass('public.supplier_invoices') is not null then 'yes' else 'no' end),
  (166, 'Financial reporting (billing_revenue, billing_integrity_checks)', case when to_regclass('public.billing_revenue') is not null and to_regprocedure('public.billing_integrity_checks()') is not null then 'yes' else 'no' end),
  (167, 'Service codes (service_catalogue.code)', case when exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'service_catalogue' and column_name = 'code') then 'yes' else 'no' end),
  (168, 'Document templates (document_templates)', case when to_regclass('public.document_templates') is not null then 'yes' else 'no' end),
  (169, 'Contracted hours (staff_contract_hours)', case when to_regclass('public.staff_contract_hours') is not null then 'yes' else 'no' end),
  (170, 'Roster billing checks (roster_billing_forecast)', case when to_regprocedure('public.roster_billing_forecast(date, date, uuid)') is not null then 'yes' else 'no' end),
  (171, 'Internal functions locked (apply_request not callable by signed-in people)', case when not has_function_privilege('authenticated', 'public.apply_request(uuid)', 'execute') then 'yes' else 'no' end),
  (0, 'Undo schemas present (an undo was run)', coalesce((select string_agg(nspname, ', ' order by nspname) from pg_namespace where nspname like 'undo\_%\_kept'), 'none')),
  (0, 'Billing actions registered (expect 15)', coalesce((select cardinality(actions)::text from public.app_modules where id = 'clients.billing'), 'missing'))
) v(n, item, result)
order by n = 0, n;
