-- Staff Portal · © cmeproject. All rights reserved.
--
-- Which two-factor login methods people can use. The authenticator app is on;
-- text message (SMS) codes are off until an SMS provider is set up in
-- Supabase (it costs per message). Public so the two-factor page can read
-- them before the second step is done; they hold no secrets.

insert into public.app_settings (key, value, label, description, is_public) values
  ('security.mfa_app_enabled', 'true', 'Two-factor: authenticator app',
   'People can use an app like Google or Microsoft Authenticator. Free and the most secure.', true),
  ('security.mfa_sms_enabled', 'false', 'Two-factor: text message (SMS) code',
   'People can get a code by text message. Needs an SMS provider set up in Supabase first (it costs per message).', true)
on conflict (key) do nothing;
