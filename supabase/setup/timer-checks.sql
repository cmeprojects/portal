-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: checks for the hourly timer (Dev testing). Run one section at a
-- time in the Supabase SQL Editor. Nothing here shows the secret.

-- 1. Is the timer scheduled? (expect one row: due-alerts, 5 * * * *, active)
select jobname, schedule, active from cron.job where jobname = 'due-alerts';

-- 2. Run it now instead of waiting for five past the hour.
select net.http_post(
  url := (select decrypted_secret from vault.decrypted_secrets where name = 'portal_url') || '/cron/due-alerts',
  headers := jsonb_build_object('Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'cron_secret')),
  timeout_milliseconds := 60000) as request_id;

-- 3. The answer from the portal (wait about 30 seconds after step 2).
--    Expect status 200 and {"ok":true,...}. 401 = CRON_SECRET in Vercel doesn't
--    match (or no redeploy yet).
select id, status_code, left(content, 400) as answer, created
  from net._http_response order by created desc limit 3;

-- 4. Last run as the portal saw it (same as System health).
select job, ran_at at time zone 'Australia/Sydney' as ran_sydney, ok, detail from public.system_heartbeat;

-- 5. Recent expiry and onboarding reminders (bell).
select n.created_at at time zone 'Australia/Sydney' as at_sydney, p.email, n.kind, n.title
  from public.notifications n join public.profiles p on p.id = n.user_id
 where n.kind in ('document_expiring', 'document_expired') or n.href like '/onboarding?finish=%'
 order by n.created_at desc limit 20;

-- 6. TEST DATA ONLY: make a test person's clearance 8 days old so the 7-day
--    onboarding reminder can be tested today. Change the email first.
-- update public.profiles set cleared_at = now() - interval '8 days'
--  where email = 'test-person@example.com' and cleared_at is not null;

-- 7. TEST DATA ONLY: put the clearance date back afterwards (or leave it).
-- update public.profiles set cleared_at = now()
--  where email = 'test-person@example.com';

-- 8. Turn the timer off (rollback). Then remove CRON_SECRET in Vercel if wanted.
-- select cron.unschedule('due-alerts');
-- delete from vault.secrets where name in ('cron_secret', 'portal_url');
