-- Staff Portal · © cmeproject. All rights reserved.
--
-- Turns on the hourly timer for due date reminders, overdue alerts,
-- escalations and the managers' morning summary. Run once per company in
-- the Supabase SQL Editor, after changing the web address below.
--
-- It makes a new secret and shows it once. Copy it into Vercel as
-- CRON_SECRET (Settings → Environment Variables), then redeploy. Don't paste
-- it anywhere else. Running this again makes a new secret.

create extension if not exists pg_cron;
create extension if not exists pg_net;

do $$
declare
  -- ▼ This company's portal address (no slash at the end).
  v_site text := 'https://engagedcare-portal-beta.vercel.app';
  v_secret text := encode(extensions.gen_random_bytes(32), 'hex');
begin
  delete from vault.secrets where name in ('cron_secret', 'portal_url');
  perform vault.create_secret(v_secret, 'cron_secret');
  perform vault.create_secret(v_site, 'portal_url');

  if exists (select 1 from cron.job where jobname = 'due-alerts') then
    perform cron.unschedule('due-alerts');
  end if;
  -- Five past every hour.
  perform cron.schedule('due-alerts', '5 * * * *', $job$
    select net.http_post(
      url := (select decrypted_secret from vault.decrypted_secrets where name = 'portal_url') || '/cron/due-alerts',
      headers := jsonb_build_object(
        'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'cron_secret')),
      timeout_milliseconds := 60000)
  $job$);
end;
$$;

-- Copy this value into Vercel as CRON_SECRET.
select decrypted_secret as "CRON_SECRET (copy into Vercel)"
  from vault.decrypted_secrets where name = 'cron_secret';
