begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|admin_delegations|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.admin_delegations x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|admin_delegations|UPDATE
with u as (update public.admin_delegations set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|admin_delegations|DELETE
with d as (delete from public.admin_delegations returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|app_settings|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.app_settings x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|app_settings|UPDATE
with u as (update public.app_settings set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|app_settings|DELETE
with d as (delete from public.app_settings returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_chats|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_chats x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_chats|UPDATE
with u as (update public.assistant_chats set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_chats|DELETE
with d as (delete from public.assistant_chats returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_documents|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_documents x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_documents|UPDATE
with u as (update public.assistant_documents set title = title returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_documents|DELETE
with d as (delete from public.assistant_documents returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_messages|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_messages x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_messages|UPDATE
with u as (update public.assistant_messages set chat_id = chat_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_messages|DELETE
with d as (delete from public.assistant_messages returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_questions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_questions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_questions|UPDATE
with u as (update public.assistant_questions set question = question returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_questions|DELETE
with d as (delete from public.assistant_questions returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_settings|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_settings x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_settings|UPDATE
with u as (update public.assistant_settings set model = model returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|assistant_settings|DELETE
with d as (delete from public.assistant_settings returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|audit_log|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.audit_log x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|audit_log|UPDATE
with u as (update public.audit_log set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|audit_log|DELETE
with d as (delete from public.audit_log returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|car_clients|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_clients x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|car_clients|UPDATE
with u as (update public.car_clients set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|car_clients|DELETE
with d as (delete from public.car_clients returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|car_purposes|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_purposes x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|car_purposes|UPDATE
with u as (update public.car_purposes set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|car_purposes|DELETE
with d as (delete from public.car_purposes returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|car_trips|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_trips x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|car_trips|UPDATE
with u as (update public.car_trips set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|car_trips|DELETE
with d as (delete from public.car_trips returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|cars|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.cars x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|cars|UPDATE
with u as (update public.cars set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|cars|DELETE
with d as (delete from public.cars returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|client_teams|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.client_teams x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|client_teams|UPDATE
with u as (update public.client_teams set client_id = client_id returning md5(row(client_id,team_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|client_teams|DELETE
with d as (delete from public.client_teams returning md5(row(client_id,team_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|compliance_items|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_items x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|compliance_items|UPDATE
with u as (update public.compliance_items set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|compliance_items|DELETE
with d as (delete from public.compliance_items returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|compliance_opens|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_opens x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|compliance_opens|UPDATE
with u as (update public.compliance_opens set item_id = item_id returning md5(row(item_id,user_id,version)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|compliance_opens|DELETE
with d as (delete from public.compliance_opens returning md5(row(item_id,user_id,version)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|compliance_records|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_records x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|compliance_records|UPDATE
with u as (update public.compliance_records set item_id = item_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|compliance_records|DELETE
with d as (delete from public.compliance_records returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_alerts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_alerts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_alerts|UPDATE
with u as (update public.custom_alerts set feature_id = feature_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_alerts|DELETE
with d as (delete from public.custom_alerts returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_client_targets|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_client_targets x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_client_targets|UPDATE
with u as (update public.custom_client_targets set feature_id = feature_id returning md5(row(feature_id,client_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_client_targets|DELETE
with d as (delete from public.custom_client_targets returning md5(row(feature_id,client_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_entries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_entries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_entries|UPDATE
with u as (update public.custom_entries set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_entries|DELETE
with d as (delete from public.custom_entries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_features|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_features x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_features|UPDATE
with u as (update public.custom_features set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_features|DELETE
with d as (delete from public.custom_features returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_fields|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_fields x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_fields|UPDATE
with u as (update public.custom_fields set feature_id = feature_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|custom_fields|DELETE
with d as (delete from public.custom_fields returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|delegation_rules|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.delegation_rules x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|delegation_rules|UPDATE
with u as (update public.delegation_rules set area = area returning md5((area)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|delegation_rules|DELETE
with d as (delete from public.delegation_rules returning md5((area)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|delegation_shares|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.delegation_shares x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|delegation_shares|UPDATE
with u as (update public.delegation_shares set area = area returning md5(row(area,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|delegation_shares|DELETE
with d as (delete from public.delegation_shares returning md5(row(area,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|features|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.features x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|features|UPDATE
with u as (update public.features set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|features|DELETE
with d as (delete from public.features returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_collaborators|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_collaborators x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_collaborators|UPDATE
with u as (update public.form_collaborators set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_collaborators|DELETE
with d as (delete from public.form_collaborators returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_completions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_completions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_completions|UPDATE
with u as (update public.form_completions set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_completions|DELETE
with d as (delete from public.form_completions returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_questions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_questions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_questions|UPDATE
with u as (update public.form_questions set form_id = form_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_questions|DELETE
with d as (delete from public.form_questions returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_recipients|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_recipients x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_recipients|UPDATE
with u as (update public.form_recipients set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_recipients|DELETE
with d as (delete from public.form_recipients returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_responses|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_responses x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_responses|UPDATE
with u as (update public.form_responses set form_id = form_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|form_responses|DELETE
with d as (delete from public.form_responses returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|forms|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.forms x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|forms|UPDATE
with u as (update public.forms set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|forms|DELETE
with d as (delete from public.forms returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|invitations|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.invitations x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|invitations|UPDATE
with u as (update public.invitations set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|invitations|DELETE
with d as (delete from public.invitations returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|job_titles|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.job_titles x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|job_titles|UPDATE
with u as (update public.job_titles set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|job_titles|DELETE
with d as (delete from public.job_titles returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|leave_periods|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.leave_periods x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|leave_periods|UPDATE
with u as (update public.leave_periods set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|leave_periods|DELETE
with d as (delete from public.leave_periods returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|live_signals|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.live_signals x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|live_signals|UPDATE
with u as (update public.live_signals set topic = topic returning md5((topic)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|live_signals|DELETE
with d as (delete from public.live_signals returning md5((topic)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|notifications|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.notifications x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|notifications|UPDATE
with u as (update public.notifications set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|notifications|DELETE
with d as (delete from public.notifications returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|organisation|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.organisation x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|organisation|UPDATE
with u as (update public.organisation set name = name returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|organisation|DELETE
with d as (delete from public.organisation returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|people_change_requests|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.people_change_requests x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|people_change_requests|UPDATE
with u as (update public.people_change_requests set kind = kind returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|people_change_requests|DELETE
with d as (delete from public.people_change_requests returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|profiles|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.profiles x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|profiles|UPDATE
with u as (update public.profiles set id = id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|profiles|DELETE
with d as (delete from public.profiles returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|record_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.record_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|record_events|UPDATE
with u as (update public.record_events set record_id = record_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|record_events|DELETE
with d as (delete from public.record_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|records|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.records x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|records|UPDATE
with u as (update public.records set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|records|DELETE
with d as (delete from public.records returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|register_templates|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.register_templates x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|register_templates|UPDATE
with u as (update public.register_templates set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|register_templates|DELETE
with d as (delete from public.register_templates returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|registries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|registries|UPDATE
with u as (update public.registries set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|registries|DELETE
with d as (delete from public.registries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|registry_fields|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registry_fields x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|registry_fields|UPDATE
with u as (update public.registry_fields set registry_id = registry_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|registry_fields|DELETE
with d as (delete from public.registry_fields returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|registry_managers|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registry_managers x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|registry_managers|UPDATE
with u as (update public.registry_managers set registry_id = registry_id returning md5(row(registry_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|registry_managers|DELETE
with d as (delete from public.registry_managers returning md5(row(registry_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|request_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.request_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|request_events|UPDATE
with u as (update public.request_events set request_id = request_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|request_events|DELETE
with d as (delete from public.request_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|request_types|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.request_types x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|request_types|UPDATE
with u as (update public.request_types set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|request_types|DELETE
with d as (delete from public.request_types returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|requests|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.requests x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|requests|UPDATE
with u as (update public.requests set type = type returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|requests|DELETE
with d as (delete from public.requests returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|settings_drafts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.settings_drafts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|settings_drafts|UPDATE
with u as (update public.settings_drafts set kind = kind returning md5(row(kind,key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|settings_drafts|DELETE
with d as (delete from public.settings_drafts returning md5(row(kind,key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|shift_changes|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.shift_changes x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|shift_changes|UPDATE
with u as (update public.shift_changes set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|shift_changes|DELETE
with d as (delete from public.shift_changes returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|staff_directory|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.staff_directory x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|staff_directory|UPDATE
with u as (update public.staff_directory set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|staff_directory|DELETE
with d as (delete from public.staff_directory returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|staff_private|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.staff_private x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|staff_private|UPDATE
with u as (update public.staff_private set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|staff_private|DELETE
with d as (delete from public.staff_private returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_alerts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_alerts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_alerts|UPDATE
with u as (update public.task_alerts set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_alerts|DELETE
with d as (delete from public.task_alerts returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_attachments|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_attachments x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_attachments|UPDATE
with u as (update public.task_attachments set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_attachments|DELETE
with d as (delete from public.task_attachments returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_events|UPDATE
with u as (update public.task_events set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_events|DELETE
with d as (delete from public.task_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_helpers|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_helpers x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_helpers|UPDATE
with u as (update public.task_helpers set task_id = task_id returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_helpers|DELETE
with d as (delete from public.task_helpers returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_views|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_views x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_views|UPDATE
with u as (update public.task_views set task_id = task_id returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|task_views|DELETE
with d as (delete from public.task_views returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|tasks|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.tasks x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|tasks|UPDATE
with u as (update public.tasks set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|tasks|DELETE
with d as (delete from public.tasks returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|team_leaders|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.team_leaders x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|team_leaders|UPDATE
with u as (update public.team_leaders set team_id = team_id returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|team_leaders|DELETE
with d as (delete from public.team_leaders returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|team_members|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.team_members x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|team_members|UPDATE
with u as (update public.team_members set team_id = team_id returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|team_members|DELETE
with d as (delete from public.team_members returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|teams|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.teams x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|teams|UPDATE
with u as (update public.teams set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|teams|DELETE
with d as (delete from public.teams returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|website_enquiries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.website_enquiries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|website_enquiries|UPDATE
with u as (update public.website_enquiries set full_name = full_name returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|website_enquiries|DELETE
with d as (delete from public.website_enquiries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|work_overrides|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.work_overrides x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|work_overrides|UPDATE
with u as (update public.work_overrides set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null; \echo system admin|work_overrides|DELETE
with d as (delete from public.work_overrides returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|admin_delegations|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.admin_delegations x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|admin_delegations|UPDATE
with u as (update public.admin_delegations set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|admin_delegations|DELETE
with d as (delete from public.admin_delegations returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|app_settings|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.app_settings x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|app_settings|UPDATE
with u as (update public.app_settings set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|app_settings|DELETE
with d as (delete from public.app_settings returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_chats|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_chats x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_chats|UPDATE
with u as (update public.assistant_chats set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_chats|DELETE
with d as (delete from public.assistant_chats returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_documents|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_documents x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_documents|UPDATE
with u as (update public.assistant_documents set title = title returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_documents|DELETE
with d as (delete from public.assistant_documents returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_messages|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_messages x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_messages|UPDATE
with u as (update public.assistant_messages set chat_id = chat_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_messages|DELETE
with d as (delete from public.assistant_messages returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_questions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_questions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_questions|UPDATE
with u as (update public.assistant_questions set question = question returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_questions|DELETE
with d as (delete from public.assistant_questions returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_settings|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_settings x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_settings|UPDATE
with u as (update public.assistant_settings set model = model returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|assistant_settings|DELETE
with d as (delete from public.assistant_settings returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|audit_log|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.audit_log x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|audit_log|UPDATE
with u as (update public.audit_log set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|audit_log|DELETE
with d as (delete from public.audit_log returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|car_clients|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_clients x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|car_clients|UPDATE
with u as (update public.car_clients set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|car_clients|DELETE
with d as (delete from public.car_clients returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|car_purposes|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_purposes x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|car_purposes|UPDATE
with u as (update public.car_purposes set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|car_purposes|DELETE
with d as (delete from public.car_purposes returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|car_trips|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_trips x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|car_trips|UPDATE
with u as (update public.car_trips set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|car_trips|DELETE
with d as (delete from public.car_trips returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|cars|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.cars x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|cars|UPDATE
with u as (update public.cars set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|cars|DELETE
with d as (delete from public.cars returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|client_teams|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.client_teams x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|client_teams|UPDATE
with u as (update public.client_teams set client_id = client_id returning md5(row(client_id,team_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|client_teams|DELETE
with d as (delete from public.client_teams returning md5(row(client_id,team_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|compliance_items|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_items x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|compliance_items|UPDATE
with u as (update public.compliance_items set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|compliance_items|DELETE
with d as (delete from public.compliance_items returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|compliance_opens|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_opens x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|compliance_opens|UPDATE
with u as (update public.compliance_opens set item_id = item_id returning md5(row(item_id,user_id,version)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|compliance_opens|DELETE
with d as (delete from public.compliance_opens returning md5(row(item_id,user_id,version)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|compliance_records|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_records x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|compliance_records|UPDATE
with u as (update public.compliance_records set item_id = item_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|compliance_records|DELETE
with d as (delete from public.compliance_records returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_alerts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_alerts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_alerts|UPDATE
with u as (update public.custom_alerts set feature_id = feature_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_alerts|DELETE
with d as (delete from public.custom_alerts returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_client_targets|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_client_targets x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_client_targets|UPDATE
with u as (update public.custom_client_targets set feature_id = feature_id returning md5(row(feature_id,client_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_client_targets|DELETE
with d as (delete from public.custom_client_targets returning md5(row(feature_id,client_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_entries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_entries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_entries|UPDATE
with u as (update public.custom_entries set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_entries|DELETE
with d as (delete from public.custom_entries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_features|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_features x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_features|UPDATE
with u as (update public.custom_features set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_features|DELETE
with d as (delete from public.custom_features returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_fields|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_fields x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_fields|UPDATE
with u as (update public.custom_fields set feature_id = feature_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|custom_fields|DELETE
with d as (delete from public.custom_fields returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|delegation_rules|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.delegation_rules x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|delegation_rules|UPDATE
with u as (update public.delegation_rules set area = area returning md5((area)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|delegation_rules|DELETE
with d as (delete from public.delegation_rules returning md5((area)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|delegation_shares|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.delegation_shares x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|delegation_shares|UPDATE
with u as (update public.delegation_shares set area = area returning md5(row(area,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|delegation_shares|DELETE
with d as (delete from public.delegation_shares returning md5(row(area,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|features|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.features x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|features|UPDATE
with u as (update public.features set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|features|DELETE
with d as (delete from public.features returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_collaborators|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_collaborators x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_collaborators|UPDATE
with u as (update public.form_collaborators set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_collaborators|DELETE
with d as (delete from public.form_collaborators returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_completions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_completions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_completions|UPDATE
with u as (update public.form_completions set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_completions|DELETE
with d as (delete from public.form_completions returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_questions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_questions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_questions|UPDATE
with u as (update public.form_questions set form_id = form_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_questions|DELETE
with d as (delete from public.form_questions returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_recipients|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_recipients x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_recipients|UPDATE
with u as (update public.form_recipients set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_recipients|DELETE
with d as (delete from public.form_recipients returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_responses|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_responses x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_responses|UPDATE
with u as (update public.form_responses set form_id = form_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|form_responses|DELETE
with d as (delete from public.form_responses returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|forms|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.forms x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|forms|UPDATE
with u as (update public.forms set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|forms|DELETE
with d as (delete from public.forms returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|invitations|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.invitations x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|invitations|UPDATE
with u as (update public.invitations set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|invitations|DELETE
with d as (delete from public.invitations returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|job_titles|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.job_titles x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|job_titles|UPDATE
with u as (update public.job_titles set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|job_titles|DELETE
with d as (delete from public.job_titles returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|leave_periods|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.leave_periods x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|leave_periods|UPDATE
with u as (update public.leave_periods set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|leave_periods|DELETE
with d as (delete from public.leave_periods returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|live_signals|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.live_signals x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|live_signals|UPDATE
with u as (update public.live_signals set topic = topic returning md5((topic)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|live_signals|DELETE
with d as (delete from public.live_signals returning md5((topic)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|notifications|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.notifications x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|notifications|UPDATE
with u as (update public.notifications set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|notifications|DELETE
with d as (delete from public.notifications returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|organisation|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.organisation x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|organisation|UPDATE
with u as (update public.organisation set name = name returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|organisation|DELETE
with d as (delete from public.organisation returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|people_change_requests|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.people_change_requests x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|people_change_requests|UPDATE
with u as (update public.people_change_requests set kind = kind returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|people_change_requests|DELETE
with d as (delete from public.people_change_requests returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|profiles|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.profiles x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|profiles|UPDATE
with u as (update public.profiles set id = id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|profiles|DELETE
with d as (delete from public.profiles returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|record_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.record_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|record_events|UPDATE
with u as (update public.record_events set record_id = record_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|record_events|DELETE
with d as (delete from public.record_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|records|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.records x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|records|UPDATE
with u as (update public.records set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|records|DELETE
with d as (delete from public.records returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|register_templates|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.register_templates x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|register_templates|UPDATE
with u as (update public.register_templates set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|register_templates|DELETE
with d as (delete from public.register_templates returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|registries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|registries|UPDATE
with u as (update public.registries set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|registries|DELETE
with d as (delete from public.registries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|registry_fields|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registry_fields x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|registry_fields|UPDATE
with u as (update public.registry_fields set registry_id = registry_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|registry_fields|DELETE
with d as (delete from public.registry_fields returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|registry_managers|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registry_managers x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|registry_managers|UPDATE
with u as (update public.registry_managers set registry_id = registry_id returning md5(row(registry_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|registry_managers|DELETE
with d as (delete from public.registry_managers returning md5(row(registry_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|request_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.request_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|request_events|UPDATE
with u as (update public.request_events set request_id = request_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|request_events|DELETE
with d as (delete from public.request_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|request_types|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.request_types x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|request_types|UPDATE
with u as (update public.request_types set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|request_types|DELETE
with d as (delete from public.request_types returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|requests|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.requests x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|requests|UPDATE
with u as (update public.requests set type = type returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|requests|DELETE
with d as (delete from public.requests returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|settings_drafts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.settings_drafts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|settings_drafts|UPDATE
with u as (update public.settings_drafts set kind = kind returning md5(row(kind,key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|settings_drafts|DELETE
with d as (delete from public.settings_drafts returning md5(row(kind,key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|shift_changes|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.shift_changes x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|shift_changes|UPDATE
with u as (update public.shift_changes set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|shift_changes|DELETE
with d as (delete from public.shift_changes returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|staff_directory|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.staff_directory x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|staff_directory|UPDATE
with u as (update public.staff_directory set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|staff_directory|DELETE
with d as (delete from public.staff_directory returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|staff_private|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.staff_private x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|staff_private|UPDATE
with u as (update public.staff_private set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|staff_private|DELETE
with d as (delete from public.staff_private returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_alerts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_alerts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_alerts|UPDATE
with u as (update public.task_alerts set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_alerts|DELETE
with d as (delete from public.task_alerts returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_attachments|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_attachments x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_attachments|UPDATE
with u as (update public.task_attachments set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_attachments|DELETE
with d as (delete from public.task_attachments returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_events|UPDATE
with u as (update public.task_events set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_events|DELETE
with d as (delete from public.task_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_helpers|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_helpers x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_helpers|UPDATE
with u as (update public.task_helpers set task_id = task_id returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_helpers|DELETE
with d as (delete from public.task_helpers returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_views|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_views x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_views|UPDATE
with u as (update public.task_views set task_id = task_id returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|task_views|DELETE
with d as (delete from public.task_views returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|tasks|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.tasks x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|tasks|UPDATE
with u as (update public.tasks set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|tasks|DELETE
with d as (delete from public.tasks returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|team_leaders|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.team_leaders x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|team_leaders|UPDATE
with u as (update public.team_leaders set team_id = team_id returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|team_leaders|DELETE
with d as (delete from public.team_leaders returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|team_members|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.team_members x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|team_members|UPDATE
with u as (update public.team_members set team_id = team_id returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|team_members|DELETE
with d as (delete from public.team_members returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|teams|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.teams x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|teams|UPDATE
with u as (update public.teams set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|teams|DELETE
with d as (delete from public.teams returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|website_enquiries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.website_enquiries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|website_enquiries|UPDATE
with u as (update public.website_enquiries set full_name = full_name returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|website_enquiries|DELETE
with d as (delete from public.website_enquiries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|work_overrides|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.work_overrides x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|work_overrides|UPDATE
with u as (update public.work_overrides set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null; \echo manager|work_overrides|DELETE
with d as (delete from public.work_overrides returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|admin_delegations|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.admin_delegations x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|admin_delegations|UPDATE
with u as (update public.admin_delegations set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|admin_delegations|DELETE
with d as (delete from public.admin_delegations returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|app_settings|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.app_settings x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|app_settings|UPDATE
with u as (update public.app_settings set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|app_settings|DELETE
with d as (delete from public.app_settings returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_chats|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_chats x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_chats|UPDATE
with u as (update public.assistant_chats set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_chats|DELETE
with d as (delete from public.assistant_chats returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_documents|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_documents x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_documents|UPDATE
with u as (update public.assistant_documents set title = title returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_documents|DELETE
with d as (delete from public.assistant_documents returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_messages|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_messages x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_messages|UPDATE
with u as (update public.assistant_messages set chat_id = chat_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_messages|DELETE
with d as (delete from public.assistant_messages returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_questions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_questions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_questions|UPDATE
with u as (update public.assistant_questions set question = question returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_questions|DELETE
with d as (delete from public.assistant_questions returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_settings|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_settings x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_settings|UPDATE
with u as (update public.assistant_settings set model = model returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|assistant_settings|DELETE
with d as (delete from public.assistant_settings returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|audit_log|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.audit_log x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|audit_log|UPDATE
with u as (update public.audit_log set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|audit_log|DELETE
with d as (delete from public.audit_log returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|car_clients|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_clients x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|car_clients|UPDATE
with u as (update public.car_clients set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|car_clients|DELETE
with d as (delete from public.car_clients returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|car_purposes|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_purposes x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|car_purposes|UPDATE
with u as (update public.car_purposes set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|car_purposes|DELETE
with d as (delete from public.car_purposes returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|car_trips|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_trips x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|car_trips|UPDATE
with u as (update public.car_trips set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|car_trips|DELETE
with d as (delete from public.car_trips returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|cars|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.cars x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|cars|UPDATE
with u as (update public.cars set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|cars|DELETE
with d as (delete from public.cars returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|client_teams|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.client_teams x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|client_teams|UPDATE
with u as (update public.client_teams set client_id = client_id returning md5(row(client_id,team_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|client_teams|DELETE
with d as (delete from public.client_teams returning md5(row(client_id,team_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|compliance_items|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_items x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|compliance_items|UPDATE
with u as (update public.compliance_items set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|compliance_items|DELETE
with d as (delete from public.compliance_items returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|compliance_opens|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_opens x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|compliance_opens|UPDATE
with u as (update public.compliance_opens set item_id = item_id returning md5(row(item_id,user_id,version)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|compliance_opens|DELETE
with d as (delete from public.compliance_opens returning md5(row(item_id,user_id,version)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|compliance_records|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_records x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|compliance_records|UPDATE
with u as (update public.compliance_records set item_id = item_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|compliance_records|DELETE
with d as (delete from public.compliance_records returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_alerts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_alerts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_alerts|UPDATE
with u as (update public.custom_alerts set feature_id = feature_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_alerts|DELETE
with d as (delete from public.custom_alerts returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_client_targets|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_client_targets x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_client_targets|UPDATE
with u as (update public.custom_client_targets set feature_id = feature_id returning md5(row(feature_id,client_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_client_targets|DELETE
with d as (delete from public.custom_client_targets returning md5(row(feature_id,client_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_entries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_entries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_entries|UPDATE
with u as (update public.custom_entries set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_entries|DELETE
with d as (delete from public.custom_entries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_features|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_features x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_features|UPDATE
with u as (update public.custom_features set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_features|DELETE
with d as (delete from public.custom_features returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_fields|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_fields x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_fields|UPDATE
with u as (update public.custom_fields set feature_id = feature_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|custom_fields|DELETE
with d as (delete from public.custom_fields returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|delegation_rules|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.delegation_rules x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|delegation_rules|UPDATE
with u as (update public.delegation_rules set area = area returning md5((area)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|delegation_rules|DELETE
with d as (delete from public.delegation_rules returning md5((area)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|delegation_shares|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.delegation_shares x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|delegation_shares|UPDATE
with u as (update public.delegation_shares set area = area returning md5(row(area,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|delegation_shares|DELETE
with d as (delete from public.delegation_shares returning md5(row(area,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|features|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.features x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|features|UPDATE
with u as (update public.features set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|features|DELETE
with d as (delete from public.features returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_collaborators|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_collaborators x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_collaborators|UPDATE
with u as (update public.form_collaborators set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_collaborators|DELETE
with d as (delete from public.form_collaborators returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_completions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_completions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_completions|UPDATE
with u as (update public.form_completions set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_completions|DELETE
with d as (delete from public.form_completions returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_questions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_questions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_questions|UPDATE
with u as (update public.form_questions set form_id = form_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_questions|DELETE
with d as (delete from public.form_questions returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_recipients|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_recipients x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_recipients|UPDATE
with u as (update public.form_recipients set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_recipients|DELETE
with d as (delete from public.form_recipients returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_responses|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_responses x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_responses|UPDATE
with u as (update public.form_responses set form_id = form_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|form_responses|DELETE
with d as (delete from public.form_responses returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|forms|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.forms x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|forms|UPDATE
with u as (update public.forms set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|forms|DELETE
with d as (delete from public.forms returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|invitations|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.invitations x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|invitations|UPDATE
with u as (update public.invitations set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|invitations|DELETE
with d as (delete from public.invitations returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|job_titles|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.job_titles x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|job_titles|UPDATE
with u as (update public.job_titles set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|job_titles|DELETE
with d as (delete from public.job_titles returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|leave_periods|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.leave_periods x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|leave_periods|UPDATE
with u as (update public.leave_periods set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|leave_periods|DELETE
with d as (delete from public.leave_periods returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|live_signals|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.live_signals x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|live_signals|UPDATE
with u as (update public.live_signals set topic = topic returning md5((topic)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|live_signals|DELETE
with d as (delete from public.live_signals returning md5((topic)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|notifications|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.notifications x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|notifications|UPDATE
with u as (update public.notifications set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|notifications|DELETE
with d as (delete from public.notifications returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|organisation|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.organisation x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|organisation|UPDATE
with u as (update public.organisation set name = name returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|organisation|DELETE
with d as (delete from public.organisation returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|people_change_requests|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.people_change_requests x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|people_change_requests|UPDATE
with u as (update public.people_change_requests set kind = kind returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|people_change_requests|DELETE
with d as (delete from public.people_change_requests returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|profiles|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.profiles x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|profiles|UPDATE
with u as (update public.profiles set id = id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|profiles|DELETE
with d as (delete from public.profiles returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|record_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.record_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|record_events|UPDATE
with u as (update public.record_events set record_id = record_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|record_events|DELETE
with d as (delete from public.record_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|records|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.records x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|records|UPDATE
with u as (update public.records set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|records|DELETE
with d as (delete from public.records returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|register_templates|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.register_templates x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|register_templates|UPDATE
with u as (update public.register_templates set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|register_templates|DELETE
with d as (delete from public.register_templates returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|registries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|registries|UPDATE
with u as (update public.registries set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|registries|DELETE
with d as (delete from public.registries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|registry_fields|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registry_fields x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|registry_fields|UPDATE
with u as (update public.registry_fields set registry_id = registry_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|registry_fields|DELETE
with d as (delete from public.registry_fields returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|registry_managers|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registry_managers x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|registry_managers|UPDATE
with u as (update public.registry_managers set registry_id = registry_id returning md5(row(registry_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|registry_managers|DELETE
with d as (delete from public.registry_managers returning md5(row(registry_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|request_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.request_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|request_events|UPDATE
with u as (update public.request_events set request_id = request_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|request_events|DELETE
with d as (delete from public.request_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|request_types|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.request_types x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|request_types|UPDATE
with u as (update public.request_types set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|request_types|DELETE
with d as (delete from public.request_types returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|requests|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.requests x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|requests|UPDATE
with u as (update public.requests set type = type returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|requests|DELETE
with d as (delete from public.requests returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|settings_drafts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.settings_drafts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|settings_drafts|UPDATE
with u as (update public.settings_drafts set kind = kind returning md5(row(kind,key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|settings_drafts|DELETE
with d as (delete from public.settings_drafts returning md5(row(kind,key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|shift_changes|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.shift_changes x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|shift_changes|UPDATE
with u as (update public.shift_changes set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|shift_changes|DELETE
with d as (delete from public.shift_changes returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|staff_directory|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.staff_directory x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|staff_directory|UPDATE
with u as (update public.staff_directory set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|staff_directory|DELETE
with d as (delete from public.staff_directory returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|staff_private|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.staff_private x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|staff_private|UPDATE
with u as (update public.staff_private set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|staff_private|DELETE
with d as (delete from public.staff_private returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_alerts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_alerts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_alerts|UPDATE
with u as (update public.task_alerts set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_alerts|DELETE
with d as (delete from public.task_alerts returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_attachments|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_attachments x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_attachments|UPDATE
with u as (update public.task_attachments set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_attachments|DELETE
with d as (delete from public.task_attachments returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_events|UPDATE
with u as (update public.task_events set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_events|DELETE
with d as (delete from public.task_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_helpers|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_helpers x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_helpers|UPDATE
with u as (update public.task_helpers set task_id = task_id returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_helpers|DELETE
with d as (delete from public.task_helpers returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_views|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_views x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_views|UPDATE
with u as (update public.task_views set task_id = task_id returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|task_views|DELETE
with d as (delete from public.task_views returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|tasks|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.tasks x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|tasks|UPDATE
with u as (update public.tasks set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|tasks|DELETE
with d as (delete from public.tasks returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|team_leaders|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.team_leaders x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|team_leaders|UPDATE
with u as (update public.team_leaders set team_id = team_id returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|team_leaders|DELETE
with d as (delete from public.team_leaders returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|team_members|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.team_members x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|team_members|UPDATE
with u as (update public.team_members set team_id = team_id returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|team_members|DELETE
with d as (delete from public.team_members returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|teams|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.teams x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|teams|UPDATE
with u as (update public.teams set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|teams|DELETE
with d as (delete from public.teams returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|website_enquiries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.website_enquiries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|website_enquiries|UPDATE
with u as (update public.website_enquiries set full_name = full_name returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|website_enquiries|DELETE
with d as (delete from public.website_enquiries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|work_overrides|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.work_overrides x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|work_overrides|UPDATE
with u as (update public.work_overrides set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff admin|work_overrides|DELETE
with d as (delete from public.work_overrides returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|admin_delegations|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.admin_delegations x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|admin_delegations|UPDATE
with u as (update public.admin_delegations set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|admin_delegations|DELETE
with d as (delete from public.admin_delegations returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|app_settings|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.app_settings x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|app_settings|UPDATE
with u as (update public.app_settings set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|app_settings|DELETE
with d as (delete from public.app_settings returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_chats|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_chats x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_chats|UPDATE
with u as (update public.assistant_chats set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_chats|DELETE
with d as (delete from public.assistant_chats returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_documents|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_documents x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_documents|UPDATE
with u as (update public.assistant_documents set title = title returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_documents|DELETE
with d as (delete from public.assistant_documents returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_messages|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_messages x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_messages|UPDATE
with u as (update public.assistant_messages set chat_id = chat_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_messages|DELETE
with d as (delete from public.assistant_messages returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_questions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_questions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_questions|UPDATE
with u as (update public.assistant_questions set question = question returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_questions|DELETE
with d as (delete from public.assistant_questions returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_settings|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_settings x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_settings|UPDATE
with u as (update public.assistant_settings set model = model returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|assistant_settings|DELETE
with d as (delete from public.assistant_settings returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|audit_log|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.audit_log x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|audit_log|UPDATE
with u as (update public.audit_log set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|audit_log|DELETE
with d as (delete from public.audit_log returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|car_clients|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_clients x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|car_clients|UPDATE
with u as (update public.car_clients set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|car_clients|DELETE
with d as (delete from public.car_clients returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|car_purposes|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_purposes x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|car_purposes|UPDATE
with u as (update public.car_purposes set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|car_purposes|DELETE
with d as (delete from public.car_purposes returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|car_trips|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_trips x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|car_trips|UPDATE
with u as (update public.car_trips set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|car_trips|DELETE
with d as (delete from public.car_trips returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|cars|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.cars x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|cars|UPDATE
with u as (update public.cars set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|cars|DELETE
with d as (delete from public.cars returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|client_teams|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.client_teams x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|client_teams|UPDATE
with u as (update public.client_teams set client_id = client_id returning md5(row(client_id,team_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|client_teams|DELETE
with d as (delete from public.client_teams returning md5(row(client_id,team_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|compliance_items|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_items x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|compliance_items|UPDATE
with u as (update public.compliance_items set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|compliance_items|DELETE
with d as (delete from public.compliance_items returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|compliance_opens|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_opens x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|compliance_opens|UPDATE
with u as (update public.compliance_opens set item_id = item_id returning md5(row(item_id,user_id,version)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|compliance_opens|DELETE
with d as (delete from public.compliance_opens returning md5(row(item_id,user_id,version)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|compliance_records|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_records x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|compliance_records|UPDATE
with u as (update public.compliance_records set item_id = item_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|compliance_records|DELETE
with d as (delete from public.compliance_records returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_alerts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_alerts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_alerts|UPDATE
with u as (update public.custom_alerts set feature_id = feature_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_alerts|DELETE
with d as (delete from public.custom_alerts returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_client_targets|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_client_targets x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_client_targets|UPDATE
with u as (update public.custom_client_targets set feature_id = feature_id returning md5(row(feature_id,client_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_client_targets|DELETE
with d as (delete from public.custom_client_targets returning md5(row(feature_id,client_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_entries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_entries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_entries|UPDATE
with u as (update public.custom_entries set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_entries|DELETE
with d as (delete from public.custom_entries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_features|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_features x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_features|UPDATE
with u as (update public.custom_features set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_features|DELETE
with d as (delete from public.custom_features returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_fields|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_fields x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_fields|UPDATE
with u as (update public.custom_fields set feature_id = feature_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|custom_fields|DELETE
with d as (delete from public.custom_fields returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|delegation_rules|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.delegation_rules x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|delegation_rules|UPDATE
with u as (update public.delegation_rules set area = area returning md5((area)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|delegation_rules|DELETE
with d as (delete from public.delegation_rules returning md5((area)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|delegation_shares|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.delegation_shares x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|delegation_shares|UPDATE
with u as (update public.delegation_shares set area = area returning md5(row(area,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|delegation_shares|DELETE
with d as (delete from public.delegation_shares returning md5(row(area,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|features|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.features x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|features|UPDATE
with u as (update public.features set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|features|DELETE
with d as (delete from public.features returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_collaborators|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_collaborators x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_collaborators|UPDATE
with u as (update public.form_collaborators set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_collaborators|DELETE
with d as (delete from public.form_collaborators returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_completions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_completions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_completions|UPDATE
with u as (update public.form_completions set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_completions|DELETE
with d as (delete from public.form_completions returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_questions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_questions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_questions|UPDATE
with u as (update public.form_questions set form_id = form_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_questions|DELETE
with d as (delete from public.form_questions returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_recipients|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_recipients x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_recipients|UPDATE
with u as (update public.form_recipients set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_recipients|DELETE
with d as (delete from public.form_recipients returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_responses|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_responses x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_responses|UPDATE
with u as (update public.form_responses set form_id = form_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|form_responses|DELETE
with d as (delete from public.form_responses returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|forms|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.forms x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|forms|UPDATE
with u as (update public.forms set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|forms|DELETE
with d as (delete from public.forms returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|invitations|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.invitations x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|invitations|UPDATE
with u as (update public.invitations set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|invitations|DELETE
with d as (delete from public.invitations returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|job_titles|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.job_titles x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|job_titles|UPDATE
with u as (update public.job_titles set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|job_titles|DELETE
with d as (delete from public.job_titles returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|leave_periods|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.leave_periods x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|leave_periods|UPDATE
with u as (update public.leave_periods set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|leave_periods|DELETE
with d as (delete from public.leave_periods returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|live_signals|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.live_signals x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|live_signals|UPDATE
with u as (update public.live_signals set topic = topic returning md5((topic)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|live_signals|DELETE
with d as (delete from public.live_signals returning md5((topic)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|notifications|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.notifications x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|notifications|UPDATE
with u as (update public.notifications set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|notifications|DELETE
with d as (delete from public.notifications returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|organisation|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.organisation x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|organisation|UPDATE
with u as (update public.organisation set name = name returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|organisation|DELETE
with d as (delete from public.organisation returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|people_change_requests|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.people_change_requests x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|people_change_requests|UPDATE
with u as (update public.people_change_requests set kind = kind returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|people_change_requests|DELETE
with d as (delete from public.people_change_requests returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|profiles|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.profiles x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|profiles|UPDATE
with u as (update public.profiles set id = id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|profiles|DELETE
with d as (delete from public.profiles returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|record_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.record_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|record_events|UPDATE
with u as (update public.record_events set record_id = record_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|record_events|DELETE
with d as (delete from public.record_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|records|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.records x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|records|UPDATE
with u as (update public.records set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|records|DELETE
with d as (delete from public.records returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|register_templates|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.register_templates x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|register_templates|UPDATE
with u as (update public.register_templates set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|register_templates|DELETE
with d as (delete from public.register_templates returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|registries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|registries|UPDATE
with u as (update public.registries set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|registries|DELETE
with d as (delete from public.registries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|registry_fields|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registry_fields x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|registry_fields|UPDATE
with u as (update public.registry_fields set registry_id = registry_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|registry_fields|DELETE
with d as (delete from public.registry_fields returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|registry_managers|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registry_managers x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|registry_managers|UPDATE
with u as (update public.registry_managers set registry_id = registry_id returning md5(row(registry_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|registry_managers|DELETE
with d as (delete from public.registry_managers returning md5(row(registry_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|request_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.request_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|request_events|UPDATE
with u as (update public.request_events set request_id = request_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|request_events|DELETE
with d as (delete from public.request_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|request_types|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.request_types x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|request_types|UPDATE
with u as (update public.request_types set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|request_types|DELETE
with d as (delete from public.request_types returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|requests|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.requests x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|requests|UPDATE
with u as (update public.requests set type = type returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|requests|DELETE
with d as (delete from public.requests returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|settings_drafts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.settings_drafts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|settings_drafts|UPDATE
with u as (update public.settings_drafts set kind = kind returning md5(row(kind,key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|settings_drafts|DELETE
with d as (delete from public.settings_drafts returning md5(row(kind,key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|shift_changes|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.shift_changes x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|shift_changes|UPDATE
with u as (update public.shift_changes set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|shift_changes|DELETE
with d as (delete from public.shift_changes returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|staff_directory|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.staff_directory x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|staff_directory|UPDATE
with u as (update public.staff_directory set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|staff_directory|DELETE
with d as (delete from public.staff_directory returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|staff_private|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.staff_private x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|staff_private|UPDATE
with u as (update public.staff_private set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|staff_private|DELETE
with d as (delete from public.staff_private returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_alerts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_alerts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_alerts|UPDATE
with u as (update public.task_alerts set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_alerts|DELETE
with d as (delete from public.task_alerts returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_attachments|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_attachments x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_attachments|UPDATE
with u as (update public.task_attachments set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_attachments|DELETE
with d as (delete from public.task_attachments returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_events|UPDATE
with u as (update public.task_events set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_events|DELETE
with d as (delete from public.task_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_helpers|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_helpers x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_helpers|UPDATE
with u as (update public.task_helpers set task_id = task_id returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_helpers|DELETE
with d as (delete from public.task_helpers returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_views|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_views x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_views|UPDATE
with u as (update public.task_views set task_id = task_id returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|task_views|DELETE
with d as (delete from public.task_views returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|tasks|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.tasks x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|tasks|UPDATE
with u as (update public.tasks set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|tasks|DELETE
with d as (delete from public.tasks returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|team_leaders|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.team_leaders x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|team_leaders|UPDATE
with u as (update public.team_leaders set team_id = team_id returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|team_leaders|DELETE
with d as (delete from public.team_leaders returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|team_members|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.team_members x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|team_members|UPDATE
with u as (update public.team_members set team_id = team_id returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|team_members|DELETE
with d as (delete from public.team_members returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|teams|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.teams x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|teams|UPDATE
with u as (update public.teams set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|teams|DELETE
with d as (delete from public.teams returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|website_enquiries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.website_enquiries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|website_enquiries|UPDATE
with u as (update public.website_enquiries set full_name = full_name returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|website_enquiries|DELETE
with d as (delete from public.website_enquiries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|work_overrides|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.work_overrides x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|work_overrides|UPDATE
with u as (update public.work_overrides set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null; \echo team leader|work_overrides|DELETE
with d as (delete from public.work_overrides returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|admin_delegations|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.admin_delegations x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|admin_delegations|UPDATE
with u as (update public.admin_delegations set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|admin_delegations|DELETE
with d as (delete from public.admin_delegations returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|app_settings|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.app_settings x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|app_settings|UPDATE
with u as (update public.app_settings set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|app_settings|DELETE
with d as (delete from public.app_settings returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_chats|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_chats x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_chats|UPDATE
with u as (update public.assistant_chats set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_chats|DELETE
with d as (delete from public.assistant_chats returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_documents|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_documents x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_documents|UPDATE
with u as (update public.assistant_documents set title = title returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_documents|DELETE
with d as (delete from public.assistant_documents returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_messages|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_messages x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_messages|UPDATE
with u as (update public.assistant_messages set chat_id = chat_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_messages|DELETE
with d as (delete from public.assistant_messages returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_questions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_questions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_questions|UPDATE
with u as (update public.assistant_questions set question = question returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_questions|DELETE
with d as (delete from public.assistant_questions returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_settings|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_settings x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_settings|UPDATE
with u as (update public.assistant_settings set model = model returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|assistant_settings|DELETE
with d as (delete from public.assistant_settings returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|audit_log|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.audit_log x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|audit_log|UPDATE
with u as (update public.audit_log set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|audit_log|DELETE
with d as (delete from public.audit_log returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|car_clients|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_clients x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|car_clients|UPDATE
with u as (update public.car_clients set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|car_clients|DELETE
with d as (delete from public.car_clients returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|car_purposes|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_purposes x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|car_purposes|UPDATE
with u as (update public.car_purposes set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|car_purposes|DELETE
with d as (delete from public.car_purposes returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|car_trips|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_trips x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|car_trips|UPDATE
with u as (update public.car_trips set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|car_trips|DELETE
with d as (delete from public.car_trips returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|cars|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.cars x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|cars|UPDATE
with u as (update public.cars set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|cars|DELETE
with d as (delete from public.cars returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|client_teams|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.client_teams x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|client_teams|UPDATE
with u as (update public.client_teams set client_id = client_id returning md5(row(client_id,team_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|client_teams|DELETE
with d as (delete from public.client_teams returning md5(row(client_id,team_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|compliance_items|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_items x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|compliance_items|UPDATE
with u as (update public.compliance_items set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|compliance_items|DELETE
with d as (delete from public.compliance_items returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|compliance_opens|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_opens x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|compliance_opens|UPDATE
with u as (update public.compliance_opens set item_id = item_id returning md5(row(item_id,user_id,version)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|compliance_opens|DELETE
with d as (delete from public.compliance_opens returning md5(row(item_id,user_id,version)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|compliance_records|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_records x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|compliance_records|UPDATE
with u as (update public.compliance_records set item_id = item_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|compliance_records|DELETE
with d as (delete from public.compliance_records returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_alerts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_alerts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_alerts|UPDATE
with u as (update public.custom_alerts set feature_id = feature_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_alerts|DELETE
with d as (delete from public.custom_alerts returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_client_targets|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_client_targets x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_client_targets|UPDATE
with u as (update public.custom_client_targets set feature_id = feature_id returning md5(row(feature_id,client_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_client_targets|DELETE
with d as (delete from public.custom_client_targets returning md5(row(feature_id,client_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_entries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_entries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_entries|UPDATE
with u as (update public.custom_entries set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_entries|DELETE
with d as (delete from public.custom_entries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_features|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_features x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_features|UPDATE
with u as (update public.custom_features set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_features|DELETE
with d as (delete from public.custom_features returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_fields|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_fields x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_fields|UPDATE
with u as (update public.custom_fields set feature_id = feature_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|custom_fields|DELETE
with d as (delete from public.custom_fields returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|delegation_rules|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.delegation_rules x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|delegation_rules|UPDATE
with u as (update public.delegation_rules set area = area returning md5((area)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|delegation_rules|DELETE
with d as (delete from public.delegation_rules returning md5((area)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|delegation_shares|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.delegation_shares x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|delegation_shares|UPDATE
with u as (update public.delegation_shares set area = area returning md5(row(area,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|delegation_shares|DELETE
with d as (delete from public.delegation_shares returning md5(row(area,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|features|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.features x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|features|UPDATE
with u as (update public.features set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|features|DELETE
with d as (delete from public.features returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_collaborators|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_collaborators x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_collaborators|UPDATE
with u as (update public.form_collaborators set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_collaborators|DELETE
with d as (delete from public.form_collaborators returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_completions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_completions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_completions|UPDATE
with u as (update public.form_completions set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_completions|DELETE
with d as (delete from public.form_completions returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_questions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_questions x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_questions|UPDATE
with u as (update public.form_questions set form_id = form_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_questions|DELETE
with d as (delete from public.form_questions returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_recipients|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_recipients x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_recipients|UPDATE
with u as (update public.form_recipients set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_recipients|DELETE
with d as (delete from public.form_recipients returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_responses|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_responses x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_responses|UPDATE
with u as (update public.form_responses set form_id = form_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|form_responses|DELETE
with d as (delete from public.form_responses returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|forms|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.forms x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|forms|UPDATE
with u as (update public.forms set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|forms|DELETE
with d as (delete from public.forms returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|invitations|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.invitations x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|invitations|UPDATE
with u as (update public.invitations set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|invitations|DELETE
with d as (delete from public.invitations returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|job_titles|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.job_titles x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|job_titles|UPDATE
with u as (update public.job_titles set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|job_titles|DELETE
with d as (delete from public.job_titles returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|leave_periods|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.leave_periods x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|leave_periods|UPDATE
with u as (update public.leave_periods set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|leave_periods|DELETE
with d as (delete from public.leave_periods returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|live_signals|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.live_signals x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|live_signals|UPDATE
with u as (update public.live_signals set topic = topic returning md5((topic)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|live_signals|DELETE
with d as (delete from public.live_signals returning md5((topic)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|notifications|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.notifications x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|notifications|UPDATE
with u as (update public.notifications set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|notifications|DELETE
with d as (delete from public.notifications returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|organisation|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.organisation x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|organisation|UPDATE
with u as (update public.organisation set name = name returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|organisation|DELETE
with d as (delete from public.organisation returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|people_change_requests|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.people_change_requests x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|people_change_requests|UPDATE
with u as (update public.people_change_requests set kind = kind returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|people_change_requests|DELETE
with d as (delete from public.people_change_requests returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|profiles|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.profiles x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|profiles|UPDATE
with u as (update public.profiles set id = id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|profiles|DELETE
with d as (delete from public.profiles returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|record_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.record_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|record_events|UPDATE
with u as (update public.record_events set record_id = record_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|record_events|DELETE
with d as (delete from public.record_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|records|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.records x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|records|UPDATE
with u as (update public.records set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|records|DELETE
with d as (delete from public.records returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|register_templates|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.register_templates x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|register_templates|UPDATE
with u as (update public.register_templates set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|register_templates|DELETE
with d as (delete from public.register_templates returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|registries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|registries|UPDATE
with u as (update public.registries set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|registries|DELETE
with d as (delete from public.registries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|registry_fields|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registry_fields x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|registry_fields|UPDATE
with u as (update public.registry_fields set registry_id = registry_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|registry_fields|DELETE
with d as (delete from public.registry_fields returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|registry_managers|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registry_managers x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|registry_managers|UPDATE
with u as (update public.registry_managers set registry_id = registry_id returning md5(row(registry_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|registry_managers|DELETE
with d as (delete from public.registry_managers returning md5(row(registry_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|request_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.request_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|request_events|UPDATE
with u as (update public.request_events set request_id = request_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|request_events|DELETE
with d as (delete from public.request_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|request_types|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.request_types x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|request_types|UPDATE
with u as (update public.request_types set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|request_types|DELETE
with d as (delete from public.request_types returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|requests|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.requests x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|requests|UPDATE
with u as (update public.requests set type = type returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|requests|DELETE
with d as (delete from public.requests returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|settings_drafts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.settings_drafts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|settings_drafts|UPDATE
with u as (update public.settings_drafts set kind = kind returning md5(row(kind,key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|settings_drafts|DELETE
with d as (delete from public.settings_drafts returning md5(row(kind,key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|shift_changes|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.shift_changes x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|shift_changes|UPDATE
with u as (update public.shift_changes set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|shift_changes|DELETE
with d as (delete from public.shift_changes returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|staff_directory|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.staff_directory x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|staff_directory|UPDATE
with u as (update public.staff_directory set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|staff_directory|DELETE
with d as (delete from public.staff_directory returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|staff_private|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.staff_private x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|staff_private|UPDATE
with u as (update public.staff_private set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|staff_private|DELETE
with d as (delete from public.staff_private returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_alerts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_alerts x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_alerts|UPDATE
with u as (update public.task_alerts set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_alerts|DELETE
with d as (delete from public.task_alerts returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_attachments|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_attachments x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_attachments|UPDATE
with u as (update public.task_attachments set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_attachments|DELETE
with d as (delete from public.task_attachments returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_events x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_events|UPDATE
with u as (update public.task_events set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_events|DELETE
with d as (delete from public.task_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_helpers|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_helpers x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_helpers|UPDATE
with u as (update public.task_helpers set task_id = task_id returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_helpers|DELETE
with d as (delete from public.task_helpers returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_views|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_views x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_views|UPDATE
with u as (update public.task_views set task_id = task_id returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|task_views|DELETE
with d as (delete from public.task_views returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|tasks|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.tasks x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|tasks|UPDATE
with u as (update public.tasks set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|tasks|DELETE
with d as (delete from public.tasks returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|team_leaders|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.team_leaders x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|team_leaders|UPDATE
with u as (update public.team_leaders set team_id = team_id returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|team_leaders|DELETE
with d as (delete from public.team_leaders returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|team_members|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.team_members x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|team_members|UPDATE
with u as (update public.team_members set team_id = team_id returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|team_members|DELETE
with d as (delete from public.team_members returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|teams|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.teams x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|teams|UPDATE
with u as (update public.teams set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|teams|DELETE
with d as (delete from public.teams returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|website_enquiries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.website_enquiries x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|website_enquiries|UPDATE
with u as (update public.website_enquiries set full_name = full_name returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|website_enquiries|DELETE
with d as (delete from public.website_enquiries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|work_overrides|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.work_overrides x);
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|work_overrides|UPDATE
with u as (update public.work_overrides set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null; \echo staff|work_overrides|DELETE
with d as (delete from public.work_overrides returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|admin_delegations|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.admin_delegations x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|admin_delegations|UPDATE
with u as (update public.admin_delegations set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|admin_delegations|DELETE
with d as (delete from public.admin_delegations returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|app_settings|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.app_settings x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|app_settings|UPDATE
with u as (update public.app_settings set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|app_settings|DELETE
with d as (delete from public.app_settings returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_chats|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_chats x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_chats|UPDATE
with u as (update public.assistant_chats set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_chats|DELETE
with d as (delete from public.assistant_chats returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_documents|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_documents x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_documents|UPDATE
with u as (update public.assistant_documents set title = title returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_documents|DELETE
with d as (delete from public.assistant_documents returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_messages|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_messages x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_messages|UPDATE
with u as (update public.assistant_messages set chat_id = chat_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_messages|DELETE
with d as (delete from public.assistant_messages returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_questions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_questions x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_questions|UPDATE
with u as (update public.assistant_questions set question = question returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_questions|DELETE
with d as (delete from public.assistant_questions returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_settings|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.assistant_settings x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_settings|UPDATE
with u as (update public.assistant_settings set model = model returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|assistant_settings|DELETE
with d as (delete from public.assistant_settings returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|audit_log|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.audit_log x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|audit_log|UPDATE
with u as (update public.audit_log set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|audit_log|DELETE
with d as (delete from public.audit_log returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|car_clients|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_clients x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|car_clients|UPDATE
with u as (update public.car_clients set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|car_clients|DELETE
with d as (delete from public.car_clients returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|car_purposes|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_purposes x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|car_purposes|UPDATE
with u as (update public.car_purposes set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|car_purposes|DELETE
with d as (delete from public.car_purposes returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|car_trips|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.car_trips x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|car_trips|UPDATE
with u as (update public.car_trips set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|car_trips|DELETE
with d as (delete from public.car_trips returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|cars|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.cars x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|cars|UPDATE
with u as (update public.cars set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|cars|DELETE
with d as (delete from public.cars returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|client_teams|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.client_teams x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|client_teams|UPDATE
with u as (update public.client_teams set client_id = client_id returning md5(row(client_id,team_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|client_teams|DELETE
with d as (delete from public.client_teams returning md5(row(client_id,team_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|compliance_items|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_items x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|compliance_items|UPDATE
with u as (update public.compliance_items set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|compliance_items|DELETE
with d as (delete from public.compliance_items returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|compliance_opens|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_opens x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|compliance_opens|UPDATE
with u as (update public.compliance_opens set item_id = item_id returning md5(row(item_id,user_id,version)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|compliance_opens|DELETE
with d as (delete from public.compliance_opens returning md5(row(item_id,user_id,version)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|compliance_records|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.compliance_records x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|compliance_records|UPDATE
with u as (update public.compliance_records set item_id = item_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|compliance_records|DELETE
with d as (delete from public.compliance_records returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_alerts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_alerts x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_alerts|UPDATE
with u as (update public.custom_alerts set feature_id = feature_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_alerts|DELETE
with d as (delete from public.custom_alerts returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_client_targets|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_client_targets x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_client_targets|UPDATE
with u as (update public.custom_client_targets set feature_id = feature_id returning md5(row(feature_id,client_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_client_targets|DELETE
with d as (delete from public.custom_client_targets returning md5(row(feature_id,client_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_entries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_entries x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_entries|UPDATE
with u as (update public.custom_entries set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_entries|DELETE
with d as (delete from public.custom_entries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_features|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_features x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_features|UPDATE
with u as (update public.custom_features set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_features|DELETE
with d as (delete from public.custom_features returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_fields|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.custom_fields x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_fields|UPDATE
with u as (update public.custom_fields set feature_id = feature_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|custom_fields|DELETE
with d as (delete from public.custom_fields returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|delegation_rules|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.delegation_rules x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|delegation_rules|UPDATE
with u as (update public.delegation_rules set area = area returning md5((area)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|delegation_rules|DELETE
with d as (delete from public.delegation_rules returning md5((area)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|delegation_shares|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.delegation_shares x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|delegation_shares|UPDATE
with u as (update public.delegation_shares set area = area returning md5(row(area,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|delegation_shares|DELETE
with d as (delete from public.delegation_shares returning md5(row(area,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|features|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.features x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|features|UPDATE
with u as (update public.features set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|features|DELETE
with d as (delete from public.features returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_collaborators|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_collaborators x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_collaborators|UPDATE
with u as (update public.form_collaborators set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_collaborators|DELETE
with d as (delete from public.form_collaborators returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_completions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_completions x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_completions|UPDATE
with u as (update public.form_completions set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_completions|DELETE
with d as (delete from public.form_completions returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_questions|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_questions x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_questions|UPDATE
with u as (update public.form_questions set form_id = form_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_questions|DELETE
with d as (delete from public.form_questions returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_recipients|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_recipients x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_recipients|UPDATE
with u as (update public.form_recipients set form_id = form_id returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_recipients|DELETE
with d as (delete from public.form_recipients returning md5(row(form_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_responses|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.form_responses x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_responses|UPDATE
with u as (update public.form_responses set form_id = form_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|form_responses|DELETE
with d as (delete from public.form_responses returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|forms|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.forms x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|forms|UPDATE
with u as (update public.forms set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|forms|DELETE
with d as (delete from public.forms returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|invitations|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.invitations x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|invitations|UPDATE
with u as (update public.invitations set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|invitations|DELETE
with d as (delete from public.invitations returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|job_titles|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.job_titles x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|job_titles|UPDATE
with u as (update public.job_titles set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|job_titles|DELETE
with d as (delete from public.job_titles returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|leave_periods|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.leave_periods x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|leave_periods|UPDATE
with u as (update public.leave_periods set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|leave_periods|DELETE
with d as (delete from public.leave_periods returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|live_signals|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.live_signals x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|live_signals|UPDATE
with u as (update public.live_signals set topic = topic returning md5((topic)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|live_signals|DELETE
with d as (delete from public.live_signals returning md5((topic)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|notifications|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.notifications x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|notifications|UPDATE
with u as (update public.notifications set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|notifications|DELETE
with d as (delete from public.notifications returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|organisation|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.organisation x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|organisation|UPDATE
with u as (update public.organisation set name = name returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|organisation|DELETE
with d as (delete from public.organisation returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|people_change_requests|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.people_change_requests x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|people_change_requests|UPDATE
with u as (update public.people_change_requests set kind = kind returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|people_change_requests|DELETE
with d as (delete from public.people_change_requests returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|profiles|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.profiles x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|profiles|UPDATE
with u as (update public.profiles set id = id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|profiles|DELETE
with d as (delete from public.profiles returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|record_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.record_events x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|record_events|UPDATE
with u as (update public.record_events set record_id = record_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|record_events|DELETE
with d as (delete from public.record_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|records|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.records x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|records|UPDATE
with u as (update public.records set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|records|DELETE
with d as (delete from public.records returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|register_templates|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.register_templates x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|register_templates|UPDATE
with u as (update public.register_templates set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|register_templates|DELETE
with d as (delete from public.register_templates returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|registries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registries x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|registries|UPDATE
with u as (update public.registries set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|registries|DELETE
with d as (delete from public.registries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|registry_fields|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registry_fields x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|registry_fields|UPDATE
with u as (update public.registry_fields set registry_id = registry_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|registry_fields|DELETE
with d as (delete from public.registry_fields returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|registry_managers|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.registry_managers x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|registry_managers|UPDATE
with u as (update public.registry_managers set registry_id = registry_id returning md5(row(registry_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|registry_managers|DELETE
with d as (delete from public.registry_managers returning md5(row(registry_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|request_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.request_events x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|request_events|UPDATE
with u as (update public.request_events set request_id = request_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|request_events|DELETE
with d as (delete from public.request_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|request_types|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.request_types x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|request_types|UPDATE
with u as (update public.request_types set key = key returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|request_types|DELETE
with d as (delete from public.request_types returning md5((key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|requests|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.requests x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|requests|UPDATE
with u as (update public.requests set type = type returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|requests|DELETE
with d as (delete from public.requests returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|settings_drafts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.settings_drafts x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|settings_drafts|UPDATE
with u as (update public.settings_drafts set kind = kind returning md5(row(kind,key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|settings_drafts|DELETE
with d as (delete from public.settings_drafts returning md5(row(kind,key)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|shift_changes|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.shift_changes x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|shift_changes|UPDATE
with u as (update public.shift_changes set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|shift_changes|DELETE
with d as (delete from public.shift_changes returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|staff_directory|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.staff_directory x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|staff_directory|UPDATE
with u as (update public.staff_directory set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|staff_directory|DELETE
with d as (delete from public.staff_directory returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|staff_private|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.staff_private x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|staff_private|UPDATE
with u as (update public.staff_private set user_id = user_id returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|staff_private|DELETE
with d as (delete from public.staff_private returning md5((user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_alerts|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_alerts x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_alerts|UPDATE
with u as (update public.task_alerts set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_alerts|DELETE
with d as (delete from public.task_alerts returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_attachments|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_attachments x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_attachments|UPDATE
with u as (update public.task_attachments set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_attachments|DELETE
with d as (delete from public.task_attachments returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_events|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_events x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_events|UPDATE
with u as (update public.task_events set task_id = task_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_events|DELETE
with d as (delete from public.task_events returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_helpers|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_helpers x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_helpers|UPDATE
with u as (update public.task_helpers set task_id = task_id returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_helpers|DELETE
with d as (delete from public.task_helpers returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_views|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.task_views x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_views|UPDATE
with u as (update public.task_views set task_id = task_id returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|task_views|DELETE
with d as (delete from public.task_views returning md5(row(task_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|tasks|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.tasks x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|tasks|UPDATE
with u as (update public.tasks set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|tasks|DELETE
with d as (delete from public.tasks returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|team_leaders|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.team_leaders x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|team_leaders|UPDATE
with u as (update public.team_leaders set team_id = team_id returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|team_leaders|DELETE
with d as (delete from public.team_leaders returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|team_members|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.team_members x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|team_members|UPDATE
with u as (update public.team_members set team_id = team_id returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|team_members|DELETE
with d as (delete from public.team_members returning md5(row(team_id,user_id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|teams|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.teams x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|teams|UPDATE
with u as (update public.teams set org_id = org_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|teams|DELETE
with d as (delete from public.teams returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|website_enquiries|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.website_enquiries x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|website_enquiries|UPDATE
with u as (update public.website_enquiries set full_name = full_name returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|website_enquiries|DELETE
with d as (delete from public.website_enquiries returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|work_overrides|SELECT
select 'R|' || (select count(*)||':'||coalesce(md5(string_agg(md5(x::text),',' order by md5(x::text))),'-') from public.work_overrides x);
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|work_overrides|UPDATE
with u as (update public.work_overrides set user_id = user_id returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from u;
rollback;
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null; \echo signed out|work_overrides|DELETE
with d as (delete from public.work_overrides returning md5((id)::text) h) select 'R|' || count(*)||':'||coalesce(md5(string_agg(h,',' order by h)),'-') from d;
rollback;
