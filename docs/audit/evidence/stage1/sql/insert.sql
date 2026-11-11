\echo INS|system admin|admin_delegations|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.admin_delegations (user_id,areas,granted_by,granted_at) select user_id,areas,granted_by,granted_at from jsonb_populate_record(null::public.admin_delegations, '{"user_id": "00000000-0000-4000-8000-836577700005", "granted_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|admin_delegations|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.admin_delegations (user_id,areas,granted_by,granted_at) select user_id,areas,granted_by,granted_at from jsonb_populate_record(null::public.admin_delegations, '{"user_id": "00000000-0000-4000-8000-798769833609", "granted_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|admin_delegations|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.admin_delegations (user_id,areas,granted_by,granted_at) select user_id,areas,granted_by,granted_at from jsonb_populate_record(null::public.admin_delegations, '{"user_id": "00000000-0000-4000-8000-881191826419", "granted_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|admin_delegations|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.admin_delegations (user_id,areas,granted_by,granted_at) select user_id,areas,granted_by,granted_at from jsonb_populate_record(null::public.admin_delegations, '{"user_id": "00000000-0000-4000-8000-132018816848", "granted_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|admin_delegations|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.admin_delegations (user_id,areas,granted_by,granted_at) select user_id,areas,granted_by,granted_at from jsonb_populate_record(null::public.admin_delegations, '{"user_id": "00000000-0000-4000-8000-254222991858", "granted_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|admin_delegations|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.admin_delegations (user_id,areas,granted_by,granted_at) select user_id,areas,granted_by,granted_at from jsonb_populate_record(null::public.admin_delegations, '{"user_id": "00000000-0000-4000-8000-216415125462", "granted_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|admin_delegations|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.admin_delegations (user_id,areas,granted_by,granted_at) select user_id,areas,granted_by,granted_at from jsonb_populate_record(null::public.admin_delegations, '{"user_id": "00000000-0000-4000-8000-337830023372", "granted_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|admin_delegations|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.admin_delegations (user_id,areas,granted_by,granted_at) select user_id,areas,granted_by,granted_at from jsonb_populate_record(null::public.admin_delegations, '{"user_id": "00000000-0000-4000-8000-485052537815", "granted_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|admin_delegations|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.admin_delegations (user_id,areas,granted_by,granted_at) select user_id,areas,granted_by,granted_at from jsonb_populate_record(null::public.admin_delegations, '{"user_id": "00000000-0000-4000-8000-604606093906", "granted_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|admin_delegations|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.admin_delegations (user_id,areas,granted_by,granted_at) select user_id,areas,granted_by,granted_at from jsonb_populate_record(null::public.admin_delegations, '{"user_id": "00000000-0000-4000-8000-642413960302", "granted_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|admin_delegations|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.admin_delegations (user_id,areas,granted_by,granted_at) select user_id,areas,granted_by,granted_at from jsonb_populate_record(null::public.admin_delegations, '{"user_id": "00000000-0000-4000-8000-458851458163", "granted_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|admin_delegations|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.admin_delegations (user_id,areas,granted_by,granted_at) select user_id,areas,granted_by,granted_at from jsonb_populate_record(null::public.admin_delegations, '{"user_id": "00000000-0000-4000-8000-577050227057", "granted_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|app_settings|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"key": "website.closed_title", "label": "Heading while the website is off", "value": "Our website is coming soon", "is_public": true, "updated_at": "2026-11-09T02:09:26.807114+00:00", "updated_by": null, "description": "Shown when Website and Assistant is switched off."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|app_settings|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"updated_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|app_settings|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|app_settings|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"key": "website.closed_title", "label": "Heading while the website is off", "value": "Our website is coming soon", "is_public": true, "updated_at": "2026-11-09T02:09:26.807114+00:00", "updated_by": null, "description": "Shown when Website and Assistant is switched off."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|app_settings|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"updated_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|app_settings|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|app_settings|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"key": "website.closed_title", "label": "Heading while the website is off", "value": "Our website is coming soon", "is_public": true, "updated_at": "2026-11-09T02:09:26.807114+00:00", "updated_by": null, "description": "Shown when Website and Assistant is switched off."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|app_settings|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"updated_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|app_settings|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|app_settings|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"key": "website.closed_title", "label": "Heading while the website is off", "value": "Our website is coming soon", "is_public": true, "updated_at": "2026-11-09T02:09:26.807114+00:00", "updated_by": null, "description": "Shown when Website and Assistant is switched off."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|app_settings|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"updated_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|app_settings|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|app_settings|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"key": "website.closed_title", "label": "Heading while the website is off", "value": "Our website is coming soon", "is_public": true, "updated_at": "2026-11-09T02:09:26.807114+00:00", "updated_by": null, "description": "Shown when Website and Assistant is switched off."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|app_settings|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"updated_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|app_settings|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|app_settings|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"key": "website.closed_title", "label": "Heading while the website is off", "value": "Our website is coming soon", "is_public": true, "updated_at": "2026-11-09T02:09:26.807114+00:00", "updated_by": null, "description": "Shown when Website and Assistant is switched off."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|app_settings|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|app_settings|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.app_settings (key,value,label,description,is_public,updated_at,updated_by) select key,value,label,description,is_public,updated_at,updated_by from jsonb_populate_record(null::public.app_settings, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|assistant_chats|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_chats (id,user_id,title,created_at,updated_at) select id,user_id,title,created_at,updated_at from jsonb_populate_record(null::public.assistant_chats, '{"id": "00000000-0000-4000-8000-007606793116", "user_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|assistant_chats|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_chats (id,user_id,title,created_at,updated_at) select id,user_id,title,created_at,updated_at from jsonb_populate_record(null::public.assistant_chats, '{"id": "00000000-0000-4000-8000-815275768071", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|assistant_chats|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_chats (id,user_id,title,created_at,updated_at) select id,user_id,title,created_at,updated_at from jsonb_populate_record(null::public.assistant_chats, '{"id": "00000000-0000-4000-8000-535045952559", "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|assistant_chats|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_chats (id,user_id,title,created_at,updated_at) select id,user_id,title,created_at,updated_at from jsonb_populate_record(null::public.assistant_chats, '{"id": "00000000-0000-4000-8000-715781037870", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|assistant_chats|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_chats (id,user_id,title,created_at,updated_at) select id,user_id,title,created_at,updated_at from jsonb_populate_record(null::public.assistant_chats, '{"id": "00000000-0000-4000-8000-544999155248", "user_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|assistant_chats|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_chats (id,user_id,title,created_at,updated_at) select id,user_id,title,created_at,updated_at from jsonb_populate_record(null::public.assistant_chats, '{"id": "00000000-0000-4000-8000-582807021644", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|assistant_chats|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_chats (id,user_id,title,created_at,updated_at) select id,user_id,title,created_at,updated_at from jsonb_populate_record(null::public.assistant_chats, '{"id": "00000000-0000-4000-8000-921592244394", "user_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|assistant_chats|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_chats (id,user_id,title,created_at,updated_at) select id,user_id,title,created_at,updated_at from jsonb_populate_record(null::public.assistant_chats, '{"id": "00000000-0000-4000-8000-901290316793", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|assistant_chats|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_chats (id,user_id,title,created_at,updated_at) select id,user_id,title,created_at,updated_at from jsonb_populate_record(null::public.assistant_chats, '{"id": "00000000-0000-4000-8000-403828241012", "user_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|assistant_chats|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_chats (id,user_id,title,created_at,updated_at) select id,user_id,title,created_at,updated_at from jsonb_populate_record(null::public.assistant_chats, '{"id": "00000000-0000-4000-8000-632073444208", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|assistant_chats|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.assistant_chats (id,user_id,title,created_at,updated_at) select id,user_id,title,created_at,updated_at from jsonb_populate_record(null::public.assistant_chats, '{"id": "00000000-0000-4000-8000-198620314475", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|assistant_chats|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.assistant_chats (id,user_id,title,created_at,updated_at) select id,user_id,title,created_at,updated_at from jsonb_populate_record(null::public.assistant_chats, '{"id": "00000000-0000-4000-8000-160812448079", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|assistant_documents|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_documents (id,title,audience,body,created_by,created_at,read_cost_usd) select id,title,audience,body,created_by,created_at,read_cost_usd from jsonb_populate_record(null::public.assistant_documents, '{"id": "00000000-0000-4000-8000-215165421001", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|assistant_documents|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_documents (id,title,audience,body,created_by,created_at,read_cost_usd) select id,title,audience,body,created_by,created_at,read_cost_usd from jsonb_populate_record(null::public.assistant_documents, '{"id": "00000000-0000-4000-8000-252973287397", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|assistant_documents|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_documents (id,title,audience,body,created_by,created_at,read_cost_usd) select id,title,audience,body,created_by,created_at,read_cost_usd from jsonb_populate_record(null::public.assistant_documents, '{"id": "00000000-0000-4000-8000-170551294587", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|assistant_documents|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_documents (id,title,audience,body,created_by,created_at,read_cost_usd) select id,title,audience,body,created_by,created_at,read_cost_usd from jsonb_populate_record(null::public.assistant_documents, '{"id": "00000000-0000-4000-8000-080275695842", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|assistant_documents|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_documents (id,title,audience,body,created_by,created_at,read_cost_usd) select id,title,audience,body,created_by,created_at,read_cost_usd from jsonb_populate_record(null::public.assistant_documents, '{"id": "00000000-0000-4000-8000-400287693554", "created_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|assistant_documents|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_documents (id,title,audience,body,created_by,created_at,read_cost_usd) select id,title,audience,body,created_by,created_at,read_cost_usd from jsonb_populate_record(null::public.assistant_documents, '{"id": "00000000-0000-4000-8000-362479827158", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|assistant_documents|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_documents (id,title,audience,body,created_by,created_at,read_cost_usd) select id,title,audience,body,created_by,created_at,read_cost_usd from jsonb_populate_record(null::public.assistant_documents, '{"id": "00000000-0000-4000-8000-669071270494", "created_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|assistant_documents|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_documents (id,title,audience,body,created_by,created_at,read_cost_usd) select id,title,audience,body,created_by,created_at,read_cost_usd from jsonb_populate_record(null::public.assistant_documents, '{"id": "00000000-0000-4000-8000-536913892795", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|assistant_documents|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_documents (id,title,audience,body,created_by,created_at,read_cost_usd) select id,title,audience,body,created_by,created_at,read_cost_usd from jsonb_populate_record(null::public.assistant_documents, '{"id": "00000000-0000-4000-8000-656349214912", "created_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|assistant_documents|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_documents (id,title,audience,body,created_by,created_at,read_cost_usd) select id,title,audience,body,created_by,created_at,read_cost_usd from jsonb_populate_record(null::public.assistant_documents, '{"id": "00000000-0000-4000-8000-694157081308", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|assistant_documents|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.assistant_documents (id,title,audience,body,created_by,created_at,read_cost_usd) select id,title,audience,body,created_by,created_at,read_cost_usd from jsonb_populate_record(null::public.assistant_documents, '{"id": "00000000-0000-4000-8000-552605293170", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|assistant_documents|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.assistant_documents (id,title,audience,body,created_by,created_at,read_cost_usd) select id,title,audience,body,created_by,created_at,read_cost_usd from jsonb_populate_record(null::public.assistant_documents, '{"id": "00000000-0000-4000-8000-698221697259", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|assistant_messages|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_messages (chat_id,question,answer,sources,answered,created_at) select chat_id,question,answer,sources,answered,created_at from jsonb_populate_record(null::public.assistant_messages, '{"chat_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|assistant_messages|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_messages (chat_id,question,answer,sources,answered,created_at) select chat_id,question,answer,sources,answered,created_at from jsonb_populate_record(null::public.assistant_messages, '{"chat_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|assistant_messages|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_messages (chat_id,question,answer,sources,answered,created_at) select chat_id,question,answer,sources,answered,created_at from jsonb_populate_record(null::public.assistant_messages, '{"chat_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|assistant_messages|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_messages (chat_id,question,answer,sources,answered,created_at) select chat_id,question,answer,sources,answered,created_at from jsonb_populate_record(null::public.assistant_messages, '{"chat_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|assistant_messages|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_messages (chat_id,question,answer,sources,answered,created_at) select chat_id,question,answer,sources,answered,created_at from jsonb_populate_record(null::public.assistant_messages, '{"chat_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|assistant_messages|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_messages (chat_id,question,answer,sources,answered,created_at) select chat_id,question,answer,sources,answered,created_at from jsonb_populate_record(null::public.assistant_messages, '{"chat_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|assistant_messages|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_messages (chat_id,question,answer,sources,answered,created_at) select chat_id,question,answer,sources,answered,created_at from jsonb_populate_record(null::public.assistant_messages, '{"chat_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|assistant_messages|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_messages (chat_id,question,answer,sources,answered,created_at) select chat_id,question,answer,sources,answered,created_at from jsonb_populate_record(null::public.assistant_messages, '{"chat_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|assistant_messages|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_messages (chat_id,question,answer,sources,answered,created_at) select chat_id,question,answer,sources,answered,created_at from jsonb_populate_record(null::public.assistant_messages, '{"chat_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|assistant_messages|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_messages (chat_id,question,answer,sources,answered,created_at) select chat_id,question,answer,sources,answered,created_at from jsonb_populate_record(null::public.assistant_messages, '{"chat_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|assistant_messages|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.assistant_messages (chat_id,question,answer,sources,answered,created_at) select chat_id,question,answer,sources,answered,created_at from jsonb_populate_record(null::public.assistant_messages, '{"chat_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|assistant_messages|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.assistant_messages (chat_id,question,answer,sources,answered,created_at) select chat_id,question,answer,sources,answered,created_at from jsonb_populate_record(null::public.assistant_messages, '{"chat_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|assistant_questions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_questions (question,audience,answered,sources,cost_usd,created_at) select question,audience,answered,sources,cost_usd,created_at from jsonb_populate_record(null::public.assistant_questions, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|assistant_questions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_questions (question,audience,answered,sources,cost_usd,created_at) select question,audience,answered,sources,cost_usd,created_at from jsonb_populate_record(null::public.assistant_questions, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|assistant_questions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_questions (question,audience,answered,sources,cost_usd,created_at) select question,audience,answered,sources,cost_usd,created_at from jsonb_populate_record(null::public.assistant_questions, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|assistant_questions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_questions (question,audience,answered,sources,cost_usd,created_at) select question,audience,answered,sources,cost_usd,created_at from jsonb_populate_record(null::public.assistant_questions, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|assistant_questions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_questions (question,audience,answered,sources,cost_usd,created_at) select question,audience,answered,sources,cost_usd,created_at from jsonb_populate_record(null::public.assistant_questions, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|assistant_questions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_questions (question,audience,answered,sources,cost_usd,created_at) select question,audience,answered,sources,cost_usd,created_at from jsonb_populate_record(null::public.assistant_questions, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|assistant_questions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_questions (question,audience,answered,sources,cost_usd,created_at) select question,audience,answered,sources,cost_usd,created_at from jsonb_populate_record(null::public.assistant_questions, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|assistant_questions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_questions (question,audience,answered,sources,cost_usd,created_at) select question,audience,answered,sources,cost_usd,created_at from jsonb_populate_record(null::public.assistant_questions, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|assistant_questions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_questions (question,audience,answered,sources,cost_usd,created_at) select question,audience,answered,sources,cost_usd,created_at from jsonb_populate_record(null::public.assistant_questions, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|assistant_questions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_questions (question,audience,answered,sources,cost_usd,created_at) select question,audience,answered,sources,cost_usd,created_at from jsonb_populate_record(null::public.assistant_questions, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|assistant_questions|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.assistant_questions (question,audience,answered,sources,cost_usd,created_at) select question,audience,answered,sources,cost_usd,created_at from jsonb_populate_record(null::public.assistant_questions, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|assistant_questions|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.assistant_questions (question,audience,answered,sources,cost_usd,created_at) select question,audience,answered,sources,cost_usd,created_at from jsonb_populate_record(null::public.assistant_questions, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|assistant_settings|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{"id": true, "intro": "Ask anything about our services, the NDIS or our policies. Answers come from our own documents, with the source shown.", "model": "haiku", "phone": "", "heading": "How can we help today?", "fallback": "I can''t find that in our documents. Please call us or leave your details and we''ll call you.", "credit_aud": 0.0, "disclaimer": "General information only, not official NDIS advice.", "offer_call": true, "updated_at": "2026-11-09T02:09:26.76501+00:00", "scope_staff": "documents", "suggestions": ["What services do you offer?", "What''s your cancellation policy?", "How do I start with you?", "How does NDIS funding work?"], "credit_since": null, "hourly_limit": 60, "scope_public": "documents", "show_credits": true, "log_questions": true, "trusted_sites": ["ndis.gov.au", "ndiscommission.gov.au", "legislation.gov.au"], "scope_managers": "documents", "monthly_limit_aud": 50.0}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|assistant_settings|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|assistant_settings|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|assistant_settings|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{"id": true, "intro": "Ask anything about our services, the NDIS or our policies. Answers come from our own documents, with the source shown.", "model": "haiku", "phone": "", "heading": "How can we help today?", "fallback": "I can''t find that in our documents. Please call us or leave your details and we''ll call you.", "credit_aud": 0.0, "disclaimer": "General information only, not official NDIS advice.", "offer_call": true, "updated_at": "2026-11-09T02:09:26.76501+00:00", "scope_staff": "documents", "suggestions": ["What services do you offer?", "What''s your cancellation policy?", "How do I start with you?", "How does NDIS funding work?"], "credit_since": null, "hourly_limit": 60, "scope_public": "documents", "show_credits": true, "log_questions": true, "trusted_sites": ["ndis.gov.au", "ndiscommission.gov.au", "legislation.gov.au"], "scope_managers": "documents", "monthly_limit_aud": 50.0}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|assistant_settings|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|assistant_settings|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|assistant_settings|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{"id": true, "intro": "Ask anything about our services, the NDIS or our policies. Answers come from our own documents, with the source shown.", "model": "haiku", "phone": "", "heading": "How can we help today?", "fallback": "I can''t find that in our documents. Please call us or leave your details and we''ll call you.", "credit_aud": 0.0, "disclaimer": "General information only, not official NDIS advice.", "offer_call": true, "updated_at": "2026-11-09T02:09:26.76501+00:00", "scope_staff": "documents", "suggestions": ["What services do you offer?", "What''s your cancellation policy?", "How do I start with you?", "How does NDIS funding work?"], "credit_since": null, "hourly_limit": 60, "scope_public": "documents", "show_credits": true, "log_questions": true, "trusted_sites": ["ndis.gov.au", "ndiscommission.gov.au", "legislation.gov.au"], "scope_managers": "documents", "monthly_limit_aud": 50.0}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|assistant_settings|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|assistant_settings|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|assistant_settings|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{"id": true, "intro": "Ask anything about our services, the NDIS or our policies. Answers come from our own documents, with the source shown.", "model": "haiku", "phone": "", "heading": "How can we help today?", "fallback": "I can''t find that in our documents. Please call us or leave your details and we''ll call you.", "credit_aud": 0.0, "disclaimer": "General information only, not official NDIS advice.", "offer_call": true, "updated_at": "2026-11-09T02:09:26.76501+00:00", "scope_staff": "documents", "suggestions": ["What services do you offer?", "What''s your cancellation policy?", "How do I start with you?", "How does NDIS funding work?"], "credit_since": null, "hourly_limit": 60, "scope_public": "documents", "show_credits": true, "log_questions": true, "trusted_sites": ["ndis.gov.au", "ndiscommission.gov.au", "legislation.gov.au"], "scope_managers": "documents", "monthly_limit_aud": 50.0}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|assistant_settings|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|assistant_settings|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|assistant_settings|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{"id": true, "intro": "Ask anything about our services, the NDIS or our policies. Answers come from our own documents, with the source shown.", "model": "haiku", "phone": "", "heading": "How can we help today?", "fallback": "I can''t find that in our documents. Please call us or leave your details and we''ll call you.", "credit_aud": 0.0, "disclaimer": "General information only, not official NDIS advice.", "offer_call": true, "updated_at": "2026-11-09T02:09:26.76501+00:00", "scope_staff": "documents", "suggestions": ["What services do you offer?", "What''s your cancellation policy?", "How do I start with you?", "How does NDIS funding work?"], "credit_since": null, "hourly_limit": 60, "scope_public": "documents", "show_credits": true, "log_questions": true, "trusted_sites": ["ndis.gov.au", "ndiscommission.gov.au", "legislation.gov.au"], "scope_managers": "documents", "monthly_limit_aud": 50.0}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|assistant_settings|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|assistant_settings|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|assistant_settings|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{"id": true, "intro": "Ask anything about our services, the NDIS or our policies. Answers come from our own documents, with the source shown.", "model": "haiku", "phone": "", "heading": "How can we help today?", "fallback": "I can''t find that in our documents. Please call us or leave your details and we''ll call you.", "credit_aud": 0.0, "disclaimer": "General information only, not official NDIS advice.", "offer_call": true, "updated_at": "2026-11-09T02:09:26.76501+00:00", "scope_staff": "documents", "suggestions": ["What services do you offer?", "What''s your cancellation policy?", "How do I start with you?", "How does NDIS funding work?"], "credit_since": null, "hourly_limit": 60, "scope_public": "documents", "show_credits": true, "log_questions": true, "trusted_sites": ["ndis.gov.au", "ndiscommission.gov.au", "legislation.gov.au"], "scope_managers": "documents", "monthly_limit_aud": 50.0}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|assistant_settings|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|assistant_settings|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.assistant_settings (id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since) select id,model,heading,intro,disclaimer,fallback,phone,offer_call,log_questions,monthly_limit_aud,hourly_limit,updated_at,suggestions,show_credits,scope_public,scope_staff,scope_managers,trusted_sites,credit_aud,credit_since from jsonb_populate_record(null::public.assistant_settings, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|audit_log|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"id": 1240, "action": "invited", "entity": "invitation", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "details": {"role": "support_worker"}, "actor_id": null, "entity_id": "perf274@example.test", "created_at": "2026-11-09T21:14:30.544857+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|audit_log|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"org_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "actor_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|audit_log|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"org_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|audit_log|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"id": 1240, "action": "invited", "entity": "invitation", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "details": {"role": "support_worker"}, "actor_id": null, "entity_id": "perf274@example.test", "created_at": "2026-11-09T21:14:30.544857+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|audit_log|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"id": 47, "action": "unstarted_person_deleted", "entity": "profile", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "details": {"name": "Starter One 1794201333706", "email": "starterOne1794201333706@example.com"}, "actor_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "entity_id": "4ed69273-b96a-4198-b08d-7badc69ff5c7", "created_at": "2026-11-09T05:15:36.083349+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|audit_log|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "actor_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|audit_log|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"org_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|audit_log|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"id": 1240, "action": "invited", "entity": "invitation", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "details": {"role": "support_worker"}, "actor_id": null, "entity_id": "perf274@example.test", "created_at": "2026-11-09T21:14:30.544857+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|audit_log|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"id": 61, "action": "upload_replacement_requested", "entity": "compliance_record", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "details": {"item": "NDIS Worker Screening Check", "note": "Blurry photo, please upload a clearer one"}, "actor_id": "1028b402-8a12-467c-adcf-2f1269268df7", "entity_id": "3", "created_at": "2026-11-09T10:26:15.358606+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|audit_log|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"org_id": "1028b402-8a12-467c-adcf-2f1269268df7", "actor_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|audit_log|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"org_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|audit_log|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"id": 1240, "action": "invited", "entity": "invitation", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "details": {"role": "support_worker"}, "actor_id": null, "entity_id": "perf274@example.test", "created_at": "2026-11-09T21:14:30.544857+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|audit_log|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"id": 35, "action": "profile_updated", "entity": "profile", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "details": {}, "actor_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "entity_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "created_at": "2026-11-09T03:38:02.563181+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|audit_log|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "actor_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|audit_log|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"org_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|audit_log|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"id": 1240, "action": "invited", "entity": "invitation", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "details": {"role": "support_worker"}, "actor_id": null, "entity_id": "perf274@example.test", "created_at": "2026-11-09T21:14:30.544857+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|audit_log|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"org_id": "b0104664-71b0-4297-9d29-942575610100", "actor_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|audit_log|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"org_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|audit_log|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"id": 1240, "action": "invited", "entity": "invitation", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "details": {"role": "support_worker"}, "actor_id": null, "entity_id": "perf274@example.test", "created_at": "2026-11-09T21:14:30.544857+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|audit_log|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"org_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|audit_log|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.audit_log (org_id,actor_id,action,entity,entity_id,details,created_at) select org_id,actor_id,action,entity,entity_id,details,created_at from jsonb_populate_record(null::public.audit_log, '{"org_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|car_clients|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_clients (id,org_id,name,reference,active,created_by,created_at) select id,org_id,name,reference,active,created_by,created_at from jsonb_populate_record(null::public.car_clients, '{"id": "00000000-0000-4000-8000-278190017568", "org_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|car_clients|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_clients (id,org_id,name,reference,active,created_by,created_at) select id,org_id,name,reference,active,created_by,created_at from jsonb_populate_record(null::public.car_clients, '{"id": "00000000-0000-4000-8000-240382151172", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|car_clients|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_clients (id,org_id,name,reference,active,created_by,created_at) select id,org_id,name,reference,active,created_by,created_at from jsonb_populate_record(null::public.car_clients, '{"id": "00000000-0000-4000-8000-611439000807", "org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|car_clients|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_clients (id,org_id,name,reference,active,created_by,created_at) select id,org_id,name,reference,active,created_by,created_at from jsonb_populate_record(null::public.car_clients, '{"id": "00000000-0000-4000-8000-573631134411", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|car_clients|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_clients (id,org_id,name,reference,active,created_by,created_at) select id,org_id,name,reference,active,created_by,created_at from jsonb_populate_record(null::public.car_clients, '{"id": "00000000-0000-4000-8000-007151828285", "org_id": "1028b402-8a12-467c-adcf-2f1269268df7", "created_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|car_clients|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_clients (id,org_id,name,reference,active,created_by,created_at) select id,org_id,name,reference,active,created_by,created_at from jsonb_populate_record(null::public.car_clients, '{"id": "00000000-0000-4000-8000-028749856935", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|car_clients|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_clients (id,org_id,name,reference,active,created_by,created_at) select id,org_id,name,reference,active,created_by,created_at from jsonb_populate_record(null::public.car_clients, '{"id": "00000000-0000-4000-8000-923544796771", "org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "created_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|car_clients|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_clients (id,org_id,name,reference,active,created_by,created_at) select id,org_id,name,reference,active,created_by,created_at from jsonb_populate_record(null::public.car_clients, '{"id": "00000000-0000-4000-8000-327282193658", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|car_clients|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_clients (id,org_id,name,reference,active,created_by,created_at) select id,org_id,name,reference,active,created_by,created_at from jsonb_populate_record(null::public.car_clients, '{"id": "00000000-0000-4000-8000-990079185135", "org_id": "b0104664-71b0-4297-9d29-942575610100", "created_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|car_clients|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_clients (id,org_id,name,reference,active,created_by,created_at) select id,org_id,name,reference,active,created_by,created_at from jsonb_populate_record(null::public.car_clients, '{"id": "00000000-0000-4000-8000-027887051531", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|car_clients|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.car_clients (id,org_id,name,reference,active,created_by,created_at) select id,org_id,name,reference,active,created_by,created_at from jsonb_populate_record(null::public.car_clients, '{"id": "00000000-0000-4000-8000-646516726690", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|car_clients|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.car_clients (id,org_id,name,reference,active,created_by,created_at) select id,org_id,name,reference,active,created_by,created_at from jsonb_populate_record(null::public.car_clients, '{"id": "00000000-0000-4000-8000-684324593086", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|car_purposes|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-110569491108", "name": "Office errand", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "created_at": "2026-11-09T02:09:25.594301+00:00", "sort_order": 50}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|car_purposes|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-461405242040", "org_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|car_purposes|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-361477319147", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|car_purposes|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-962497053295", "name": "Office errand", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "created_at": "2026-11-09T02:09:25.594301+00:00", "sort_order": 50}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|car_purposes|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-081247503635", "org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|car_purposes|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-169579486794", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|car_purposes|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-878100744681", "name": "Office errand", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "created_at": "2026-11-09T02:09:25.594301+00:00", "sort_order": 50}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|car_purposes|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-091200706324", "org_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|car_purposes|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-129008572720", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|car_purposes|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-196584039830", "name": "Office errand", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "created_at": "2026-11-09T02:09:25.594301+00:00", "sort_order": 50}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|car_purposes|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-375390693318", "org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|car_purposes|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-337582826922", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|car_purposes|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-336779721171", "name": "Office errand", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "created_at": "2026-11-09T02:09:25.594301+00:00", "sort_order": 50}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|car_purposes|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-567045423960", "org_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|car_purposes|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-085871893132", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|car_purposes|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-865518725042", "name": "Office errand", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "created_at": "2026-11-09T02:09:25.594301+00:00", "sort_order": 50}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|car_purposes|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-652418763399", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|car_purposes|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.car_purposes (id,org_id,name,active,sort_order,created_at) select id,org_id,name,active,sort_order,created_at from jsonb_populate_record(null::public.car_purposes, '{"id": "00000000-0000-4000-8000-614610897003", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|car_trips|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_trips (org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to) select org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to from jsonb_populate_record(null::public.car_trips, '{"org_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "car_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "driver_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "client_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "returned_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|car_trips|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_trips (org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to) select org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to from jsonb_populate_record(null::public.car_trips, '{"org_id": "11111111-1111-4111-8111-111111111111", "car_id": "11111111-1111-4111-8111-111111111111", "driver_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "returned_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|car_trips|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_trips (org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to) select org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to from jsonb_populate_record(null::public.car_trips, '{"org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "car_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "driver_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "client_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "returned_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|car_trips|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_trips (org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to) select org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to from jsonb_populate_record(null::public.car_trips, '{"org_id": "11111111-1111-4111-8111-111111111111", "car_id": "11111111-1111-4111-8111-111111111111", "driver_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "returned_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|car_trips|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_trips (org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to) select org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to from jsonb_populate_record(null::public.car_trips, '{"org_id": "1028b402-8a12-467c-adcf-2f1269268df7", "car_id": "1028b402-8a12-467c-adcf-2f1269268df7", "driver_id": "1028b402-8a12-467c-adcf-2f1269268df7", "client_id": "1028b402-8a12-467c-adcf-2f1269268df7", "returned_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|car_trips|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_trips (org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to) select org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to from jsonb_populate_record(null::public.car_trips, '{"org_id": "11111111-1111-4111-8111-111111111111", "car_id": "11111111-1111-4111-8111-111111111111", "driver_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "returned_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|car_trips|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_trips (org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to) select org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to from jsonb_populate_record(null::public.car_trips, '{"org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "car_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "driver_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "client_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "returned_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|car_trips|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_trips (org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to) select org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to from jsonb_populate_record(null::public.car_trips, '{"org_id": "11111111-1111-4111-8111-111111111111", "car_id": "11111111-1111-4111-8111-111111111111", "driver_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "returned_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|car_trips|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_trips (org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to) select org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to from jsonb_populate_record(null::public.car_trips, '{"org_id": "b0104664-71b0-4297-9d29-942575610100", "car_id": "b0104664-71b0-4297-9d29-942575610100", "driver_id": "b0104664-71b0-4297-9d29-942575610100", "client_id": "b0104664-71b0-4297-9d29-942575610100", "returned_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|car_trips|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.car_trips (org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to) select org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to from jsonb_populate_record(null::public.car_trips, '{"org_id": "11111111-1111-4111-8111-111111111111", "car_id": "11111111-1111-4111-8111-111111111111", "driver_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "returned_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|car_trips|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.car_trips (org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to) select org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to from jsonb_populate_record(null::public.car_trips, '{"org_id": "11111111-1111-4111-8111-111111111111", "car_id": "11111111-1111-4111-8111-111111111111", "driver_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "returned_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|car_trips|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.car_trips (org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to) select org_id,car_id,driver_id,purpose,details,client_id,client_name,started_at,start_odo,gap_km,returned_at,end_odo,returned_by,return_note,odo_photo_path,reminded_at,managers_told_at,corrected_at,went_to from jsonb_populate_record(null::public.car_trips, '{"org_id": "11111111-1111-4111-8111-111111111111", "car_id": "11111111-1111-4111-8111-111111111111", "driver_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "returned_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|cars|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.cars (id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at) select id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at from jsonb_populate_record(null::public.cars, '{"id": "00000000-0000-4000-8000-450653908549", "org_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|cars|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.cars (id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at) select id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at from jsonb_populate_record(null::public.cars, '{"id": "00000000-0000-4000-8000-488461774945", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|cars|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.cars (id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at) select id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at from jsonb_populate_record(null::public.cars, '{"id": "00000000-0000-4000-8000-265579442818", "org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|cars|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.cars (id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at) select id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at from jsonb_populate_record(null::public.cars, '{"id": "00000000-0000-4000-8000-227771576422", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|cars|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.cars (id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at) select id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at from jsonb_populate_record(null::public.cars, '{"id": "00000000-0000-4000-8000-164799206006", "org_id": "1028b402-8a12-467c-adcf-2f1269268df7", "created_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|cars|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.cars (id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at) select id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at from jsonb_populate_record(null::public.cars, '{"id": "00000000-0000-4000-8000-658083355181", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|cars|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.cars (id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at) select id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at from jsonb_populate_record(null::public.cars, '{"id": "00000000-0000-4000-8000-536668457271", "org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "created_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|cars|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.cars (id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at) select id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at from jsonb_populate_record(null::public.cars, '{"id": "00000000-0000-4000-8000-574476323667", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|cars|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.cars (id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at) select id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at from jsonb_populate_record(null::public.cars, '{"id": "00000000-0000-4000-8000-891837702460", "org_id": "b0104664-71b0-4297-9d29-942575610100", "created_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|cars|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.cars (id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at) select id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at from jsonb_populate_record(null::public.cars, '{"id": "00000000-0000-4000-8000-929645568856", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|cars|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.cars (id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at) select id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at from jsonb_populate_record(null::public.cars, '{"id": "00000000-0000-4000-8000-375360652807", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|cars|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.cars (id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at) select id,org_id,name,rego,car_type,colour,odometer,rego_expires,service_due_date,service_due_km,photo_path,notes,active,rego_alerted,service_alerted,created_by,created_at,updated_at,changed_at from jsonb_populate_record(null::public.cars, '{"id": "00000000-0000-4000-8000-660541032413", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|client_teams|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.client_teams (client_id,team_id) select client_id,team_id from jsonb_populate_record(null::public.client_teams, '{"client_id": "00000000-0000-4000-8000-572084274517", "team_id": "00000000-0000-4000-8000-572084274517"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|client_teams|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.client_teams (client_id,team_id) select client_id,team_id from jsonb_populate_record(null::public.client_teams, '{"client_id": "00000000-0000-4000-8000-534276408121", "team_id": "00000000-0000-4000-8000-534276408121"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|client_teams|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.client_teams (client_id,team_id) select client_id,team_id from jsonb_populate_record(null::public.client_teams, '{"client_id": "00000000-0000-4000-8000-785391925732", "team_id": "00000000-0000-4000-8000-785391925732"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|client_teams|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.client_teams (client_id,team_id) select client_id,team_id from jsonb_populate_record(null::public.client_teams, '{"client_id": "00000000-0000-4000-8000-823199792128", "team_id": "00000000-0000-4000-8000-823199792128"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|client_teams|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.client_teams (client_id,team_id) select client_id,team_id from jsonb_populate_record(null::public.client_teams, '{"client_id": "00000000-0000-4000-8000-886172162544", "team_id": "00000000-0000-4000-8000-886172162544"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|client_teams|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.client_teams (client_id,team_id) select client_id,team_id from jsonb_populate_record(null::public.client_teams, '{"client_id": "00000000-0000-4000-8000-364654827885", "team_id": "00000000-0000-4000-8000-364654827885"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|client_teams|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.client_teams (client_id,team_id) select client_id,team_id from jsonb_populate_record(null::public.client_teams, '{"client_id": "00000000-0000-4000-8000-204655457693", "team_id": "00000000-0000-4000-8000-204655457693"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|client_teams|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.client_teams (client_id,team_id) select client_id,team_id from jsonb_populate_record(null::public.client_teams, '{"client_id": "00000000-0000-4000-8000-242463324089", "team_id": "00000000-0000-4000-8000-242463324089"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|client_teams|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.client_teams (client_id,team_id) select client_id,team_id from jsonb_populate_record(null::public.client_teams, '{"client_id": "00000000-0000-4000-8000-130900480606", "team_id": "00000000-0000-4000-8000-130900480606"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|client_teams|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.client_teams (client_id,team_id) select client_id,team_id from jsonb_populate_record(null::public.client_teams, '{"client_id": "00000000-0000-4000-8000-381727471035", "team_id": "00000000-0000-4000-8000-381727471035"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|client_teams|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.client_teams (client_id,team_id) select client_id,team_id from jsonb_populate_record(null::public.client_teams, '{"client_id": "00000000-0000-4000-8000-659639484477", "team_id": "00000000-0000-4000-8000-659639484477"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|client_teams|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.client_teams (client_id,team_id) select client_id,team_id from jsonb_populate_record(null::public.client_teams, '{"client_id": "00000000-0000-4000-8000-910466474906", "team_id": "00000000-0000-4000-8000-910466474906"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|compliance_items|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-320948775234", "body": "", "kind": "upload", "title": "Profile photo", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "form_id": null, "version": 1, "category": "", "link_url": "", "file_name": null, "file_path": null, "created_at": "2026-11-09T02:09:27.305489+00:00", "created_by": null, "sets_photo": true, "sort_order": 5, "updated_at": "2026-11-09T02:09:27.305489+00:00", "before_work": false, "certificate": "optional", "description": "A clear, recent photo of your face, like a passport photo. It''s shown next to your name in the portal, only to signed-in staff.", "needs_expiry": false, "needs_number": false, "applies_roles": [], "applies_teams": [], "applies_titles": [], "needs_issue_date": false}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|compliance_items|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-848935631251", "org_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a", "form_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|compliance_items|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-811127764855", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|compliance_items|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-012300208005", "body": "", "kind": "upload", "title": "Profile photo", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "form_id": null, "version": 1, "category": "", "link_url": "", "file_name": null, "file_path": null, "created_at": "2026-11-09T02:09:27.305489+00:00", "created_by": null, "sets_photo": true, "sort_order": 5, "updated_at": "2026-11-09T02:09:27.305489+00:00", "before_work": false, "certificate": "optional", "description": "A clear, recent photo of your face, like a passport photo. It''s shown next to your name in the portal, only to signed-in staff.", "needs_expiry": false, "needs_number": false, "applies_roles": [], "applies_teams": [], "applies_titles": [], "needs_issue_date": false}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|compliance_items|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-893549757665", "org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "form_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|compliance_items|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-144376748094", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|compliance_items|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-294504339321", "body": "", "kind": "upload", "title": "Profile photo", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "form_id": null, "version": 1, "category": "", "link_url": "", "file_name": null, "file_path": null, "created_at": "2026-11-09T02:09:27.305489+00:00", "created_by": null, "sets_photo": true, "sort_order": 5, "updated_at": "2026-11-09T02:09:27.305489+00:00", "before_work": false, "certificate": "optional", "description": "A clear, recent photo of your face, like a passport photo. It''s shown next to your name in the portal, only to signed-in staff.", "needs_expiry": false, "needs_number": false, "applies_roles": [], "applies_teams": [], "applies_titles": [], "needs_issue_date": false}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|compliance_items|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-081404377678", "org_id": "1028b402-8a12-467c-adcf-2f1269268df7", "created_by": "1028b402-8a12-467c-adcf-2f1269268df7", "form_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|compliance_items|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-043596511282", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|compliance_items|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-221786778530", "body": "", "kind": "upload", "title": "Profile photo", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "form_id": null, "version": 1, "category": "", "link_url": "", "file_name": null, "file_path": null, "created_at": "2026-11-09T02:09:27.305489+00:00", "created_by": null, "sets_photo": true, "sort_order": 5, "updated_at": "2026-11-09T02:09:27.305489+00:00", "before_work": false, "certificate": "optional", "description": "A clear, recent photo of your face, like a passport photo. It''s shown next to your name in the portal, only to signed-in staff.", "needs_expiry": false, "needs_number": false, "applies_roles": [], "applies_teams": [], "applies_titles": [], "needs_issue_date": false}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|compliance_items|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-723521596998", "org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "created_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "form_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|compliance_items|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-472694606569", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|compliance_items|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-762132569145", "body": "", "kind": "upload", "title": "Profile photo", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "form_id": null, "version": 1, "category": "", "link_url": "", "file_name": null, "file_path": null, "created_at": "2026-11-09T02:09:27.305489+00:00", "created_by": null, "sets_photo": true, "sort_order": 5, "updated_at": "2026-11-09T02:09:27.305489+00:00", "before_work": false, "certificate": "optional", "description": "A clear, recent photo of your face, like a passport photo. It''s shown next to your name in the portal, only to signed-in staff.", "needs_expiry": false, "needs_number": false, "applies_roles": [], "applies_teams": [], "applies_titles": [], "needs_issue_date": false}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|compliance_items|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-592248162660", "org_id": "b0104664-71b0-4297-9d29-942575610100", "created_by": "b0104664-71b0-4297-9d29-942575610100", "form_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|compliance_items|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-630056029056", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|compliance_items|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-840315986342", "body": "", "kind": "upload", "title": "Profile photo", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "form_id": null, "version": 1, "category": "", "link_url": "", "file_name": null, "file_path": null, "created_at": "2026-11-09T02:09:27.305489+00:00", "created_by": null, "sets_photo": true, "sort_order": 5, "updated_at": "2026-11-09T02:09:27.305489+00:00", "before_work": false, "certificate": "optional", "description": "A clear, recent photo of your face, like a passport photo. It''s shown next to your name in the portal, only to signed-in staff.", "needs_expiry": false, "needs_number": false, "applies_roles": [], "applies_teams": [], "applies_titles": [], "needs_issue_date": false}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|compliance_items|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-446493526917", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|compliance_items|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.compliance_items (id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate) select id,org_id,kind,title,description,body,link_url,file_path,file_name,version,needs_expiry,active,applies_roles,applies_teams,sort_order,created_by,created_at,updated_at,form_id,sets_photo,category,before_work,applies_titles,needs_issue_date,needs_number,certificate from jsonb_populate_record(null::public.compliance_items, '{"id": "00000000-0000-4000-8000-484301393313", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|compliance_opens|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-698740646557", "user_id": "00000000-0000-4000-8000-698740646557", "version": 1, "opened_at": "2026-11-09T21:09:42.800467+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|compliance_opens|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-485640684914", "user_id": "00000000-0000-4000-8000-485640684914"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|compliance_opens|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-447832818518", "user_id": "00000000-0000-4000-8000-447832818518"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|compliance_opens|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-843912099118", "user_id": "00000000-0000-4000-8000-843912099118", "version": 1, "opened_at": "2026-11-09T21:09:42.800467+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|compliance_opens|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-057012060761", "user_id": "00000000-0000-4000-8000-057012060761"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|compliance_opens|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-094819927157", "user_id": "00000000-0000-4000-8000-094819927157"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|compliance_opens|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-470880933679", "user_id": "00000000-0000-4000-8000-470880933679", "version": 1, "opened_at": "2026-11-09T21:09:42.800467+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|compliance_opens|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-972615752147", "user_id": "00000000-0000-4000-8000-972615752147"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|compliance_opens|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-721788761718", "user_id": "00000000-0000-4000-8000-721788761718"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|compliance_opens|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-612726097835", "user_id": "00000000-0000-4000-8000-612726097835", "version": 1, "opened_at": "2026-11-09T21:09:42.800467+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|compliance_opens|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-399626136192", "user_id": "00000000-0000-4000-8000-399626136192"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|compliance_opens|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-361818269796", "user_id": "00000000-0000-4000-8000-361818269796"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|compliance_opens|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-546191709471", "user_id": "00000000-0000-4000-8000-546191709471", "version": 1, "opened_at": "2026-11-09T21:09:42.800467+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|compliance_opens|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-955543108997", "user_id": "00000000-0000-4000-8000-955543108997"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|compliance_opens|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-993350975393", "user_id": "00000000-0000-4000-8000-993350975393"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|compliance_opens|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-225966097701", "user_id": "00000000-0000-4000-8000-225966097701", "version": 1, "opened_at": "2026-11-09T21:09:42.800467+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|compliance_opens|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-439066059344", "user_id": "00000000-0000-4000-8000-439066059344"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|compliance_opens|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.compliance_opens (item_id,user_id,version,opened_at) select item_id,user_id,version,opened_at from jsonb_populate_record(null::public.compliance_opens, '{"item_id": "00000000-0000-4000-8000-476873925740", "user_id": "00000000-0000-4000-8000-476873925740"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|compliance_records|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"id": 32, "status": "rejected", "item_id": "b803beda-f444-4ae3-ab63-b3c4446c0fab", "user_id": "eea9da48-a491-4526-ad8b-4861c4a2a8d0", "version": 1, "provider": "", "file_name": "x.pdf", "file_path": "eea9da48-a491-4526-ad8b-4861c4a2a8d0/x.pdf", "issued_on": null, "created_at": "2026-11-04T21:14:30.544857+00:00", "doc_number": "", "expires_on": null, "review_note": "", "reviewed_at": null, "reviewed_by": null, "signed_from": "", "signed_name": "", "uploaded_by": null, "completed_on": null, "content_hash": "", "signature_path": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|compliance_records|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"item_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "user_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "reviewed_by": "0a29bd38-850f-4222-b674-d080fe462c2a", "uploaded_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|compliance_records|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"item_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "reviewed_by": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|compliance_records|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"id": 32, "status": "rejected", "item_id": "b803beda-f444-4ae3-ab63-b3c4446c0fab", "user_id": "eea9da48-a491-4526-ad8b-4861c4a2a8d0", "version": 1, "provider": "", "file_name": "x.pdf", "file_path": "eea9da48-a491-4526-ad8b-4861c4a2a8d0/x.pdf", "issued_on": null, "created_at": "2026-11-04T21:14:30.544857+00:00", "doc_number": "", "expires_on": null, "review_note": "", "reviewed_at": null, "reviewed_by": null, "signed_from": "", "signed_name": "", "uploaded_by": null, "completed_on": null, "content_hash": "", "signature_path": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|compliance_records|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"item_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "reviewed_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "uploaded_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|compliance_records|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"item_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "reviewed_by": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|compliance_records|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"id": 32, "status": "rejected", "item_id": "b803beda-f444-4ae3-ab63-b3c4446c0fab", "user_id": "eea9da48-a491-4526-ad8b-4861c4a2a8d0", "version": 1, "provider": "", "file_name": "x.pdf", "file_path": "eea9da48-a491-4526-ad8b-4861c4a2a8d0/x.pdf", "issued_on": null, "created_at": "2026-11-04T21:14:30.544857+00:00", "doc_number": "", "expires_on": null, "review_note": "", "reviewed_at": null, "reviewed_by": null, "signed_from": "", "signed_name": "", "uploaded_by": null, "completed_on": null, "content_hash": "", "signature_path": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|compliance_records|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"id": 3, "status": "accepted", "item_id": "16d28005-9596-4837-a167-f0d30b1ed26b", "user_id": "db00fb0c-3ac0-4ea6-939f-057d09a8f5f5", "version": 1, "provider": "", "file_name": "screen.png", "file_path": "db00fb0c-3ac0-4ea6-939f-057d09a8f5f5/1794209176697-screen.png", "issued_on": null, "created_at": "2026-11-09T07:26:16.82057+00:00", "doc_number": "NWS-1234", "expires_on": "2030-01-01", "review_note": "", "reviewed_at": "2026-11-09T10:27:26.090001+00:00", "reviewed_by": "1028b402-8a12-467c-adcf-2f1269268df7", "signed_from": "", "signed_name": "", "uploaded_by": "db00fb0c-3ac0-4ea6-939f-057d09a8f5f5", "completed_on": null, "content_hash": "", "signature_path": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|compliance_records|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"item_id": "1028b402-8a12-467c-adcf-2f1269268df7", "user_id": "1028b402-8a12-467c-adcf-2f1269268df7", "reviewed_by": "1028b402-8a12-467c-adcf-2f1269268df7", "uploaded_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|compliance_records|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"item_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "reviewed_by": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|compliance_records|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"id": 32, "status": "rejected", "item_id": "b803beda-f444-4ae3-ab63-b3c4446c0fab", "user_id": "eea9da48-a491-4526-ad8b-4861c4a2a8d0", "version": 1, "provider": "", "file_name": "x.pdf", "file_path": "eea9da48-a491-4526-ad8b-4861c4a2a8d0/x.pdf", "issued_on": null, "created_at": "2026-11-04T21:14:30.544857+00:00", "doc_number": "", "expires_on": null, "review_note": "", "reviewed_at": null, "reviewed_by": null, "signed_from": "", "signed_name": "", "uploaded_by": null, "completed_on": null, "content_hash": "", "signature_path": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|compliance_records|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"item_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "user_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "reviewed_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "uploaded_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|compliance_records|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"item_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "reviewed_by": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|compliance_records|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"id": 32, "status": "rejected", "item_id": "b803beda-f444-4ae3-ab63-b3c4446c0fab", "user_id": "eea9da48-a491-4526-ad8b-4861c4a2a8d0", "version": 1, "provider": "", "file_name": "x.pdf", "file_path": "eea9da48-a491-4526-ad8b-4861c4a2a8d0/x.pdf", "issued_on": null, "created_at": "2026-11-04T21:14:30.544857+00:00", "doc_number": "", "expires_on": null, "review_note": "", "reviewed_at": null, "reviewed_by": null, "signed_from": "", "signed_name": "", "uploaded_by": null, "completed_on": null, "content_hash": "", "signature_path": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|compliance_records|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"item_id": "b0104664-71b0-4297-9d29-942575610100", "user_id": "b0104664-71b0-4297-9d29-942575610100", "reviewed_by": "b0104664-71b0-4297-9d29-942575610100", "uploaded_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|compliance_records|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"item_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "reviewed_by": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|compliance_records|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"id": 32, "status": "rejected", "item_id": "b803beda-f444-4ae3-ab63-b3c4446c0fab", "user_id": "eea9da48-a491-4526-ad8b-4861c4a2a8d0", "version": 1, "provider": "", "file_name": "x.pdf", "file_path": "eea9da48-a491-4526-ad8b-4861c4a2a8d0/x.pdf", "issued_on": null, "created_at": "2026-11-04T21:14:30.544857+00:00", "doc_number": "", "expires_on": null, "review_note": "", "reviewed_at": null, "reviewed_by": null, "signed_from": "", "signed_name": "", "uploaded_by": null, "completed_on": null, "content_hash": "", "signature_path": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|compliance_records|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"item_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "reviewed_by": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|compliance_records|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.compliance_records (item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from) select item_id,user_id,version,status,file_path,file_name,expires_on,review_note,reviewed_by,reviewed_at,created_at,uploaded_by,issued_on,doc_number,completed_on,provider,signed_name,signature_path,content_hash,signed_from from jsonb_populate_record(null::public.compliance_records, '{"item_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "reviewed_by": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|custom_alerts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_alerts (id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour) select id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour from jsonb_populate_record(null::public.custom_alerts, '{"id": "00000000-0000-4000-8000-052232020233", "feature_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "field_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|custom_alerts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_alerts (id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour) select id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour from jsonb_populate_record(null::public.custom_alerts, '{"id": "00000000-0000-4000-8000-090039886629", "feature_id": "11111111-1111-4111-8111-111111111111", "field_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|custom_alerts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_alerts (id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour) select id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour from jsonb_populate_record(null::public.custom_alerts, '{"id": "00000000-0000-4000-8000-904159582420", "feature_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "field_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|custom_alerts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_alerts (id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour) select id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour from jsonb_populate_record(null::public.custom_alerts, '{"id": "00000000-0000-4000-8000-941967448816", "feature_id": "11111111-1111-4111-8111-111111111111", "field_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|custom_alerts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_alerts (id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour) select id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour from jsonb_populate_record(null::public.custom_alerts, '{"id": "00000000-0000-4000-8000-819763273806", "feature_id": "1028b402-8a12-467c-adcf-2f1269268df7", "field_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|custom_alerts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_alerts (id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour) select id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour from jsonb_populate_record(null::public.custom_alerts, '{"id": "00000000-0000-4000-8000-431063716623", "feature_id": "11111111-1111-4111-8111-111111111111", "field_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|custom_alerts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_alerts (id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour) select id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour from jsonb_populate_record(null::public.custom_alerts, '{"id": "00000000-0000-4000-8000-138246568955", "feature_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "field_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|custom_alerts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_alerts (id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour) select id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour from jsonb_populate_record(null::public.custom_alerts, '{"id": "00000000-0000-4000-8000-176054435351", "feature_id": "11111111-1111-4111-8111-111111111111", "field_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|custom_alerts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_alerts (id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour) select id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour from jsonb_populate_record(null::public.custom_alerts, '{"id": "00000000-0000-4000-8000-395117192046", "feature_id": "b0104664-71b0-4297-9d29-942575610100", "field_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|custom_alerts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_alerts (id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour) select id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour from jsonb_populate_record(null::public.custom_alerts, '{"id": "00000000-0000-4000-8000-427765369141", "feature_id": "11111111-1111-4111-8111-111111111111", "field_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|custom_alerts|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.custom_alerts (id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour) select id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour from jsonb_populate_record(null::public.custom_alerts, '{"id": "00000000-0000-4000-8000-861218498874", "feature_id": "11111111-1111-4111-8111-111111111111", "field_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|custom_alerts|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.custom_alerts (id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour) select id,feature_id,name,when_kind,field_id,match_text,limit_value,notify_roles,notify_leader,notify_people,by_bell,by_email,on_fix,message,active,created_at,at_hour from jsonb_populate_record(null::public.custom_alerts, '{"id": "00000000-0000-4000-8000-899026365270", "feature_id": "11111111-1111-4111-8111-111111111111", "field_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|custom_client_targets|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_client_targets (feature_id,client_id,target) select feature_id,client_id,target from jsonb_populate_record(null::public.custom_client_targets, '{"feature_id": "00000000-0000-4000-8000-768142293021", "client_id": "00000000-0000-4000-8000-768142293021"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|custom_client_targets|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_client_targets (feature_id,client_id,target) select feature_id,client_id,target from jsonb_populate_record(null::public.custom_client_targets, '{"feature_id": "00000000-0000-4000-8000-730334426625", "client_id": "00000000-0000-4000-8000-730334426625"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|custom_client_targets|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_client_targets (feature_id,client_id,target) select feature_id,client_id,target from jsonb_populate_record(null::public.custom_client_targets, '{"feature_id": "00000000-0000-4000-8000-101391276260", "client_id": "00000000-0000-4000-8000-101391276260"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|custom_client_targets|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_client_targets (feature_id,client_id,target) select feature_id,client_id,target from jsonb_populate_record(null::public.custom_client_targets, '{"feature_id": "00000000-0000-4000-8000-063583409864", "client_id": "00000000-0000-4000-8000-063583409864"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|custom_client_targets|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_client_targets (feature_id,client_id,target) select feature_id,client_id,target from jsonb_populate_record(null::public.custom_client_targets, '{"feature_id": "00000000-0000-4000-8000-000611039448", "client_id": "00000000-0000-4000-8000-000611039448"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|custom_client_targets|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_client_targets (feature_id,client_id,target) select feature_id,client_id,target from jsonb_populate_record(null::public.custom_client_targets, '{"feature_id": "00000000-0000-4000-8000-962803173052", "client_id": "00000000-0000-4000-8000-962803173052"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|custom_client_targets|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_client_targets (feature_id,client_id,target) select feature_id,client_id,target from jsonb_populate_record(null::public.custom_client_targets, '{"feature_id": "00000000-0000-4000-8000-682127744299", "client_id": "00000000-0000-4000-8000-682127744299"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|custom_client_targets|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_client_targets (feature_id,client_id,target) select feature_id,client_id,target from jsonb_populate_record(null::public.custom_client_targets, '{"feature_id": "00000000-0000-4000-8000-644319877903", "client_id": "00000000-0000-4000-8000-644319877903"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|custom_client_targets|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_client_targets (feature_id,client_id,target) select feature_id,client_id,target from jsonb_populate_record(null::public.custom_client_targets, '{"feature_id": "00000000-0000-4000-8000-673041500890", "client_id": "00000000-0000-4000-8000-673041500890"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|custom_client_targets|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_client_targets (feature_id,client_id,target) select feature_id,client_id,target from jsonb_populate_record(null::public.custom_client_targets, '{"feature_id": "00000000-0000-4000-8000-710849367286", "client_id": "00000000-0000-4000-8000-710849367286"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|custom_client_targets|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.custom_client_targets (feature_id,client_id,target) select feature_id,client_id,target from jsonb_populate_record(null::public.custom_client_targets, '{"feature_id": "00000000-0000-4000-8000-430702420852", "client_id": "00000000-0000-4000-8000-430702420852"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|custom_client_targets|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.custom_client_targets (feature_id,client_id,target) select feature_id,client_id,target from jsonb_populate_record(null::public.custom_client_targets, '{"feature_id": "00000000-0000-4000-8000-681529411281", "client_id": "00000000-0000-4000-8000-681529411281"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|custom_entries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_entries (org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason) select org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason from jsonb_populate_record(null::public.custom_entries, '{"org_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "feature_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "client_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a", "corrected_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|custom_entries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_entries (org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason) select org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason from jsonb_populate_record(null::public.custom_entries, '{"org_id": "11111111-1111-4111-8111-111111111111", "feature_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "corrected_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|custom_entries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_entries (org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason) select org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason from jsonb_populate_record(null::public.custom_entries, '{"org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "feature_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "client_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "corrected_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|custom_entries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_entries (org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason) select org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason from jsonb_populate_record(null::public.custom_entries, '{"org_id": "11111111-1111-4111-8111-111111111111", "feature_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "corrected_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|custom_entries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_entries (org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason) select org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason from jsonb_populate_record(null::public.custom_entries, '{"org_id": "1028b402-8a12-467c-adcf-2f1269268df7", "feature_id": "1028b402-8a12-467c-adcf-2f1269268df7", "client_id": "1028b402-8a12-467c-adcf-2f1269268df7", "created_by": "1028b402-8a12-467c-adcf-2f1269268df7", "corrected_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|custom_entries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_entries (org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason) select org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason from jsonb_populate_record(null::public.custom_entries, '{"org_id": "11111111-1111-4111-8111-111111111111", "feature_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "corrected_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|custom_entries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_entries (org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason) select org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason from jsonb_populate_record(null::public.custom_entries, '{"org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "feature_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "client_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "created_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "corrected_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|custom_entries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_entries (org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason) select org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason from jsonb_populate_record(null::public.custom_entries, '{"org_id": "11111111-1111-4111-8111-111111111111", "feature_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "corrected_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|custom_entries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_entries (org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason) select org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason from jsonb_populate_record(null::public.custom_entries, '{"org_id": "b0104664-71b0-4297-9d29-942575610100", "feature_id": "b0104664-71b0-4297-9d29-942575610100", "client_id": "b0104664-71b0-4297-9d29-942575610100", "created_by": "b0104664-71b0-4297-9d29-942575610100", "corrected_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|custom_entries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_entries (org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason) select org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason from jsonb_populate_record(null::public.custom_entries, '{"org_id": "11111111-1111-4111-8111-111111111111", "feature_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "corrected_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|custom_entries|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.custom_entries (org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason) select org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason from jsonb_populate_record(null::public.custom_entries, '{"org_id": "11111111-1111-4111-8111-111111111111", "feature_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "corrected_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|custom_entries|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.custom_entries (org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason) select org_id,feature_id,data,client_id,client_name,team_names,created_by,created_at,corrected_at,corrected_by,correction_reason from jsonb_populate_record(null::public.custom_entries, '{"org_id": "11111111-1111-4111-8111-111111111111", "feature_id": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "corrected_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|custom_features|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_features (id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour) select id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour from jsonb_populate_record(null::public.custom_features, '{"id": "00000000-0000-4000-8000-417566143500", "org_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "total_field": "0a29bd38-850f-4222-b674-d080fe462c2a", "group_field": "0a29bd38-850f-4222-b674-d080fe462c2a", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|custom_features|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_features (id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour) select id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour from jsonb_populate_record(null::public.custom_features, '{"id": "00000000-0000-4000-8000-668393133929", "org_id": "11111111-1111-4111-8111-111111111111", "total_field": "11111111-1111-4111-8111-111111111111", "group_field": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|custom_features|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_features (id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour) select id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour from jsonb_populate_record(null::public.custom_features, '{"id": "00000000-0000-4000-8000-939910056749", "org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "total_field": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "group_field": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|custom_features|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_features (id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour) select id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour from jsonb_populate_record(null::public.custom_features, '{"id": "00000000-0000-4000-8000-095991628471", "org_id": "11111111-1111-4111-8111-111111111111", "total_field": "11111111-1111-4111-8111-111111111111", "group_field": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|custom_features|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_features (id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour) select id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour from jsonb_populate_record(null::public.custom_features, '{"id": "00000000-0000-4000-8000-752055436736", "org_id": "1028b402-8a12-467c-adcf-2f1269268df7", "total_field": "1028b402-8a12-467c-adcf-2f1269268df7", "group_field": "1028b402-8a12-467c-adcf-2f1269268df7", "created_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|custom_features|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_features (id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour) select id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour from jsonb_populate_record(null::public.custom_features, '{"id": "00000000-0000-4000-8000-789863303132", "org_id": "11111111-1111-4111-8111-111111111111", "total_field": "11111111-1111-4111-8111-111111111111", "group_field": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|custom_features|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_features (id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour) select id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour from jsonb_populate_record(null::public.custom_features, '{"id": "00000000-0000-4000-8000-714535962906", "org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "total_field": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "group_field": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "created_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|custom_features|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_features (id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour) select id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour from jsonb_populate_record(null::public.custom_features, '{"id": "00000000-0000-4000-8000-582378585207", "org_id": "11111111-1111-4111-8111-111111111111", "total_field": "11111111-1111-4111-8111-111111111111", "group_field": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|custom_features|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_features (id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour) select id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour from jsonb_populate_record(null::public.custom_features, '{"id": "00000000-0000-4000-8000-265017206414", "org_id": "b0104664-71b0-4297-9d29-942575610100", "total_field": "b0104664-71b0-4297-9d29-942575610100", "group_field": "b0104664-71b0-4297-9d29-942575610100", "created_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|custom_features|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_features (id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour) select id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour from jsonb_populate_record(null::public.custom_features, '{"id": "00000000-0000-4000-8000-227209340018", "org_id": "11111111-1111-4111-8111-111111111111", "total_field": "11111111-1111-4111-8111-111111111111", "group_field": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|custom_features|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.custom_features (id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour) select id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour from jsonb_populate_record(null::public.custom_features, '{"id": "00000000-0000-4000-8000-507140600758", "org_id": "11111111-1111-4111-8111-111111111111", "total_field": "11111111-1111-4111-8111-111111111111", "group_field": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|custom_features|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.custom_features (id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour) select id,org_id,slug,name,menu_label,description,status,enabled,fill_roles,see_roles,undo_minutes,record_team,total_field,group_field,default_target,sort_order,created_by,created_at,updated_at,published_at,managers_fix,managers_targets,managers_options,in_app,app_icon,app_colour from jsonb_populate_record(null::public.custom_features, '{"id": "00000000-0000-4000-8000-256313610329", "org_id": "11111111-1111-4111-8111-111111111111", "total_field": "11111111-1111-4111-8111-111111111111", "group_field": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|custom_fields|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_fields (id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed) select id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed from jsonb_populate_record(null::public.custom_fields, '{"id": "00000000-0000-4000-8000-110236367740", "feature_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|custom_fields|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_fields (id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed) select id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed from jsonb_populate_record(null::public.custom_fields, '{"id": "00000000-0000-4000-8000-925665317480", "feature_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|custom_fields|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_fields (id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed) select id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed from jsonb_populate_record(null::public.custom_fields, '{"id": "00000000-0000-4000-8000-420820438201", "feature_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|custom_fields|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_fields (id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed) select id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed from jsonb_populate_record(null::public.custom_fields, '{"id": "00000000-0000-4000-8000-383012571805", "feature_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|custom_fields|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_fields (id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed) select id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed from jsonb_populate_record(null::public.custom_fields, '{"id": "00000000-0000-4000-8000-877767621313", "feature_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|custom_fields|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_fields (id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed) select id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed from jsonb_populate_record(null::public.custom_fields, '{"id": "00000000-0000-4000-8000-373059369116", "feature_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|custom_fields|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_fields (id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed) select id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed from jsonb_populate_record(null::public.custom_fields, '{"id": "00000000-0000-4000-8000-196250916462", "feature_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|custom_fields|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_fields (id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed) select id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed from jsonb_populate_record(null::public.custom_fields, '{"id": "00000000-0000-4000-8000-234058782858", "feature_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|custom_fields|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_fields (id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed) select id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed from jsonb_populate_record(null::public.custom_fields, '{"id": "00000000-0000-4000-8000-337112844539", "feature_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|custom_fields|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.custom_fields (id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed) select id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed from jsonb_populate_record(null::public.custom_fields, '{"id": "00000000-0000-4000-8000-485769716648", "feature_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|custom_fields|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.custom_fields (id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed) select id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed from jsonb_populate_record(null::public.custom_fields, '{"id": "00000000-0000-4000-8000-865851848410", "feature_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|custom_fields|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.custom_fields (id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed) select id,feature_id,label,type,required,help,unit,min_value,max_value,options,allow_other,quick,sort_order,archived,created_at,add_typed from jsonb_populate_record(null::public.custom_fields, '{"id": "00000000-0000-4000-8000-957030712777", "feature_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|delegation_rules|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"area": "roles", "mode": "managers", "people": [], "updated_at": "2026-11-09T02:09:27.173451+00:00", "updated_by": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|delegation_rules|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"updated_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|delegation_rules|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|delegation_rules|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"area": "roles", "mode": "managers", "people": [], "updated_at": "2026-11-09T02:09:27.173451+00:00", "updated_by": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|delegation_rules|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"updated_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|delegation_rules|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|delegation_rules|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"area": "roles", "mode": "managers", "people": [], "updated_at": "2026-11-09T02:09:27.173451+00:00", "updated_by": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|delegation_rules|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"updated_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|delegation_rules|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|delegation_rules|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"area": "roles", "mode": "managers", "people": [], "updated_at": "2026-11-09T02:09:27.173451+00:00", "updated_by": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|delegation_rules|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"updated_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|delegation_rules|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|delegation_rules|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"area": "roles", "mode": "managers", "people": [], "updated_at": "2026-11-09T02:09:27.173451+00:00", "updated_by": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|delegation_rules|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"updated_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|delegation_rules|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|delegation_rules|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"area": "roles", "mode": "managers", "people": [], "updated_at": "2026-11-09T02:09:27.173451+00:00", "updated_by": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|delegation_rules|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|delegation_rules|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.delegation_rules (area,mode,people,updated_by,updated_at) select area,mode,people,updated_by,updated_at from jsonb_populate_record(null::public.delegation_rules, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|delegation_shares|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_shares (area,user_id,shared_by,shared_at) select area,user_id,shared_by,shared_at from jsonb_populate_record(null::public.delegation_shares, '{"user_id": "00000000-0000-4000-8000-416402966683", "shared_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|delegation_shares|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_shares (area,user_id,shared_by,shared_at) select area,user_id,shared_by,shared_at from jsonb_populate_record(null::public.delegation_shares, '{"user_id": "00000000-0000-4000-8000-165575976254", "shared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|delegation_shares|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_shares (area,user_id,shared_by,shared_at) select area,user_id,shared_by,shared_at from jsonb_populate_record(null::public.delegation_shares, '{"user_id": "00000000-0000-4000-8000-083153983444", "shared_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|delegation_shares|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_shares (area,user_id,shared_by,shared_at) select area,user_id,shared_by,shared_at from jsonb_populate_record(null::public.delegation_shares, '{"user_id": "00000000-0000-4000-8000-120961849840", "shared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|delegation_shares|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_shares (area,user_id,shared_by,shared_at) select area,user_id,shared_by,shared_at from jsonb_populate_record(null::public.delegation_shares, '{"user_id": "00000000-0000-4000-8000-487685004697", "shared_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|delegation_shares|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_shares (area,user_id,shared_by,shared_at) select area,user_id,shared_by,shared_at from jsonb_populate_record(null::public.delegation_shares, '{"user_id": "00000000-0000-4000-8000-449877138301", "shared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|delegation_shares|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_shares (area,user_id,shared_by,shared_at) select area,user_id,shared_by,shared_at from jsonb_populate_record(null::public.delegation_shares, '{"user_id": "00000000-0000-4000-8000-373484213509", "shared_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|delegation_shares|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_shares (area,user_id,shared_by,shared_at) select area,user_id,shared_by,shared_at from jsonb_populate_record(null::public.delegation_shares, '{"user_id": "00000000-0000-4000-8000-335676347113", "shared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|delegation_shares|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_shares (area,user_id,shared_by,shared_at) select area,user_id,shared_by,shared_at from jsonb_populate_record(null::public.delegation_shares, '{"user_id": "00000000-0000-4000-8000-568951903769", "shared_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|delegation_shares|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.delegation_shares (area,user_id,shared_by,shared_at) select area,user_id,shared_by,shared_at from jsonb_populate_record(null::public.delegation_shares, '{"user_id": "00000000-0000-4000-8000-606759770165", "shared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|delegation_shares|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.delegation_shares (area,user_id,shared_by,shared_at) select area,user_id,shared_by,shared_at from jsonb_populate_record(null::public.delegation_shares, '{"user_id": "00000000-0000-4000-8000-650512283590", "shared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|delegation_shares|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.delegation_shares (area,user_id,shared_by,shared_at) select area,user_id,shared_by,shared_at from jsonb_populate_record(null::public.delegation_shares, '{"user_id": "00000000-0000-4000-8000-612704417194", "shared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|features|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"key": "hr_req_timesheet", "label": "Timesheet corrections", "parent": "hr_requests", "enabled": true, "premium": false, "included": true, "sort_order": 345, "updated_at": "2026-11-09T02:17:55.922055+00:00", "updated_by": null, "description": "Correct the times on a timesheet."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|features|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"updated_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|features|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|features|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"key": "hr_req_timesheet", "label": "Timesheet corrections", "parent": "hr_requests", "enabled": true, "premium": false, "included": true, "sort_order": 345, "updated_at": "2026-11-09T02:17:55.922055+00:00", "updated_by": null, "description": "Correct the times on a timesheet."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|features|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"updated_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|features|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|features|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"key": "hr_req_timesheet", "label": "Timesheet corrections", "parent": "hr_requests", "enabled": true, "premium": false, "included": true, "sort_order": 345, "updated_at": "2026-11-09T02:17:55.922055+00:00", "updated_by": null, "description": "Correct the times on a timesheet."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|features|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"updated_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|features|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|features|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"key": "hr_req_timesheet", "label": "Timesheet corrections", "parent": "hr_requests", "enabled": true, "premium": false, "included": true, "sort_order": 345, "updated_at": "2026-11-09T02:17:55.922055+00:00", "updated_by": null, "description": "Correct the times on a timesheet."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|features|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"updated_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|features|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|features|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"key": "hr_req_timesheet", "label": "Timesheet corrections", "parent": "hr_requests", "enabled": true, "premium": false, "included": true, "sort_order": 345, "updated_at": "2026-11-09T02:17:55.922055+00:00", "updated_by": null, "description": "Correct the times on a timesheet."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|features|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"updated_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|features|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|features|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"key": "hr_req_timesheet", "label": "Timesheet corrections", "parent": "hr_requests", "enabled": true, "premium": false, "included": true, "sort_order": 345, "updated_at": "2026-11-09T02:17:55.922055+00:00", "updated_by": null, "description": "Correct the times on a timesheet."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|features|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|features|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.features (key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent) select key,label,description,enabled,sort_order,updated_at,updated_by,premium,included,parent from jsonb_populate_record(null::public.features, '{"updated_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|form_collaborators|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_collaborators (form_id,user_id) select form_id,user_id from jsonb_populate_record(null::public.form_collaborators, '{"form_id": "00000000-0000-4000-8000-552147821757", "user_id": "00000000-0000-4000-8000-552147821757"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|form_collaborators|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_collaborators (form_id,user_id) select form_id,user_id from jsonb_populate_record(null::public.form_collaborators, '{"form_id": "00000000-0000-4000-8000-698679168672", "user_id": "00000000-0000-4000-8000-698679168672"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|form_collaborators|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_collaborators (form_id,user_id) select form_id,user_id from jsonb_populate_record(null::public.form_collaborators, '{"form_id": "00000000-0000-4000-8000-978908984184", "user_id": "00000000-0000-4000-8000-978908984184"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|form_collaborators|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_collaborators (form_id,user_id) select form_id,user_id from jsonb_populate_record(null::public.form_collaborators, '{"form_id": "00000000-0000-4000-8000-843973577003", "user_id": "00000000-0000-4000-8000-843973577003"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|form_collaborators|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_collaborators (form_id,user_id) select form_id,user_id from jsonb_populate_record(null::public.form_collaborators, '{"form_id": "00000000-0000-4000-8000-968955781495", "user_id": "00000000-0000-4000-8000-968955781495"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|form_collaborators|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_collaborators (form_id,user_id) select form_id,user_id from jsonb_populate_record(null::public.form_collaborators, '{"form_id": "00000000-0000-4000-8000-931147915099", "user_id": "00000000-0000-4000-8000-931147915099"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|form_collaborators|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_collaborators (form_id,user_id) select form_id,user_id from jsonb_populate_record(null::public.form_collaborators, '{"form_id": "00000000-0000-4000-8000-638162370479", "user_id": "00000000-0000-4000-8000-638162370479"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|form_collaborators|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_collaborators (form_id,user_id) select form_id,user_id from jsonb_populate_record(null::public.form_collaborators, '{"form_id": "00000000-0000-4000-8000-675970236875", "user_id": "00000000-0000-4000-8000-675970236875"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|form_collaborators|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_collaborators (form_id,user_id) select form_id,user_id from jsonb_populate_record(null::public.form_collaborators, '{"form_id": "00000000-0000-4000-8000-704696758843", "user_id": "00000000-0000-4000-8000-704696758843"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|form_collaborators|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_collaborators (form_id,user_id) select form_id,user_id from jsonb_populate_record(null::public.form_collaborators, '{"form_id": "00000000-0000-4000-8000-742504625239", "user_id": "00000000-0000-4000-8000-742504625239"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|form_collaborators|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.form_collaborators (form_id,user_id) select form_id,user_id from jsonb_populate_record(null::public.form_collaborators, '{"form_id": "00000000-0000-4000-8000-213870617473", "user_id": "00000000-0000-4000-8000-213870617473"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|form_collaborators|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.form_collaborators (form_id,user_id) select form_id,user_id from jsonb_populate_record(null::public.form_collaborators, '{"form_id": "00000000-0000-4000-8000-176062751077", "user_id": "00000000-0000-4000-8000-176062751077"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|form_completions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_completions (form_id,user_id,done_at) select form_id,user_id,done_at from jsonb_populate_record(null::public.form_completions, '{"form_id": "00000000-0000-4000-8000-750611584578", "user_id": "00000000-0000-4000-8000-750611584578"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|form_completions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_completions (form_id,user_id,done_at) select form_id,user_id,done_at from jsonb_populate_record(null::public.form_completions, '{"form_id": "00000000-0000-4000-8000-788419450974", "user_id": "00000000-0000-4000-8000-788419450974"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|form_completions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_completions (form_id,user_id,done_at) select form_id,user_id,done_at from jsonb_populate_record(null::public.form_completions, '{"form_id": "00000000-0000-4000-8000-780445221363", "user_id": "00000000-0000-4000-8000-780445221363"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|form_completions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_completions (form_id,user_id,done_at) select form_id,user_id,done_at from jsonb_populate_record(null::public.form_completions, '{"form_id": "00000000-0000-4000-8000-742637354967", "user_id": "00000000-0000-4000-8000-742637354967"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|form_completions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_completions (form_id,user_id,done_at) select form_id,user_id,done_at from jsonb_populate_record(null::public.form_completions, '{"form_id": "00000000-0000-4000-8000-439846447848", "user_id": "00000000-0000-4000-8000-439846447848"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|form_completions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_completions (form_id,user_id,done_at) select form_id,user_id,done_at from jsonb_populate_record(null::public.form_completions, '{"form_id": "00000000-0000-4000-8000-383036113339", "user_id": "00000000-0000-4000-8000-383036113339"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|form_completions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_completions (form_id,user_id,done_at) select form_id,user_id,done_at from jsonb_populate_record(null::public.form_completions, '{"form_id": "00000000-0000-4000-8000-836626133300", "user_id": "00000000-0000-4000-8000-836626133300"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|form_completions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_completions (form_id,user_id,done_at) select form_id,user_id,done_at from jsonb_populate_record(null::public.form_completions, '{"form_id": "00000000-0000-4000-8000-874433999696", "user_id": "00000000-0000-4000-8000-874433999696"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|form_completions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_completions (form_id,user_id,done_at) select form_id,user_id,done_at from jsonb_populate_record(null::public.form_completions, '{"form_id": "00000000-0000-4000-8000-233806092490", "user_id": "00000000-0000-4000-8000-233806092490"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|form_completions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_completions (form_id,user_id,done_at) select form_id,user_id,done_at from jsonb_populate_record(null::public.form_completions, '{"form_id": "00000000-0000-4000-8000-017020897939", "user_id": "00000000-0000-4000-8000-017020897939"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|form_completions|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.form_completions (form_id,user_id,done_at) select form_id,user_id,done_at from jsonb_populate_record(null::public.form_completions, '{"form_id": "00000000-0000-4000-8000-398391222780", "user_id": "00000000-0000-4000-8000-398391222780"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|form_completions|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.form_completions (form_id,user_id,done_at) select form_id,user_id,done_at from jsonb_populate_record(null::public.form_completions, '{"form_id": "00000000-0000-4000-8000-360583356384", "user_id": "00000000-0000-4000-8000-360583356384"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|form_questions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_questions (id,form_id,label,type,required,help,options,sort_order,archived) select id,form_id,label,type,required,help,options,sort_order,archived from jsonb_populate_record(null::public.form_questions, '{"id": "00000000-0000-4000-8000-680499506433", "form_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|form_questions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_questions (id,form_id,label,type,required,help,options,sort_order,archived) select id,form_id,label,type,required,help,options,sort_order,archived from jsonb_populate_record(null::public.form_questions, '{"id": "00000000-0000-4000-8000-718307372829", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|form_questions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_questions (id,form_id,label,type,required,help,options,sort_order,archived) select id,form_id,label,type,required,help,options,sort_order,archived from jsonb_populate_record(null::public.form_questions, '{"id": "00000000-0000-4000-8000-850557299508", "form_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|form_questions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_questions (id,form_id,label,type,required,help,options,sort_order,archived) select id,form_id,label,type,required,help,options,sort_order,archived from jsonb_populate_record(null::public.form_questions, '{"id": "00000000-0000-4000-8000-812749433112", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|form_questions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_questions (id,form_id,label,type,required,help,options,sort_order,archived) select id,form_id,label,type,required,help,options,sort_order,archived from jsonb_populate_record(null::public.form_questions, '{"id": "00000000-0000-4000-8000-563751025623", "form_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|form_questions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_questions (id,form_id,label,type,required,help,options,sort_order,archived) select id,form_id,label,type,required,help,options,sort_order,archived from jsonb_populate_record(null::public.form_questions, '{"id": "00000000-0000-4000-8000-312924035194", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|form_questions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_questions (id,form_id,label,type,required,help,options,sort_order,archived) select id,form_id,label,type,required,help,options,sort_order,archived from jsonb_populate_record(null::public.form_questions, '{"id": "00000000-0000-4000-8000-766514055155", "form_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|form_questions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_questions (id,form_id,label,type,required,help,options,sort_order,archived) select id,form_id,label,type,required,help,options,sort_order,archived from jsonb_populate_record(null::public.form_questions, '{"id": "00000000-0000-4000-8000-804321921551", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|form_questions|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_questions (id,form_id,label,type,required,help,options,sort_order,archived) select id,form_id,label,type,required,help,options,sort_order,archived from jsonb_populate_record(null::public.form_questions, '{"id": "00000000-0000-4000-8000-836305985655", "form_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|form_questions|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_questions (id,form_id,label,type,required,help,options,sort_order,archived) select id,form_id,label,type,required,help,options,sort_order,archived from jsonb_populate_record(null::public.form_questions, '{"id": "00000000-0000-4000-8000-087132976084", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|form_questions|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.form_questions (id,form_id,label,type,required,help,options,sort_order,archived) select id,form_id,label,type,required,help,options,sort_order,archived from jsonb_populate_record(null::public.form_questions, '{"id": "00000000-0000-4000-8000-605206250691", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|form_questions|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.form_questions (id,form_id,label,type,required,help,options,sort_order,archived) select id,form_id,label,type,required,help,options,sort_order,archived from jsonb_populate_record(null::public.form_questions, '{"id": "00000000-0000-4000-8000-430695434529", "form_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|form_recipients|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_recipients (form_id,user_id,sent_at,reminded_at) select form_id,user_id,sent_at,reminded_at from jsonb_populate_record(null::public.form_recipients, '{"form_id": "00000000-0000-4000-8000-243914873892", "user_id": "00000000-0000-4000-8000-243914873892"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|form_recipients|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_recipients (form_id,user_id,sent_at,reminded_at) select form_id,user_id,sent_at,reminded_at from jsonb_populate_record(null::public.form_recipients, '{"form_id": "00000000-0000-4000-8000-791986811328", "user_id": "00000000-0000-4000-8000-791986811328"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|form_recipients|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_recipients (form_id,user_id,sent_at,reminded_at) select form_id,user_id,sent_at,reminded_at from jsonb_populate_record(null::public.form_recipients, '{"form_id": "00000000-0000-4000-8000-910665890653", "user_id": "00000000-0000-4000-8000-910665890653"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|form_recipients|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_recipients (form_id,user_id,sent_at,reminded_at) select form_id,user_id,sent_at,reminded_at from jsonb_populate_record(null::public.form_recipients, '{"form_id": "00000000-0000-4000-8000-948473757049", "user_id": "00000000-0000-4000-8000-948473757049"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|form_recipients|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_recipients (form_id,user_id,sent_at,reminded_at) select form_id,user_id,sent_at,reminded_at from jsonb_populate_record(null::public.form_recipients, '{"form_id": "00000000-0000-4000-8000-628461759337", "user_id": "00000000-0000-4000-8000-628461759337"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|form_recipients|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_recipients (form_id,user_id,sent_at,reminded_at) select form_id,user_id,sent_at,reminded_at from jsonb_populate_record(null::public.form_recipients, '{"form_id": "00000000-0000-4000-8000-622365231092", "user_id": "00000000-0000-4000-8000-622365231092"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|form_recipients|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_recipients (form_id,user_id,sent_at,reminded_at) select form_id,user_id,sent_at,reminded_at from jsonb_populate_record(null::public.form_recipients, '{"form_id": "00000000-0000-4000-8000-329929422614", "user_id": "00000000-0000-4000-8000-329929422614"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|form_recipients|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_recipients (form_id,user_id,sent_at,reminded_at) select form_id,user_id,sent_at,reminded_at from jsonb_populate_record(null::public.form_recipients, '{"form_id": "00000000-0000-4000-8000-705972262606", "user_id": "00000000-0000-4000-8000-705972262606"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|form_recipients|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_recipients (form_id,user_id,sent_at,reminded_at) select form_id,user_id,sent_at,reminded_at from jsonb_populate_record(null::public.form_recipients, '{"form_id": "00000000-0000-4000-8000-388610883813", "user_id": "00000000-0000-4000-8000-388610883813"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|form_recipients|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_recipients (form_id,user_id,sent_at,reminded_at) select form_id,user_id,sent_at,reminded_at from jsonb_populate_record(null::public.form_recipients, '{"form_id": "00000000-0000-4000-8000-434271677374", "user_id": "00000000-0000-4000-8000-434271677374"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|form_recipients|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.form_recipients (form_id,user_id,sent_at,reminded_at) select form_id,user_id,sent_at,reminded_at from jsonb_populate_record(null::public.form_recipients, '{"form_id": "00000000-0000-4000-8000-905087933466", "user_id": "00000000-0000-4000-8000-905087933466"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|form_recipients|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.form_recipients (form_id,user_id,sent_at,reminded_at) select form_id,user_id,sent_at,reminded_at from jsonb_populate_record(null::public.form_recipients, '{"form_id": "00000000-0000-4000-8000-867280067070", "user_id": "00000000-0000-4000-8000-867280067070"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|form_responses|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_responses (form_id,user_id,answers,status,created_at,updated_at,submitted_at) select form_id,user_id,answers,status,created_at,updated_at,submitted_at from jsonb_populate_record(null::public.form_responses, '{"form_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "user_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|form_responses|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_responses (form_id,user_id,answers,status,created_at,updated_at,submitted_at) select form_id,user_id,answers,status,created_at,updated_at,submitted_at from jsonb_populate_record(null::public.form_responses, '{"form_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|form_responses|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_responses (form_id,user_id,answers,status,created_at,updated_at,submitted_at) select form_id,user_id,answers,status,created_at,updated_at,submitted_at from jsonb_populate_record(null::public.form_responses, '{"form_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|form_responses|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_responses (form_id,user_id,answers,status,created_at,updated_at,submitted_at) select form_id,user_id,answers,status,created_at,updated_at,submitted_at from jsonb_populate_record(null::public.form_responses, '{"form_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|form_responses|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_responses (form_id,user_id,answers,status,created_at,updated_at,submitted_at) select form_id,user_id,answers,status,created_at,updated_at,submitted_at from jsonb_populate_record(null::public.form_responses, '{"form_id": "1028b402-8a12-467c-adcf-2f1269268df7", "user_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|form_responses|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_responses (form_id,user_id,answers,status,created_at,updated_at,submitted_at) select form_id,user_id,answers,status,created_at,updated_at,submitted_at from jsonb_populate_record(null::public.form_responses, '{"form_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|form_responses|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_responses (form_id,user_id,answers,status,created_at,updated_at,submitted_at) select form_id,user_id,answers,status,created_at,updated_at,submitted_at from jsonb_populate_record(null::public.form_responses, '{"form_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "user_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|form_responses|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_responses (form_id,user_id,answers,status,created_at,updated_at,submitted_at) select form_id,user_id,answers,status,created_at,updated_at,submitted_at from jsonb_populate_record(null::public.form_responses, '{"form_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|form_responses|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_responses (form_id,user_id,answers,status,created_at,updated_at,submitted_at) select form_id,user_id,answers,status,created_at,updated_at,submitted_at from jsonb_populate_record(null::public.form_responses, '{"form_id": "b0104664-71b0-4297-9d29-942575610100", "user_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|form_responses|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.form_responses (form_id,user_id,answers,status,created_at,updated_at,submitted_at) select form_id,user_id,answers,status,created_at,updated_at,submitted_at from jsonb_populate_record(null::public.form_responses, '{"form_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|form_responses|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.form_responses (form_id,user_id,answers,status,created_at,updated_at,submitted_at) select form_id,user_id,answers,status,created_at,updated_at,submitted_at from jsonb_populate_record(null::public.form_responses, '{"form_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|form_responses|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.form_responses (form_id,user_id,answers,status,created_at,updated_at,submitted_at) select form_id,user_id,answers,status,created_at,updated_at,submitted_at from jsonb_populate_record(null::public.form_responses, '{"form_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|forms|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.forms (id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at) select id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at from jsonb_populate_record(null::public.forms, '{"id": "00000000-0000-4000-8000-394497833156", "org_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|forms|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.forms (id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at) select id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at from jsonb_populate_record(null::public.forms, '{"id": "00000000-0000-4000-8000-432305699552", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|forms|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.forms (id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at) select id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at from jsonb_populate_record(null::public.forms, '{"id": "00000000-0000-4000-8000-349883706742", "org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|forms|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.forms (id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at) select id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at from jsonb_populate_record(null::public.forms, '{"id": "00000000-0000-4000-8000-900943283687", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|forms|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.forms (id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at) select id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at from jsonb_populate_record(null::public.forms, '{"id": "00000000-0000-4000-8000-894764984218", "org_id": "1028b402-8a12-467c-adcf-2f1269268df7", "created_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|forms|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.forms (id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at) select id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at from jsonb_populate_record(null::public.forms, '{"id": "00000000-0000-4000-8000-932572850614", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|forms|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.forms (id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at) select id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at from jsonb_populate_record(null::public.forms, '{"id": "00000000-0000-4000-8000-477476904121", "org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "created_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|forms|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.forms (id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at) select id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at from jsonb_populate_record(null::public.forms, '{"id": "00000000-0000-4000-8000-439669037725", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|forms|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.forms (id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at) select id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at from jsonb_populate_record(null::public.forms, '{"id": "00000000-0000-4000-8000-122307658932", "org_id": "b0104664-71b0-4297-9d29-942575610100", "created_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|forms|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.forms (id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at) select id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at from jsonb_populate_record(null::public.forms, '{"id": "00000000-0000-4000-8000-084499792536", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|forms|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.forms (id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at) select id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at from jsonb_populate_record(null::public.forms, '{"id": "00000000-0000-4000-8000-731937705325", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|forms|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.forms (id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at) select id,org_id,title,intro,status,enabled,repeatable,anonymous,show_header,show_contact,notify_creator,due_date,closes_on,created_by,created_at,updated_at,published_at from jsonb_populate_record(null::public.forms, '{"id": "00000000-0000-4000-8000-518889285104", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|invitations|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-520644171575", "role": "support_worker", "email": "perf285@example.test", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "user_id": "bd4d88f9-9810-45e5-b882-7433401c9485", "full_name": "Test Person 285", "created_at": "2026-11-09T21:14:30.544857+00:00", "invited_by": null, "accepted_at": "2026-11-09T21:14:30.544857+00:00", "job_title_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|invitations|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-401893721235", "org_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "team_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "invited_by": "0a29bd38-850f-4222-b674-d080fe462c2a", "user_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "job_title_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|invitations|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-420988839952", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "invited_by": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|invitations|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-853893154814", "role": "support_worker", "email": "perf285@example.test", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "user_id": "bd4d88f9-9810-45e5-b882-7433401c9485", "full_name": "Test Person 285", "created_at": "2026-11-09T21:14:30.544857+00:00", "invited_by": null, "accepted_at": "2026-11-09T21:14:30.544857+00:00", "job_title_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|invitations|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-978484787223", "role": "manager", "email": "boss@example.com", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "full_name": "Morgan Manager", "created_at": "2026-11-09T02:09:38.683643+00:00", "invited_by": null, "accepted_at": "2026-11-09T02:09:38.944236+00:00", "job_title_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|invitations|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-735142704474", "org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "team_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "invited_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "job_title_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|invitations|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-697334838078", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "invited_by": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|invitations|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-937612265486", "role": "support_worker", "email": "perf285@example.test", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "user_id": "bd4d88f9-9810-45e5-b882-7433401c9485", "full_name": "Test Person 285", "created_at": "2026-11-09T21:14:30.544857+00:00", "invited_by": null, "accepted_at": "2026-11-09T21:14:30.544857+00:00", "job_title_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|invitations|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-907370144380", "role": "staff_admin", "email": "office@example.com", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "user_id": "1028b402-8a12-467c-adcf-2f1269268df7", "full_name": "Olive Office", "created_at": "2026-11-09T02:09:38.683643+00:00", "invited_by": null, "accepted_at": "2026-11-09T02:09:39.01197+00:00", "job_title_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|invitations|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-150712227129", "org_id": "1028b402-8a12-467c-adcf-2f1269268df7", "team_id": "1028b402-8a12-467c-adcf-2f1269268df7", "invited_by": "1028b402-8a12-467c-adcf-2f1269268df7", "user_id": "1028b402-8a12-467c-adcf-2f1269268df7", "job_title_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|invitations|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-188520093525", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "invited_by": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|invitations|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-434629622853", "role": "support_worker", "email": "perf285@example.test", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "user_id": "bd4d88f9-9810-45e5-b882-7433401c9485", "full_name": "Test Person 285", "created_at": "2026-11-09T21:14:30.544857+00:00", "invited_by": null, "accepted_at": "2026-11-09T21:14:30.544857+00:00", "job_title_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|invitations|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-559221255262", "role": "team_leader", "email": "lead@example.com", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "user_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "full_name": "Taylor Lead", "created_at": "2026-11-09T02:09:38.683643+00:00", "invited_by": null, "accepted_at": "2026-11-09T02:09:39.086014+00:00", "job_title_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|invitations|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-315879172513", "org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "team_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "invited_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "user_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "job_title_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|invitations|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-507003388674", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "invited_by": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|invitations|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-920539622336", "role": "support_worker", "email": "perf285@example.test", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "user_id": "bd4d88f9-9810-45e5-b882-7433401c9485", "full_name": "Test Person 285", "created_at": "2026-11-09T21:14:30.544857+00:00", "invited_by": null, "accepted_at": "2026-11-09T21:14:30.544857+00:00", "job_title_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|invitations|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-492686866898", "role": "support_worker", "email": "sam@example.com", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "user_id": "b0104664-71b0-4297-9d29-942575610100", "full_name": "Sam Worker", "created_at": "2026-11-09T02:09:38.683643+00:00", "invited_by": null, "accepted_at": "2026-11-09T02:09:39.152855+00:00", "job_title_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|invitations|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-866360416021", "org_id": "b0104664-71b0-4297-9d29-942575610100", "team_id": "b0104664-71b0-4297-9d29-942575610100", "invited_by": "b0104664-71b0-4297-9d29-942575610100", "user_id": "b0104664-71b0-4297-9d29-942575610100", "job_title_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|invitations|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-828552549625", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "invited_by": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|invitations|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-183204299406", "role": "support_worker", "email": "perf285@example.test", "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "user_id": "bd4d88f9-9810-45e5-b882-7433401c9485", "full_name": "Test Person 285", "created_at": "2026-11-09T21:14:30.544857+00:00", "invited_by": null, "accepted_at": "2026-11-09T21:14:30.544857+00:00", "job_title_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|invitations|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-720620845725", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "invited_by": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|invitations|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.invitations (id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id) select id,org_id,email,full_name,role,team_id,invited_by,created_at,accepted_at,user_id,job_title_id from jsonb_populate_record(null::public.invitations, '{"id": "00000000-0000-4000-8000-932296471367", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "invited_by": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|job_titles|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.job_titles (id,org_id,name,access_level,description,active,sort_order,created_at) select id,org_id,name,access_level,description,active,sort_order,created_at from jsonb_populate_record(null::public.job_titles, '{"id": "00000000-0000-4000-8000-018519010912", "org_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|job_titles|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.job_titles (id,org_id,name,access_level,description,active,sort_order,created_at) select id,org_id,name,access_level,description,active,sort_order,created_at from jsonb_populate_record(null::public.job_titles, '{"id": "00000000-0000-4000-8000-269346001341", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|job_titles|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.job_titles (id,org_id,name,access_level,description,active,sort_order,created_at) select id,org_id,name,access_level,description,active,sort_order,created_at from jsonb_populate_record(null::public.job_titles, '{"id": "00000000-0000-4000-8000-338957189337", "org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|job_titles|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.job_titles (id,org_id,name,access_level,description,active,sort_order,created_at) select id,org_id,name,access_level,description,active,sort_order,created_at from jsonb_populate_record(null::public.job_titles, '{"id": "00000000-0000-4000-8000-088130198908", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|job_titles|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.job_titles (id,org_id,name,access_level,description,active,sort_order,created_at) select id,org_id,name,access_level,description,active,sort_order,created_at from jsonb_populate_record(null::public.job_titles, '{"id": "00000000-0000-4000-8000-806886716675", "org_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|job_titles|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.job_titles (id,org_id,name,access_level,description,active,sort_order,created_at) select id,org_id,name,access_level,description,active,sort_order,created_at from jsonb_populate_record(null::public.job_titles, '{"id": "00000000-0000-4000-8000-769078850279", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|job_titles|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.job_titles (id,org_id,name,access_level,description,active,sort_order,created_at) select id,org_id,name,access_level,description,active,sort_order,created_at from jsonb_populate_record(null::public.job_titles, '{"id": "00000000-0000-4000-8000-692685925487", "org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|job_titles|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.job_titles (id,org_id,name,access_level,description,active,sort_order,created_at) select id,org_id,name,access_level,description,active,sort_order,created_at from jsonb_populate_record(null::public.job_titles, '{"id": "00000000-0000-4000-8000-130196635700", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|job_titles|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.job_titles (id,org_id,name,access_level,description,active,sort_order,created_at) select id,org_id,name,access_level,description,active,sort_order,created_at from jsonb_populate_record(null::public.job_titles, '{"id": "00000000-0000-4000-8000-249750191791", "org_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|job_titles|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.job_titles (id,org_id,name,access_level,description,active,sort_order,created_at) select id,org_id,name,access_level,description,active,sort_order,created_at from jsonb_populate_record(null::public.job_titles, '{"id": "00000000-0000-4000-8000-287558058187", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|job_titles|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.job_titles (id,org_id,name,access_level,description,active,sort_order,created_at) select id,org_id,name,access_level,description,active,sort_order,created_at from jsonb_populate_record(null::public.job_titles, '{"id": "00000000-0000-4000-8000-969713995568", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|job_titles|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.job_titles (id,org_id,name,access_level,description,active,sort_order,created_at) select id,org_id,name,access_level,description,active,sort_order,created_at from jsonb_populate_record(null::public.job_titles, '{"id": "00000000-0000-4000-8000-931906129172", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|leave_periods|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"id": 1, "user_id": "b0104664-71b0-4297-9d29-942575610100", "end_date": "2026-12-24", "created_at": "2026-11-09T02:33:42.42504+00:00", "leave_type": "long_service", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434", "start_date": "2026-12-22"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|leave_periods|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"user_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "request_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|leave_periods|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|leave_periods|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"id": 1, "user_id": "b0104664-71b0-4297-9d29-942575610100", "end_date": "2026-12-24", "created_at": "2026-11-09T02:33:42.42504+00:00", "leave_type": "long_service", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434", "start_date": "2026-12-22"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|leave_periods|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "request_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|leave_periods|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|leave_periods|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"id": 1, "user_id": "b0104664-71b0-4297-9d29-942575610100", "end_date": "2026-12-24", "created_at": "2026-11-09T02:33:42.42504+00:00", "leave_type": "long_service", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434", "start_date": "2026-12-22"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|leave_periods|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"user_id": "1028b402-8a12-467c-adcf-2f1269268df7", "request_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|leave_periods|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|leave_periods|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"id": 1, "user_id": "b0104664-71b0-4297-9d29-942575610100", "end_date": "2026-12-24", "created_at": "2026-11-09T02:33:42.42504+00:00", "leave_type": "long_service", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434", "start_date": "2026-12-22"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|leave_periods|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"user_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "request_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|leave_periods|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|leave_periods|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"id": 1, "user_id": "b0104664-71b0-4297-9d29-942575610100", "end_date": "2026-12-24", "created_at": "2026-11-09T02:33:42.42504+00:00", "leave_type": "long_service", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434", "start_date": "2026-12-22"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|leave_periods|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"id": 1, "user_id": "b0104664-71b0-4297-9d29-942575610100", "end_date": "2026-12-24", "created_at": "2026-11-09T02:33:42.42504+00:00", "leave_type": "long_service", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434", "start_date": "2026-12-22"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|leave_periods|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"user_id": "b0104664-71b0-4297-9d29-942575610100", "request_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|leave_periods|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|leave_periods|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"id": 1, "user_id": "b0104664-71b0-4297-9d29-942575610100", "end_date": "2026-12-24", "created_at": "2026-11-09T02:33:42.42504+00:00", "leave_type": "long_service", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434", "start_date": "2026-12-22"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|leave_periods|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|leave_periods|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.leave_periods (user_id,request_id,leave_type,start_date,end_date,created_at) select user_id,request_id,leave_type,start_date,end_date,created_at from jsonb_populate_record(null::public.leave_periods, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|live_signals|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{"topic": "people", "changed_at": "2026-11-09T05:20:18.915284+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|live_signals|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|live_signals|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|live_signals|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{"topic": "people", "changed_at": "2026-11-09T05:20:18.915284+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|live_signals|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|live_signals|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|live_signals|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{"topic": "people", "changed_at": "2026-11-09T05:20:18.915284+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|live_signals|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|live_signals|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|live_signals|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{"topic": "people", "changed_at": "2026-11-09T05:20:18.915284+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|live_signals|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|live_signals|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|live_signals|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{"topic": "people", "changed_at": "2026-11-09T05:20:18.915284+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|live_signals|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|live_signals|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|live_signals|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{"topic": "people", "changed_at": "2026-11-09T05:20:18.915284+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|live_signals|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|live_signals|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.live_signals (topic,changed_at) select topic,changed_at from jsonb_populate_record(null::public.live_signals, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|notifications|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"id": 1820, "body": "Test only", "href": "/tasks", "kind": "task_assigned", "title": "Synthetic notice 1744", "seen_at": null, "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T21:14:30.544857+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|notifications|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"id": 14, "body": "by Morgan Manager", "href": "/tasks/a8da6a2e-7883-4b30-b6c9-be292ff8ace4", "kind": "task_completed", "title": "Completed: GEN-0001 Fall in the lounge: follow up with family", "seen_at": null, "user_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "created_at": "2026-11-09T02:33:46.75674+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|notifications|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"user_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|notifications|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|notifications|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"id": 1820, "body": "Test only", "href": "/tasks", "kind": "task_assigned", "title": "Synthetic notice 1744", "seen_at": null, "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T21:14:30.544857+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|notifications|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"id": 1820, "body": "Test only", "href": "/tasks", "kind": "task_assigned", "title": "Synthetic notice 1744", "seen_at": null, "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T21:14:30.544857+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|notifications|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|notifications|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|notifications|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"id": 1820, "body": "Test only", "href": "/tasks", "kind": "task_assigned", "title": "Synthetic notice 1744", "seen_at": null, "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T21:14:30.544857+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|notifications|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"id": 73, "body": "Check it on the Compliance page.", "href": "/compliance/people/2b0480ba-ebf9-4699-93bb-5d8e27e12f50", "kind": "upload_submitted", "title": "Nina Newstart uploaded NDIS Worker Screening Check", "seen_at": null, "user_id": "1028b402-8a12-467c-adcf-2f1269268df7", "created_at": "2026-11-09T07:27:07.723543+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|notifications|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"user_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|notifications|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|notifications|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"id": 1820, "body": "Test only", "href": "/tasks", "kind": "task_assigned", "title": "Synthetic notice 1744", "seen_at": null, "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T21:14:30.544857+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|notifications|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"id": 57, "body": "It''s on your My onboarding page.", "href": "/onboarding", "kind": "onboarding_item", "title": "Please upload: Employment agreement", "seen_at": null, "user_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "created_at": "2026-11-09T07:25:00.445831+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|notifications|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"user_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|notifications|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|notifications|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"id": 1820, "body": "Test only", "href": "/tasks", "kind": "task_assigned", "title": "Synthetic notice 1744", "seen_at": null, "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T21:14:30.544857+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|notifications|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"id": 12, "body": "It now goes for final approval.", "href": "/requests/b3bd529a-be7b-4e7c-b370-de25d6739434", "kind": "request_decided", "title": "Leave request REQ-0001: first approval done", "seen_at": null, "user_id": "b0104664-71b0-4297-9d29-942575610100", "created_at": "2026-11-09T02:33:36.560074+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|notifications|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"user_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|notifications|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|notifications|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"id": 1820, "body": "Test only", "href": "/tasks", "kind": "task_assigned", "title": "Synthetic notice 1744", "seen_at": null, "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T21:14:30.544857+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|notifications|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|notifications|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.notifications (user_id,kind,title,body,href,created_at,seen_at) select user_id,kind,title,body,href,created_at,seen_at from jsonb_populate_record(null::public.notifications, '{"user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|organisation|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-629472375421", "name": "Engaged Care Pty Ltd", "created_at": "2026-11-09T02:09:24.481512+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|organisation|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-942502357727"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|organisation|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-880380203460"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|organisation|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-296223392182", "name": "Engaged Care Pty Ltd", "created_at": "2026-11-09T02:09:24.481512+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|organisation|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-414973842522"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|organisation|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-452781708918"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|organisation|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-211827083568", "name": "Engaged Care Pty Ltd", "created_at": "2026-11-09T02:09:24.481512+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|organisation|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-713561902036"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|organisation|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-462734911607"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|organisation|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-530310378717", "name": "Engaged Care Pty Ltd", "created_at": "2026-11-09T02:09:24.481512+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|organisation|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-041664354431"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|organisation|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-003856488035"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|organisation|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-003053382284", "name": "Engaged Care Pty Ltd", "created_at": "2026-11-09T02:09:24.481512+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|organisation|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-283756130975"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|organisation|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-752145554245"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|organisation|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-321722609235", "name": "Engaged Care Pty Ltd", "created_at": "2026-11-09T02:09:24.481512+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|organisation|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-180012209233"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|organisation|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.organisation (id,name,created_at) select id,name,created_at from jsonb_populate_record(null::public.organisation, '{"id": "00000000-0000-4000-8000-217820075629"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|people_change_requests|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.people_change_requests (id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id) select id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id from jsonb_populate_record(null::public.people_change_requests, '{"id": "00000000-0000-4000-8000-381535782893", "user_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "team_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "requested_by": "0a29bd38-850f-4222-b674-d080fe462c2a", "decided_by": "0a29bd38-850f-4222-b674-d080fe462c2a", "task_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|people_change_requests|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.people_change_requests (id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id) select id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id from jsonb_populate_record(null::public.people_change_requests, '{"id": "00000000-0000-4000-8000-130708792464", "user_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "requested_by": "11111111-1111-4111-8111-111111111111", "decided_by": "11111111-1111-4111-8111-111111111111", "task_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|people_change_requests|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.people_change_requests (id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id) select id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id from jsonb_populate_record(null::public.people_change_requests, '{"id": "00000000-0000-4000-8000-048286799654", "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "team_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "requested_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "decided_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "task_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|people_change_requests|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.people_change_requests (id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id) select id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id from jsonb_populate_record(null::public.people_change_requests, '{"id": "00000000-0000-4000-8000-202540190775", "user_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "requested_by": "11111111-1111-4111-8111-111111111111", "decided_by": "11111111-1111-4111-8111-111111111111", "task_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|people_change_requests|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.people_change_requests (id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id) select id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id from jsonb_populate_record(null::public.people_change_requests, '{"id": "00000000-0000-4000-8000-522552188487", "user_id": "1028b402-8a12-467c-adcf-2f1269268df7", "team_id": "1028b402-8a12-467c-adcf-2f1269268df7", "requested_by": "1028b402-8a12-467c-adcf-2f1269268df7", "decided_by": "1028b402-8a12-467c-adcf-2f1269268df7", "task_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|people_change_requests|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.people_change_requests (id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id) select id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id from jsonb_populate_record(null::public.people_change_requests, '{"id": "00000000-0000-4000-8000-484744322091", "user_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "requested_by": "11111111-1111-4111-8111-111111111111", "decided_by": "11111111-1111-4111-8111-111111111111", "task_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|people_change_requests|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.people_change_requests (id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id) select id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id from jsonb_populate_record(null::public.people_change_requests, '{"id": "00000000-0000-4000-8000-467550331615", "user_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "team_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "requested_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "decided_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "task_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|people_change_requests|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.people_change_requests (id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id) select id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id from jsonb_populate_record(null::public.people_change_requests, '{"id": "00000000-0000-4000-8000-216723341186", "user_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "requested_by": "11111111-1111-4111-8111-111111111111", "decided_by": "11111111-1111-4111-8111-111111111111", "task_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|people_change_requests|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.people_change_requests (id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id) select id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id from jsonb_populate_record(null::public.people_change_requests, '{"id": "00000000-0000-4000-8000-534084719979", "user_id": "b0104664-71b0-4297-9d29-942575610100", "team_id": "b0104664-71b0-4297-9d29-942575610100", "requested_by": "b0104664-71b0-4297-9d29-942575610100", "decided_by": "b0104664-71b0-4297-9d29-942575610100", "task_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|people_change_requests|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.people_change_requests (id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id) select id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id from jsonb_populate_record(null::public.people_change_requests, '{"id": "00000000-0000-4000-8000-571892586375", "user_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "requested_by": "11111111-1111-4111-8111-111111111111", "decided_by": "11111111-1111-4111-8111-111111111111", "task_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|people_change_requests|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.people_change_requests (id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id) select id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id from jsonb_populate_record(null::public.people_change_requests, '{"id": "00000000-0000-4000-8000-430340798237", "user_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "requested_by": "11111111-1111-4111-8111-111111111111", "decided_by": "11111111-1111-4111-8111-111111111111", "task_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|people_change_requests|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.people_change_requests (id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id) select id,kind,user_id,team_id,from_value,to_value,reason,requested_by,requested_at,status,decided_by,decided_at,decision_note,requester_seen_at,task_id from jsonb_populate_record(null::public.people_change_requests, '{"id": "00000000-0000-4000-8000-468148664633", "user_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "requested_by": "11111111-1111-4111-8111-111111111111", "decided_by": "11111111-1111-4111-8111-111111111111", "task_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|profiles|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-591484913579", "role": "support_worker", "email": "perf246@example.test", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "full_name": "Test Person 246", "joined_at": "2026-10-10T21:14:30.544857+00:00", "avatar_ref": null, "cleared_at": null, "cleared_by": null, "created_at": "2026-11-09T21:14:30.544857+00:00", "mfa_exempt": false, "job_title_id": null, "onboarded_at": null, "deactivated_at": null, "compliance_verified_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|profiles|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-716076545988", "role": "system_admin", "email": "owner@example.com", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "full_name": "", "joined_at": "2026-11-09T02:09:39.201098+00:00", "avatar_ref": null, "cleared_at": "2026-11-09T07:24:59.927735+00:00", "cleared_by": null, "created_at": "2026-11-09T02:09:38.872677+00:00", "mfa_exempt": false, "job_title_id": null, "onboarded_at": null, "deactivated_at": null, "compliance_verified_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|profiles|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-472734463239", "org_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "team_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "job_title_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "cleared_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|profiles|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-350148097948", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111", "cleared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|profiles|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-048832167904", "role": "support_worker", "email": "perf246@example.test", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "full_name": "Test Person 246", "joined_at": "2026-10-10T21:14:30.544857+00:00", "avatar_ref": null, "cleared_at": null, "cleared_by": null, "created_at": "2026-11-09T21:14:30.544857+00:00", "mfa_exempt": false, "job_title_id": null, "onboarded_at": null, "deactivated_at": null, "compliance_verified_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|profiles|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-826576199687", "role": "new_starter", "email": "nina1794209224196@example.com", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "full_name": "Nina Newstart", "joined_at": "2026-11-09T07:27:04.354083+00:00", "avatar_ref": null, "cleared_at": "2026-11-09T10:26:37.708+00:00", "cleared_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T07:27:04.311965+00:00", "mfa_exempt": false, "job_title_id": null, "onboarded_at": null, "deactivated_at": null, "compliance_verified_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|profiles|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-452902650564", "org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "team_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "job_title_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "cleared_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|profiles|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-797924339865", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111", "cleared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|profiles|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-866771523482", "role": "support_worker", "email": "perf246@example.test", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "full_name": "Test Person 246", "joined_at": "2026-10-10T21:14:30.544857+00:00", "avatar_ref": null, "cleared_at": null, "cleared_by": null, "created_at": "2026-11-09T21:14:30.544857+00:00", "mfa_exempt": false, "job_title_id": null, "onboarded_at": null, "deactivated_at": null, "compliance_verified_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|profiles|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-836529402376", "role": "staff_admin", "email": "office@example.com", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "full_name": "Olive Office", "joined_at": "2026-11-09T02:09:39.201098+00:00", "avatar_ref": null, "cleared_at": "2026-11-09T07:24:59.927735+00:00", "cleared_by": null, "created_at": "2026-11-09T02:09:39.01197+00:00", "mfa_exempt": false, "job_title_id": null, "onboarded_at": null, "deactivated_at": null, "compliance_verified_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|profiles|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-079871485125", "org_id": "1028b402-8a12-467c-adcf-2f1269268df7", "team_id": "1028b402-8a12-467c-adcf-2f1269268df7", "job_title_id": "1028b402-8a12-467c-adcf-2f1269268df7", "cleared_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|profiles|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-117679351521", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111", "cleared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|profiles|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-505470364857", "role": "support_worker", "email": "perf246@example.test", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "full_name": "Test Person 246", "joined_at": "2026-10-10T21:14:30.544857+00:00", "avatar_ref": null, "cleared_at": null, "cleared_by": null, "created_at": "2026-11-09T21:14:30.544857+00:00", "mfa_exempt": false, "job_title_id": null, "onboarded_at": null, "deactivated_at": null, "compliance_verified_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|profiles|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-630061997266", "role": "team_leader", "email": "lead@example.com", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "full_name": "Taylor Lead", "joined_at": "2026-11-09T02:09:39.201098+00:00", "avatar_ref": null, "cleared_at": "2026-11-09T07:24:59.927735+00:00", "cleared_by": null, "created_at": "2026-11-09T02:09:39.086014+00:00", "mfa_exempt": false, "job_title_id": null, "onboarded_at": null, "deactivated_at": null, "compliance_verified_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|profiles|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-386719914517", "org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "team_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "job_title_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "cleared_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|profiles|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-348912048121", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111", "cleared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|profiles|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-150301119668", "role": "support_worker", "email": "perf246@example.test", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "full_name": "Test Person 246", "joined_at": "2026-10-10T21:14:30.544857+00:00", "avatar_ref": null, "cleared_at": null, "cleared_by": null, "created_at": "2026-11-09T21:14:30.544857+00:00", "mfa_exempt": false, "job_title_id": null, "onboarded_at": null, "deactivated_at": null, "compliance_verified_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|profiles|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-563527608902", "role": "support_worker", "email": "sam@example.com", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "full_name": "Sam Worker", "joined_at": "2026-11-09T02:09:39.152855+00:00", "avatar_ref": null, "cleared_at": "2026-11-09T07:24:59.927735+00:00", "cleared_by": null, "created_at": "2026-11-09T02:09:39.152855+00:00", "mfa_exempt": false, "job_title_id": null, "onboarded_at": null, "deactivated_at": null, "compliance_verified_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|profiles|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-351433698800", "org_id": "b0104664-71b0-4297-9d29-942575610100", "team_id": "b0104664-71b0-4297-9d29-942575610100", "job_title_id": "b0104664-71b0-4297-9d29-942575610100", "cleared_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|profiles|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-899393291629", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111", "cleared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|profiles|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-493863578113", "role": "support_worker", "email": "perf246@example.test", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "team_id": null, "full_name": "Test Person 246", "joined_at": "2026-10-10T21:14:30.544857+00:00", "avatar_ref": null, "cleared_at": null, "cleared_by": null, "created_at": "2026-11-09T21:14:30.544857+00:00", "mfa_exempt": false, "job_title_id": null, "onboarded_at": null, "deactivated_at": null, "compliance_verified_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|profiles|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-409961567018", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111", "cleared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|profiles|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.profiles (id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by) select id,org_id,email,full_name,role,team_id,active,created_at,deactivated_at,job_title_id,joined_at,onboarded_at,mfa_exempt,avatar_ref,compliance_verified_at,cleared_at,cleared_by from jsonb_populate_record(null::public.profiles, '{"id": "00000000-0000-4000-8000-625940118202", "org_id": "11111111-1111-4111-8111-111111111111", "team_id": "11111111-1111-4111-8111-111111111111", "job_title_id": "11111111-1111-4111-8111-111111111111", "cleared_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|record_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.record_events (record_id,actor_id,type,details,created_at) select record_id,actor_id,type,details,created_at from jsonb_populate_record(null::public.record_events, '{"record_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "actor_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|record_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.record_events (record_id,actor_id,type,details,created_at) select record_id,actor_id,type,details,created_at from jsonb_populate_record(null::public.record_events, '{"record_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|record_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.record_events (record_id,actor_id,type,details,created_at) select record_id,actor_id,type,details,created_at from jsonb_populate_record(null::public.record_events, '{"record_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "actor_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|record_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.record_events (record_id,actor_id,type,details,created_at) select record_id,actor_id,type,details,created_at from jsonb_populate_record(null::public.record_events, '{"record_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|record_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.record_events (record_id,actor_id,type,details,created_at) select record_id,actor_id,type,details,created_at from jsonb_populate_record(null::public.record_events, '{"record_id": "1028b402-8a12-467c-adcf-2f1269268df7", "actor_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|record_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.record_events (record_id,actor_id,type,details,created_at) select record_id,actor_id,type,details,created_at from jsonb_populate_record(null::public.record_events, '{"record_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|record_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.record_events (record_id,actor_id,type,details,created_at) select record_id,actor_id,type,details,created_at from jsonb_populate_record(null::public.record_events, '{"record_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "actor_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|record_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.record_events (record_id,actor_id,type,details,created_at) select record_id,actor_id,type,details,created_at from jsonb_populate_record(null::public.record_events, '{"record_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|record_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.record_events (record_id,actor_id,type,details,created_at) select record_id,actor_id,type,details,created_at from jsonb_populate_record(null::public.record_events, '{"record_id": "b0104664-71b0-4297-9d29-942575610100", "actor_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|record_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.record_events (record_id,actor_id,type,details,created_at) select record_id,actor_id,type,details,created_at from jsonb_populate_record(null::public.record_events, '{"record_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|record_events|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.record_events (record_id,actor_id,type,details,created_at) select record_id,actor_id,type,details,created_at from jsonb_populate_record(null::public.record_events, '{"record_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|record_events|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.record_events (record_id,actor_id,type,details,created_at) select record_id,actor_id,type,details,created_at from jsonb_populate_record(null::public.record_events, '{"record_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|records|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.records (id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at) select id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at from jsonb_populate_record(null::public.records, '{"id": "00000000-0000-4000-8000-798011713632", "org_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "registry_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|records|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.records (id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at) select id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at from jsonb_populate_record(null::public.records, '{"id": "00000000-0000-4000-8000-760203847236", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|records|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.records (id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at) select id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at from jsonb_populate_record(null::public.records, '{"id": "00000000-0000-4000-8000-744641032043", "org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "registry_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|records|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.records (id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at) select id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at from jsonb_populate_record(null::public.records, '{"id": "00000000-0000-4000-8000-782448898439", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|records|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.records (id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at) select id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at from jsonb_populate_record(null::public.records, '{"id": "00000000-0000-4000-8000-030480460059", "org_id": "1028b402-8a12-467c-adcf-2f1269268df7", "registry_id": "1028b402-8a12-467c-adcf-2f1269268df7", "created_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|records|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.records (id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at) select id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at from jsonb_populate_record(null::public.records, '{"id": "00000000-0000-4000-8000-992672593663", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|records|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.records (id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at) select id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at from jsonb_populate_record(null::public.records, '{"id": "00000000-0000-4000-8000-711997164910", "org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "registry_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "created_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|records|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.records (id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at) select id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at from jsonb_populate_record(null::public.records, '{"id": "00000000-0000-4000-8000-674189298514", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|records|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.records (id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at) select id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at from jsonb_populate_record(null::public.records, '{"id": "00000000-0000-4000-8000-828348625705", "org_id": "b0104664-71b0-4297-9d29-942575610100", "registry_id": "b0104664-71b0-4297-9d29-942575610100", "created_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|records|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.records (id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at) select id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at from jsonb_populate_record(null::public.records, '{"id": "00000000-0000-4000-8000-866156492101", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|records|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.records (id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at) select id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at from jsonb_populate_record(null::public.records, '{"id": "00000000-0000-4000-8000-509679398754", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|records|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.records (id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at) select id,org_id,registry_id,ref_number,title,details,archived,created_by,created_at,updated_at from jsonb_populate_record(null::public.records, '{"id": "00000000-0000-4000-8000-526222286466", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|register_templates|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{"key": "improvement", "kind": "tasks", "name": "Continuous Improvement Register", "fields": [{"key": "source", "type": "choice", "label": "Source of feedback", "options": ["Participant", "Family or carer", "Staff", "Audit", "Incident", "Complaint", "Other"]}, {"key": "standards", "type": "multi_choice", "label": "Relevant standards", "options": ["Rights and responsibilities", "Governance and operational management", "Provision of supports", "Support provision environment"]}], "prefix": "CIR", "settings": {"title_label": "Task title", "review_label": "Review date", "show_outcome": true, "outcome_label": "Actions taken", "outcome_required": true, "show_review_date": true, "description_label": "Description", "requires_approval": false}, "sort_order": 70, "description": "Improvements to how the organisation works."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|register_templates|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|register_templates|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|register_templates|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{"key": "improvement", "kind": "tasks", "name": "Continuous Improvement Register", "fields": [{"key": "source", "type": "choice", "label": "Source of feedback", "options": ["Participant", "Family or carer", "Staff", "Audit", "Incident", "Complaint", "Other"]}, {"key": "standards", "type": "multi_choice", "label": "Relevant standards", "options": ["Rights and responsibilities", "Governance and operational management", "Provision of supports", "Support provision environment"]}], "prefix": "CIR", "settings": {"title_label": "Task title", "review_label": "Review date", "show_outcome": true, "outcome_label": "Actions taken", "outcome_required": true, "show_review_date": true, "description_label": "Description", "requires_approval": false}, "sort_order": 70, "description": "Improvements to how the organisation works."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|register_templates|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|register_templates|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|register_templates|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{"key": "improvement", "kind": "tasks", "name": "Continuous Improvement Register", "fields": [{"key": "source", "type": "choice", "label": "Source of feedback", "options": ["Participant", "Family or carer", "Staff", "Audit", "Incident", "Complaint", "Other"]}, {"key": "standards", "type": "multi_choice", "label": "Relevant standards", "options": ["Rights and responsibilities", "Governance and operational management", "Provision of supports", "Support provision environment"]}], "prefix": "CIR", "settings": {"title_label": "Task title", "review_label": "Review date", "show_outcome": true, "outcome_label": "Actions taken", "outcome_required": true, "show_review_date": true, "description_label": "Description", "requires_approval": false}, "sort_order": 70, "description": "Improvements to how the organisation works."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|register_templates|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|register_templates|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|register_templates|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{"key": "improvement", "kind": "tasks", "name": "Continuous Improvement Register", "fields": [{"key": "source", "type": "choice", "label": "Source of feedback", "options": ["Participant", "Family or carer", "Staff", "Audit", "Incident", "Complaint", "Other"]}, {"key": "standards", "type": "multi_choice", "label": "Relevant standards", "options": ["Rights and responsibilities", "Governance and operational management", "Provision of supports", "Support provision environment"]}], "prefix": "CIR", "settings": {"title_label": "Task title", "review_label": "Review date", "show_outcome": true, "outcome_label": "Actions taken", "outcome_required": true, "show_review_date": true, "description_label": "Description", "requires_approval": false}, "sort_order": 70, "description": "Improvements to how the organisation works."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|register_templates|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|register_templates|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|register_templates|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{"key": "improvement", "kind": "tasks", "name": "Continuous Improvement Register", "fields": [{"key": "source", "type": "choice", "label": "Source of feedback", "options": ["Participant", "Family or carer", "Staff", "Audit", "Incident", "Complaint", "Other"]}, {"key": "standards", "type": "multi_choice", "label": "Relevant standards", "options": ["Rights and responsibilities", "Governance and operational management", "Provision of supports", "Support provision environment"]}], "prefix": "CIR", "settings": {"title_label": "Task title", "review_label": "Review date", "show_outcome": true, "outcome_label": "Actions taken", "outcome_required": true, "show_review_date": true, "description_label": "Description", "requires_approval": false}, "sort_order": 70, "description": "Improvements to how the organisation works."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|register_templates|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|register_templates|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|register_templates|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{"key": "improvement", "kind": "tasks", "name": "Continuous Improvement Register", "fields": [{"key": "source", "type": "choice", "label": "Source of feedback", "options": ["Participant", "Family or carer", "Staff", "Audit", "Incident", "Complaint", "Other"]}, {"key": "standards", "type": "multi_choice", "label": "Relevant standards", "options": ["Rights and responsibilities", "Governance and operational management", "Provision of supports", "Support provision environment"]}], "prefix": "CIR", "settings": {"title_label": "Task title", "review_label": "Review date", "show_outcome": true, "outcome_label": "Actions taken", "outcome_required": true, "show_review_date": true, "description_label": "Description", "requires_approval": false}, "sort_order": 70, "description": "Improvements to how the organisation works."}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|register_templates|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|register_templates|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.register_templates (key,name,prefix,description,kind,settings,fields,sort_order) select key,name,prefix,description,kind,settings,fields,sort_order from jsonb_populate_record(null::public.register_templates, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|registries|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-944402732896", "kind": "tasks", "name": "Risk Management Register", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "prefix": "RSK", "sla_days": null, "created_at": "2026-11-09T02:09:38.634806+00:00", "created_by": null, "is_default": false, "sort_order": 20, "description": "Identified risks, their rating and how they are reduced.", "next_number": 2, "title_label": "Task title", "cleared_only": false, "create_roles": [], "review_label": "Review date", "show_outcome": true, "outcome_label": "Risk reduction strategies", "show_due_date": true, "outcome_required": true, "show_review_date": true, "description_label": "Risk description", "requires_approval": true}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|registries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-225481673589", "org_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|registries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-195310560935", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|registries|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-388846250343", "kind": "tasks", "name": "Risk Management Register", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "prefix": "RSK", "sla_days": null, "created_at": "2026-11-09T02:09:38.634806+00:00", "created_by": null, "is_default": false, "sort_order": 20, "description": "Identified risks, their rating and how they are reduced.", "next_number": 2, "title_label": "Task title", "cleared_only": false, "create_roles": [], "review_label": "Review date", "show_outcome": true, "outcome_label": "Risk reduction strategies", "show_due_date": true, "outcome_required": true, "show_review_date": true, "description_label": "Risk description", "requires_approval": true}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|registries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-270095800003", "org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|registries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-520922790432", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|registries|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-114024313132", "kind": "tasks", "name": "Risk Management Register", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "prefix": "RSK", "sla_days": null, "created_at": "2026-11-09T02:09:38.634806+00:00", "created_by": null, "is_default": false, "sort_order": 20, "description": "Identified risks, their rating and how they are reduced.", "next_number": 2, "title_label": "Task title", "cleared_only": false, "create_roles": [], "review_label": "Review date", "show_outcome": true, "outcome_label": "Risk reduction strategies", "show_due_date": true, "outcome_required": true, "show_review_date": true, "description_label": "Risk description", "requires_approval": true}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|registries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-457950420016", "org_id": "1028b402-8a12-467c-adcf-2f1269268df7", "created_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|registries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-420142553620", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|registries|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-845240736192", "kind": "tasks", "name": "Risk Management Register", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "prefix": "RSK", "sla_days": null, "created_at": "2026-11-09T02:09:38.634806+00:00", "created_by": null, "is_default": false, "sort_order": 20, "description": "Identified risks, their rating and how they are reduced.", "next_number": 2, "title_label": "Task title", "cleared_only": false, "create_roles": [], "review_label": "Review date", "show_outcome": true, "outcome_label": "Risk reduction strategies", "show_due_date": true, "outcome_required": true, "show_review_date": true, "description_label": "Risk description", "requires_approval": true}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|registries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-346975554660", "org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "created_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|registries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-096148564231", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|registries|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-385586526807", "kind": "tasks", "name": "Risk Management Register", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "prefix": "RSK", "sla_days": null, "created_at": "2026-11-09T02:09:38.634806+00:00", "created_by": null, "is_default": false, "sort_order": 20, "description": "Identified risks, their rating and how they are reduced.", "next_number": 2, "title_label": "Task title", "cleared_only": false, "create_roles": [], "review_label": "Review date", "show_outcome": true, "outcome_label": "Risk reduction strategies", "show_due_date": true, "outcome_required": true, "show_review_date": true, "description_label": "Risk description", "requires_approval": true}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|registries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-598686488450", "org_id": "b0104664-71b0-4297-9d29-942575610100", "created_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|registries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-636494354846", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|registries|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-568212666111", "kind": "tasks", "name": "Risk Management Register", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "prefix": "RSK", "sla_days": null, "created_at": "2026-11-09T02:09:38.634806+00:00", "created_by": null, "is_default": false, "sort_order": 20, "description": "Identified risks, their rating and how they are reduced.", "next_number": 2, "title_label": "Task title", "cleared_only": false, "create_roles": [], "review_label": "Review date", "show_outcome": true, "outcome_label": "Risk reduction strategies", "show_due_date": true, "outcome_required": true, "show_review_date": true, "description_label": "Risk description", "requires_approval": true}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|registries|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-069947484579", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|registries|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.registries (id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only) select id,org_id,name,description,requires_approval,active,sort_order,created_at,kind,prefix,next_number,description_label,title_label,show_due_date,show_review_date,review_label,show_outcome,outcome_label,is_default,created_by,sla_days,outcome_required,create_roles,cleared_only from jsonb_populate_record(null::public.registries, '{"id": "00000000-0000-4000-8000-107755350975", "org_id": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|registry_fields|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-368069259166", "key": "investigation", "help": "", "type": "long_text", "label": "Detailed investigation", "active": true, "options": [], "required": false, "created_at": "2026-11-09T02:09:38.645967+00:00", "sort_order": 30, "registry_id": "e560526c-8fff-4808-b519-63df0940e57f", "option_colors": {}}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|registry_fields|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-535755885965", "registry_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|registry_fields|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-573563752361", "registry_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|registry_fields|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-174583486509", "key": "investigation", "help": "", "type": "long_text", "label": "Detailed investigation", "active": true, "options": [], "required": false, "created_at": "2026-11-09T02:09:38.645967+00:00", "sort_order": 30, "registry_id": "e560526c-8fff-4808-b519-63df0940e57f", "option_colors": {}}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|registry_fields|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-612316551848", "registry_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|registry_fields|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-425491314548", "registry_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|registry_fields|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-917272586687", "key": "investigation", "help": "", "type": "long_text", "label": "Detailed investigation", "active": true, "options": [], "required": false, "created_at": "2026-11-09T02:09:38.645967+00:00", "sort_order": 30, "registry_id": "e560526c-8fff-4808-b519-63df0940e57f", "option_colors": {}}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|registry_fields|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-130372548330", "registry_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|registry_fields|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-168180414726", "registry_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|registry_fields|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-454969301652", "key": "investigation", "help": "", "type": "long_text", "label": "Detailed investigation", "active": true, "options": [], "required": false, "created_at": "2026-11-09T02:09:38.645967+00:00", "sort_order": 30, "registry_id": "e560526c-8fff-4808-b519-63df0940e57f", "option_colors": {}}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|registry_fields|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-953234483184", "registry_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|registry_fields|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-084573383212", "registry_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|registry_fields|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-099800056463", "key": "investigation", "help": "", "type": "long_text", "label": "Detailed investigation", "active": true, "options": [], "required": false, "created_at": "2026-11-09T02:09:38.645967+00:00", "sort_order": 30, "registry_id": "e560526c-8fff-4808-b519-63df0940e57f", "option_colors": {}}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|registry_fields|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-401934762005", "registry_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|registry_fields|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-848892228424", "registry_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|registry_fields|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-556637485092", "key": "investigation", "help": "", "type": "long_text", "label": "Detailed investigation", "active": true, "options": [], "required": false, "created_at": "2026-11-09T02:09:38.645967+00:00", "sort_order": 30, "registry_id": "e560526c-8fff-4808-b519-63df0940e57f", "option_colors": {}}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|registry_fields|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-230262553265", "registry_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|registry_fields|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.registry_fields (id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors) select id,registry_id,key,label,type,required,options,help,sort_order,active,created_at,option_colors from jsonb_populate_record(null::public.registry_fields, '{"id": "00000000-0000-4000-8000-192454686869", "registry_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|registry_managers|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_managers (registry_id,user_id) select registry_id,user_id from jsonb_populate_record(null::public.registry_managers, '{"registry_id": "00000000-0000-4000-8000-213819764889", "user_id": "00000000-0000-4000-8000-213819764889"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|registry_managers|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_managers (registry_id,user_id) select registry_id,user_id from jsonb_populate_record(null::public.registry_managers, '{"registry_id": "00000000-0000-4000-8000-176011898493", "user_id": "00000000-0000-4000-8000-176011898493"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|registry_managers|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_managers (registry_id,user_id) select registry_id,user_id from jsonb_populate_record(null::public.registry_managers, '{"registry_id": "00000000-0000-4000-8000-258433891303", "user_id": "00000000-0000-4000-8000-258433891303"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|registry_managers|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_managers (registry_id,user_id) select registry_id,user_id from jsonb_populate_record(null::public.registry_managers, '{"registry_id": "00000000-0000-4000-8000-509260881732", "user_id": "00000000-0000-4000-8000-509260881732"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|registry_managers|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_managers (registry_id,user_id) select registry_id,user_id from jsonb_populate_record(null::public.registry_managers, '{"registry_id": "00000000-0000-4000-8000-446288511316", "user_id": "00000000-0000-4000-8000-446288511316"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|registry_managers|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_managers (registry_id,user_id) select registry_id,user_id from jsonb_populate_record(null::public.registry_managers, '{"registry_id": "00000000-0000-4000-8000-408480644920", "user_id": "00000000-0000-4000-8000-408480644920"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|registry_managers|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_managers (registry_id,user_id) select registry_id,user_id from jsonb_populate_record(null::public.registry_managers, '{"registry_id": "00000000-0000-4000-8000-160829640658", "user_id": "00000000-0000-4000-8000-160829640658"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|registry_managers|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_managers (registry_id,user_id) select registry_id,user_id from jsonb_populate_record(null::public.registry_managers, '{"registry_id": "00000000-0000-4000-8000-089997349771", "user_id": "00000000-0000-4000-8000-089997349771"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|registry_managers|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_managers (registry_id,user_id) select registry_id,user_id from jsonb_populate_record(null::public.registry_managers, '{"registry_id": "00000000-0000-4000-8000-227364029022", "user_id": "00000000-0000-4000-8000-227364029022"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|registry_managers|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.registry_managers (registry_id,user_id) select registry_id,user_id from jsonb_populate_record(null::public.registry_managers, '{"registry_id": "00000000-0000-4000-8000-265171895418", "user_id": "00000000-0000-4000-8000-265171895418"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|registry_managers|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.registry_managers (registry_id,user_id) select registry_id,user_id from jsonb_populate_record(null::public.registry_managers, '{"registry_id": "00000000-0000-4000-8000-074187715422", "user_id": "00000000-0000-4000-8000-074187715422"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|registry_managers|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.registry_managers (registry_id,user_id) select registry_id,user_id from jsonb_populate_record(null::public.registry_managers, '{"registry_id": "00000000-0000-4000-8000-942030337723", "user_id": "00000000-0000-4000-8000-942030337723"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|request_events|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"id": 1, "type": "submitted", "actor": "b0104664-71b0-4297-9d29-942575610100", "comment": "", "created_at": "2026-11-09T02:33:31.631715+00:00", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|request_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"request_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "actor": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|request_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"request_id": "11111111-1111-4111-8111-111111111111", "actor": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|request_events|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"id": 1, "type": "submitted", "actor": "b0104664-71b0-4297-9d29-942575610100", "comment": "", "created_at": "2026-11-09T02:33:31.631715+00:00", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|request_events|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"id": 3, "type": "approved", "actor": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "comment": "", "created_at": "2026-11-09T02:33:42.42504+00:00", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|request_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"request_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "actor": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|request_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"request_id": "11111111-1111-4111-8111-111111111111", "actor": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|request_events|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"id": 1, "type": "submitted", "actor": "b0104664-71b0-4297-9d29-942575610100", "comment": "", "created_at": "2026-11-09T02:33:31.631715+00:00", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|request_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"request_id": "1028b402-8a12-467c-adcf-2f1269268df7", "actor": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|request_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"request_id": "11111111-1111-4111-8111-111111111111", "actor": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|request_events|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"id": 1, "type": "submitted", "actor": "b0104664-71b0-4297-9d29-942575610100", "comment": "", "created_at": "2026-11-09T02:33:31.631715+00:00", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|request_events|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"id": 2, "type": "approved_first", "actor": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "comment": "", "created_at": "2026-11-09T02:33:36.560074+00:00", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|request_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"request_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "actor": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|request_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"request_id": "11111111-1111-4111-8111-111111111111", "actor": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|request_events|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"id": 1, "type": "submitted", "actor": "b0104664-71b0-4297-9d29-942575610100", "comment": "", "created_at": "2026-11-09T02:33:31.631715+00:00", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|request_events|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"id": 1, "type": "submitted", "actor": "b0104664-71b0-4297-9d29-942575610100", "comment": "", "created_at": "2026-11-09T02:33:31.631715+00:00", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|request_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"request_id": "b0104664-71b0-4297-9d29-942575610100", "actor": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|request_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"request_id": "11111111-1111-4111-8111-111111111111", "actor": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|request_events|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"id": 1, "type": "submitted", "actor": "b0104664-71b0-4297-9d29-942575610100", "comment": "", "created_at": "2026-11-09T02:33:31.631715+00:00", "request_id": "b3bd529a-be7b-4e7c-b370-de25d6739434"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|request_events|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"request_id": "11111111-1111-4111-8111-111111111111", "actor": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|request_events|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.request_events (request_id,actor,type,comment,created_at) select request_id,actor,type,comment,created_at from jsonb_populate_record(null::public.request_events, '{"request_id": "11111111-1111-4111-8111-111111111111", "actor": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|request_types|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{"key": "hr", "label": "HR or employment enquiry", "notify": [], "sort_order": 60, "escalate_to": ["manager"], "feature_key": "hr_req_hr", "escalate_days": 3, "first_approvers": ["staff_admin"], "second_approvers": ["manager"]}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|request_types|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|request_types|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|request_types|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{"key": "hr", "label": "HR or employment enquiry", "notify": [], "sort_order": 60, "escalate_to": ["manager"], "feature_key": "hr_req_hr", "escalate_days": 3, "first_approvers": ["staff_admin"], "second_approvers": ["manager"]}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|request_types|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|request_types|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|request_types|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{"key": "hr", "label": "HR or employment enquiry", "notify": [], "sort_order": 60, "escalate_to": ["manager"], "feature_key": "hr_req_hr", "escalate_days": 3, "first_approvers": ["staff_admin"], "second_approvers": ["manager"]}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|request_types|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|request_types|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|request_types|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{"key": "hr", "label": "HR or employment enquiry", "notify": [], "sort_order": 60, "escalate_to": ["manager"], "feature_key": "hr_req_hr", "escalate_days": 3, "first_approvers": ["staff_admin"], "second_approvers": ["manager"]}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|request_types|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|request_types|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|request_types|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{"key": "hr", "label": "HR or employment enquiry", "notify": [], "sort_order": 60, "escalate_to": ["manager"], "feature_key": "hr_req_hr", "escalate_days": 3, "first_approvers": ["staff_admin"], "second_approvers": ["manager"]}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|request_types|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|request_types|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|request_types|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{"key": "hr", "label": "HR or employment enquiry", "notify": [], "sort_order": 60, "escalate_to": ["manager"], "feature_key": "hr_req_hr", "escalate_days": 3, "first_approvers": ["staff_admin"], "second_approvers": ["manager"]}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|request_types|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|request_types|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.request_types (key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order) select key,label,feature_key,first_approvers,second_approvers,notify,escalate_days,escalate_to,sort_order from jsonb_populate_record(null::public.request_types, '{}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|requests|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-249537896482", "type": "leave", "stage": 2, "status": "approved", "details": {"reason": "", "part_day": false, "leave_type": "long_service"}, "subject": "Long service leave 2026-12-22 to 2026-12-24", "end_date": "2026-12-24", "requester": "b0104664-71b0-4297-9d29-942575610100", "swap_with": null, "created_at": "2026-11-09T02:33:31.631715+00:00", "decided_at": "2026-11-09T02:33:42.42504+00:00", "partner_ok": null, "ref_number": 1, "start_date": "2026-12-22", "updated_at": "2026-11-09T02:33:42.42504+00:00", "escalated_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|requests|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-036437934839", "requester": "0a29bd38-850f-4222-b674-d080fe462c2a", "swap_with": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|requests|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-998630068443", "requester": "11111111-1111-4111-8111-111111111111", "swap_with": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|requests|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-397610334295", "type": "leave", "stage": 2, "status": "approved", "details": {"reason": "", "part_day": false, "leave_type": "long_service"}, "subject": "Long service leave 2026-12-22 to 2026-12-24", "end_date": "2026-12-24", "requester": "b0104664-71b0-4297-9d29-942575610100", "swap_with": null, "created_at": "2026-11-09T02:33:31.631715+00:00", "decided_at": "2026-11-09T02:33:42.42504+00:00", "partner_ok": null, "ref_number": 1, "start_date": "2026-12-22", "updated_at": "2026-11-09T02:33:42.42504+00:00", "escalated_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|requests|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-506214810836", "requester": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "swap_with": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|requests|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-544022677232", "requester": "11111111-1111-4111-8111-111111111111", "swap_with": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|requests|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-303068051882", "type": "leave", "stage": 2, "status": "approved", "details": {"reason": "", "part_day": false, "leave_type": "long_service"}, "subject": "Long service leave 2026-12-22 to 2026-12-24", "end_date": "2026-12-24", "requester": "b0104664-71b0-4297-9d29-942575610100", "swap_with": null, "created_at": "2026-11-09T02:33:31.631715+00:00", "decided_at": "2026-11-09T02:33:42.42504+00:00", "partner_ok": null, "ref_number": 1, "start_date": "2026-12-22", "updated_at": "2026-11-09T02:33:42.42504+00:00", "escalated_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|requests|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-421818502222", "requester": "1028b402-8a12-467c-adcf-2f1269268df7", "swap_with": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|requests|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-553975879921", "requester": "11111111-1111-4111-8111-111111111111", "swap_with": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|requests|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-163523347760", "type": "leave", "stage": 2, "status": "approved", "details": {"reason": "", "part_day": false, "leave_type": "long_service"}, "subject": "Long service leave 2026-12-22 to 2026-12-24", "end_date": "2026-12-24", "requester": "b0104664-71b0-4297-9d29-942575610100", "swap_with": null, "created_at": "2026-11-09T02:33:31.631715+00:00", "decided_at": "2026-11-09T02:33:42.42504+00:00", "partner_ok": null, "ref_number": 1, "start_date": "2026-12-22", "updated_at": "2026-11-09T02:33:42.42504+00:00", "escalated_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|requests|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-950423386117", "requester": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "swap_with": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|requests|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-912615519721", "requester": "11111111-1111-4111-8111-111111111111", "swap_with": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|requests|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-911812413970", "type": "leave", "stage": 2, "status": "approved", "details": {"reason": "", "part_day": false, "leave_type": "long_service"}, "subject": "Long service leave 2026-12-22 to 2026-12-24", "end_date": "2026-12-24", "requester": "b0104664-71b0-4297-9d29-942575610100", "swap_with": null, "created_at": "2026-11-09T02:33:31.631715+00:00", "decided_at": "2026-11-09T02:33:42.42504+00:00", "partner_ok": null, "ref_number": 1, "start_date": "2026-12-22", "updated_at": "2026-11-09T02:33:42.42504+00:00", "escalated_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|requests|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-325038903204", "type": "leave", "stage": 2, "status": "approved", "details": {"reason": "", "part_day": false, "leave_type": "long_service"}, "subject": "Long service leave 2026-12-22 to 2026-12-24", "end_date": "2026-12-24", "requester": "b0104664-71b0-4297-9d29-942575610100", "swap_with": null, "created_at": "2026-11-09T02:33:31.631715+00:00", "decided_at": "2026-11-09T02:33:42.42504+00:00", "partner_ok": null, "ref_number": 1, "start_date": "2026-12-22", "updated_at": "2026-11-09T02:33:42.42504+00:00", "escalated_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|requests|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-793061963630", "requester": "b0104664-71b0-4297-9d29-942575610100", "swap_with": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|requests|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-043888954059", "requester": "11111111-1111-4111-8111-111111111111", "swap_with": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|requests|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-015556335712", "type": "leave", "stage": 2, "status": "approved", "details": {"reason": "", "part_day": false, "leave_type": "long_service"}, "subject": "Long service leave 2026-12-22 to 2026-12-24", "end_date": "2026-12-24", "requester": "b0104664-71b0-4297-9d29-942575610100", "swap_with": null, "created_at": "2026-11-09T02:33:31.631715+00:00", "decided_at": "2026-11-09T02:33:42.42504+00:00", "partner_ok": null, "ref_number": 1, "start_date": "2026-12-22", "updated_at": "2026-11-09T02:33:42.42504+00:00", "escalated_at": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|requests|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-888268809419", "requester": "11111111-1111-4111-8111-111111111111", "swap_with": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|requests|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.requests (id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at) select id,type,requester,status,stage,subject,details,start_date,end_date,swap_with,partner_ok,escalated_at,created_at,updated_at,decided_at from jsonb_populate_record(null::public.requests, '{"id": "00000000-0000-4000-8000-926076675815", "requester": "11111111-1111-4111-8111-111111111111", "swap_with": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|settings_drafts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.settings_drafts (kind,key,value,saved_by,saved_at) select kind,key,value,saved_by,saved_at from jsonb_populate_record(null::public.settings_drafts, '{"saved_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|settings_drafts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.settings_drafts (kind,key,value,saved_by,saved_at) select kind,key,value,saved_by,saved_at from jsonb_populate_record(null::public.settings_drafts, '{"saved_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|settings_drafts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.settings_drafts (kind,key,value,saved_by,saved_at) select kind,key,value,saved_by,saved_at from jsonb_populate_record(null::public.settings_drafts, '{"saved_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|settings_drafts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.settings_drafts (kind,key,value,saved_by,saved_at) select kind,key,value,saved_by,saved_at from jsonb_populate_record(null::public.settings_drafts, '{"saved_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|settings_drafts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.settings_drafts (kind,key,value,saved_by,saved_at) select kind,key,value,saved_by,saved_at from jsonb_populate_record(null::public.settings_drafts, '{"saved_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|settings_drafts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.settings_drafts (kind,key,value,saved_by,saved_at) select kind,key,value,saved_by,saved_at from jsonb_populate_record(null::public.settings_drafts, '{"saved_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|settings_drafts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.settings_drafts (kind,key,value,saved_by,saved_at) select kind,key,value,saved_by,saved_at from jsonb_populate_record(null::public.settings_drafts, '{"saved_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|settings_drafts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.settings_drafts (kind,key,value,saved_by,saved_at) select kind,key,value,saved_by,saved_at from jsonb_populate_record(null::public.settings_drafts, '{"saved_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|settings_drafts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.settings_drafts (kind,key,value,saved_by,saved_at) select kind,key,value,saved_by,saved_at from jsonb_populate_record(null::public.settings_drafts, '{"saved_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|settings_drafts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.settings_drafts (kind,key,value,saved_by,saved_at) select kind,key,value,saved_by,saved_at from jsonb_populate_record(null::public.settings_drafts, '{"saved_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|settings_drafts|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.settings_drafts (kind,key,value,saved_by,saved_at) select kind,key,value,saved_by,saved_at from jsonb_populate_record(null::public.settings_drafts, '{"saved_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|settings_drafts|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.settings_drafts (kind,key,value,saved_by,saved_at) select kind,key,value,saved_by,saved_at from jsonb_populate_record(null::public.settings_drafts, '{"saved_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|shift_changes|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.shift_changes (user_id,request_id,on_date,change,created_at) select user_id,request_id,on_date,change,created_at from jsonb_populate_record(null::public.shift_changes, '{"user_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "request_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|shift_changes|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.shift_changes (user_id,request_id,on_date,change,created_at) select user_id,request_id,on_date,change,created_at from jsonb_populate_record(null::public.shift_changes, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|shift_changes|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.shift_changes (user_id,request_id,on_date,change,created_at) select user_id,request_id,on_date,change,created_at from jsonb_populate_record(null::public.shift_changes, '{"user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "request_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|shift_changes|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.shift_changes (user_id,request_id,on_date,change,created_at) select user_id,request_id,on_date,change,created_at from jsonb_populate_record(null::public.shift_changes, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|shift_changes|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.shift_changes (user_id,request_id,on_date,change,created_at) select user_id,request_id,on_date,change,created_at from jsonb_populate_record(null::public.shift_changes, '{"user_id": "1028b402-8a12-467c-adcf-2f1269268df7", "request_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|shift_changes|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.shift_changes (user_id,request_id,on_date,change,created_at) select user_id,request_id,on_date,change,created_at from jsonb_populate_record(null::public.shift_changes, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|shift_changes|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.shift_changes (user_id,request_id,on_date,change,created_at) select user_id,request_id,on_date,change,created_at from jsonb_populate_record(null::public.shift_changes, '{"user_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "request_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|shift_changes|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.shift_changes (user_id,request_id,on_date,change,created_at) select user_id,request_id,on_date,change,created_at from jsonb_populate_record(null::public.shift_changes, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|shift_changes|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.shift_changes (user_id,request_id,on_date,change,created_at) select user_id,request_id,on_date,change,created_at from jsonb_populate_record(null::public.shift_changes, '{"user_id": "b0104664-71b0-4297-9d29-942575610100", "request_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|shift_changes|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.shift_changes (user_id,request_id,on_date,change,created_at) select user_id,request_id,on_date,change,created_at from jsonb_populate_record(null::public.shift_changes, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|shift_changes|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.shift_changes (user_id,request_id,on_date,change,created_at) select user_id,request_id,on_date,change,created_at from jsonb_populate_record(null::public.shift_changes, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|shift_changes|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.shift_changes (user_id,request_id,on_date,change,created_at) select user_id,request_id,on_date,change,created_at from jsonb_populate_record(null::public.shift_changes, '{"user_id": "11111111-1111-4111-8111-111111111111", "request_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|staff_directory|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"skills": ["Driver''s licence", "First Aid"], "user_id": "00000000-0000-4000-8000-578416283046", "department": "", "updated_at": "2026-11-09T02:18:25.569056+00:00", "work_phone": "0400 111 222", "preferred_name": "Sammy"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|staff_directory|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"user_id": "00000000-0000-4000-8000-080151101514"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|staff_directory|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"user_id": "00000000-0000-4000-8000-955750583706"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|staff_directory|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"skills": ["Driver''s licence", "First Aid"], "user_id": "00000000-0000-4000-8000-952640522895", "department": "", "updated_at": "2026-11-09T02:18:25.569056+00:00", "work_phone": "0400 111 222", "preferred_name": "Sammy"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|staff_directory|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"skills": [], "user_id": "00000000-0000-4000-8000-305752212824", "department": "", "updated_at": "2026-11-09T02:52:48.455877+00:00", "work_phone": "+61 412 345 678", "preferred_name": ""}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|staff_directory|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"user_id": "00000000-0000-4000-8000-450905704427"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|staff_directory|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"user_id": "00000000-0000-4000-8000-586902161969"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|staff_directory|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"skills": ["Driver''s licence", "First Aid"], "user_id": "00000000-0000-4000-8000-612041749380", "department": "", "updated_at": "2026-11-09T02:18:25.569056+00:00", "work_phone": "0400 111 222", "preferred_name": "Sammy"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|staff_directory|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"user_id": "00000000-0000-4000-8000-291783395751"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|staff_directory|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"user_id": "00000000-0000-4000-8000-329591262147"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|staff_directory|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"skills": ["Driver''s licence", "First Aid"], "user_id": "00000000-0000-4000-8000-293558454231", "department": "", "updated_at": "2026-11-09T02:18:25.569056+00:00", "work_phone": "0400 111 222", "preferred_name": "Sammy"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|staff_directory|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"skills": [], "user_id": "00000000-0000-4000-8000-035165718512", "department": "", "updated_at": "2026-11-09T03:42:46.49641+00:00", "work_phone": "+61 2 9876 5432", "preferred_name": ""}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|staff_directory|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"user_id": "00000000-0000-4000-8000-791823635763"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|staff_directory|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"user_id": "00000000-0000-4000-8000-754015769367"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|staff_directory|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"skills": ["Driver''s licence", "First Aid"], "user_id": "00000000-0000-4000-8000-753212663616", "department": "", "updated_at": "2026-11-09T02:18:25.569056+00:00", "work_phone": "0400 111 222", "preferred_name": "Sammy"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|staff_directory|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"skills": ["Driver''s licence", "First Aid"], "user_id": "00000000-0000-4000-8000-166439152850", "department": "", "updated_at": "2026-11-09T02:18:25.569056+00:00", "work_phone": "0400 111 222", "preferred_name": "Sammy"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|staff_directory|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"user_id": "00000000-0000-4000-8000-150612481515"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|staff_directory|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"user_id": "00000000-0000-4000-8000-885289203705"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|staff_directory|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"skills": ["Driver''s licence", "First Aid"], "user_id": "00000000-0000-4000-8000-281951667487", "department": "", "updated_at": "2026-11-09T02:18:25.569056+00:00", "work_phone": "0400 111 222", "preferred_name": "Sammy"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|staff_directory|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"user_id": "00000000-0000-4000-8000-068851705844"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|staff_directory|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.staff_directory (user_id,preferred_name,department,work_phone,skills,updated_at) select user_id,preferred_name,department,work_phone,skills,updated_at from jsonb_populate_record(null::public.staff_directory, '{"user_id": "00000000-0000-4000-8000-031043839448"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|staff_private|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"address": "", "user_id": "00000000-0000-4000-8000-705775981063", "start_date": null, "updated_at": "2026-11-09T02:18:25.569056+00:00", "employee_id": "", "availability": {"fri": [], "mon": ["am"], "sat": [], "sun": [], "thu": [], "tue": [], "wed": []}, "emergency_name": "", "emergency_phone": "", "employment_type": ""}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|staff_private|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"user_id": "00000000-0000-4000-8000-918875942706"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|staff_private|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"user_id": "00000000-0000-4000-8000-956683809102"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|staff_private|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"address": "", "user_id": "00000000-0000-4000-8000-372526997824", "start_date": null, "updated_at": "2026-11-09T02:18:25.569056+00:00", "employee_id": "", "availability": {"fri": [], "mon": ["am"], "sat": [], "sun": [], "thu": [], "tue": [], "wed": []}, "emergency_name": "", "emergency_phone": "", "employment_type": ""}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|staff_private|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"address": "", "user_id": "00000000-0000-4000-8000-040699491410", "start_date": null, "updated_at": "2026-11-09T02:52:48.455877+00:00", "employee_id": "", "availability": {"fri": [], "mon": [], "sat": [], "sun": [], "thu": [], "tue": [], "wed": []}, "emergency_name": "Jo Smith (partner)", "emergency_phone": "+61 456 456 456", "employment_type": ""}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|staff_private|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"user_id": "00000000-0000-4000-8000-797357408661"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|staff_private|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"user_id": "00000000-0000-4000-8000-759549542265"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|staff_private|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"address": "", "user_id": "00000000-0000-4000-8000-198311990317", "start_date": null, "updated_at": "2026-11-09T02:18:25.569056+00:00", "employee_id": "", "availability": {"fri": [], "mon": ["am"], "sat": [], "sun": [], "thu": [], "tue": [], "wed": []}, "emergency_name": "", "emergency_phone": "", "employment_type": ""}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|staff_private|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"user_id": "00000000-0000-4000-8000-696577171849"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|staff_private|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"user_id": "00000000-0000-4000-8000-947404162278"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|staff_private|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"address": "", "user_id": "00000000-0000-4000-8000-606613984359", "start_date": null, "updated_at": "2026-11-09T02:18:25.569056+00:00", "employee_id": "", "availability": {"fri": [], "mon": ["am"], "sat": [], "sun": [], "thu": [], "tue": [], "wed": []}, "emergency_name": "", "emergency_phone": "", "employment_type": ""}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|staff_private|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"address": "", "user_id": "00000000-0000-4000-8000-576371863253", "start_date": null, "updated_at": "2026-11-09T03:42:46.49641+00:00", "employee_id": "", "availability": {"fri": [], "mon": [], "sat": [], "sun": [], "thu": [], "tue": [], "wed": []}, "emergency_name": "", "emergency_phone": "", "employment_type": ""}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|staff_private|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"user_id": "00000000-0000-4000-8000-819713946002"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|staff_private|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"user_id": "00000000-0000-4000-8000-857521812398"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|staff_private|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"address": "", "user_id": "00000000-0000-4000-8000-858324918149", "start_date": null, "updated_at": "2026-11-09T02:18:25.569056+00:00", "employee_id": "", "availability": {"fri": [], "mon": ["am"], "sat": [], "sun": [], "thu": [], "tue": [], "wed": []}, "emergency_name": "", "emergency_phone": "", "employment_type": ""}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|staff_private|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"address": "", "user_id": "00000000-0000-4000-8000-733733285740", "start_date": null, "updated_at": "2026-11-09T02:18:25.569056+00:00", "employee_id": "", "availability": {"fri": [], "mon": ["am"], "sat": [], "sun": [], "thu": [], "tue": [], "wed": []}, "emergency_name": "", "emergency_phone": "", "employment_type": ""}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|staff_private|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"user_id": "00000000-0000-4000-8000-713649814999"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|staff_private|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"user_id": "00000000-0000-4000-8000-109232746188"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|staff_private|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"address": "", "user_id": "00000000-0000-4000-8000-754580996407", "start_date": null, "updated_at": "2026-11-09T02:18:25.569056+00:00", "employee_id": "", "availability": {"fri": [], "mon": ["am"], "sat": [], "sun": [], "thu": [], "tue": [], "wed": []}, "emergency_name": "", "emergency_phone": "", "employment_type": ""}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|staff_private|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"user_id": "00000000-0000-4000-8000-032319041950"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|staff_private|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.staff_private (user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at) select user_id,address,emergency_name,emergency_phone,start_date,employment_type,employee_id,availability,updated_at from jsonb_populate_record(null::public.staff_private, '{"user_id": "00000000-0000-4000-8000-994511175554"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_alerts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_alerts (task_id,user_id,step,due_date,created_at) select task_id,user_id,step,due_date,created_at from jsonb_populate_record(null::public.task_alerts, '{"task_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "user_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_alerts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_alerts (task_id,user_id,step,due_date,created_at) select task_id,user_id,step,due_date,created_at from jsonb_populate_record(null::public.task_alerts, '{"task_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_alerts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_alerts (task_id,user_id,step,due_date,created_at) select task_id,user_id,step,due_date,created_at from jsonb_populate_record(null::public.task_alerts, '{"task_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_alerts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_alerts (task_id,user_id,step,due_date,created_at) select task_id,user_id,step,due_date,created_at from jsonb_populate_record(null::public.task_alerts, '{"task_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_alerts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_alerts (task_id,user_id,step,due_date,created_at) select task_id,user_id,step,due_date,created_at from jsonb_populate_record(null::public.task_alerts, '{"task_id": "1028b402-8a12-467c-adcf-2f1269268df7", "user_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_alerts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_alerts (task_id,user_id,step,due_date,created_at) select task_id,user_id,step,due_date,created_at from jsonb_populate_record(null::public.task_alerts, '{"task_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|task_alerts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_alerts (task_id,user_id,step,due_date,created_at) select task_id,user_id,step,due_date,created_at from jsonb_populate_record(null::public.task_alerts, '{"task_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "user_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|task_alerts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_alerts (task_id,user_id,step,due_date,created_at) select task_id,user_id,step,due_date,created_at from jsonb_populate_record(null::public.task_alerts, '{"task_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|task_alerts|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_alerts (task_id,user_id,step,due_date,created_at) select task_id,user_id,step,due_date,created_at from jsonb_populate_record(null::public.task_alerts, '{"task_id": "b0104664-71b0-4297-9d29-942575610100", "user_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|task_alerts|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_alerts (task_id,user_id,step,due_date,created_at) select task_id,user_id,step,due_date,created_at from jsonb_populate_record(null::public.task_alerts, '{"task_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|task_alerts|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.task_alerts (task_id,user_id,step,due_date,created_at) select task_id,user_id,step,due_date,created_at from jsonb_populate_record(null::public.task_alerts, '{"task_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|task_alerts|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.task_alerts (task_id,user_id,step,due_date,created_at) select task_id,user_id,step,due_date,created_at from jsonb_populate_record(null::public.task_alerts, '{"task_id": "11111111-1111-4111-8111-111111111111", "user_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_attachments|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_attachments (task_id,file_path,file_name,size_bytes,uploaded_by,created_at) select task_id,file_path,file_name,size_bytes,uploaded_by,created_at from jsonb_populate_record(null::public.task_attachments, '{"task_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "uploaded_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_attachments|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_attachments (task_id,file_path,file_name,size_bytes,uploaded_by,created_at) select task_id,file_path,file_name,size_bytes,uploaded_by,created_at from jsonb_populate_record(null::public.task_attachments, '{"task_id": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_attachments|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_attachments (task_id,file_path,file_name,size_bytes,uploaded_by,created_at) select task_id,file_path,file_name,size_bytes,uploaded_by,created_at from jsonb_populate_record(null::public.task_attachments, '{"task_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "uploaded_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_attachments|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_attachments (task_id,file_path,file_name,size_bytes,uploaded_by,created_at) select task_id,file_path,file_name,size_bytes,uploaded_by,created_at from jsonb_populate_record(null::public.task_attachments, '{"task_id": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_attachments|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_attachments (task_id,file_path,file_name,size_bytes,uploaded_by,created_at) select task_id,file_path,file_name,size_bytes,uploaded_by,created_at from jsonb_populate_record(null::public.task_attachments, '{"task_id": "1028b402-8a12-467c-adcf-2f1269268df7", "uploaded_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_attachments|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_attachments (task_id,file_path,file_name,size_bytes,uploaded_by,created_at) select task_id,file_path,file_name,size_bytes,uploaded_by,created_at from jsonb_populate_record(null::public.task_attachments, '{"task_id": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|task_attachments|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_attachments (task_id,file_path,file_name,size_bytes,uploaded_by,created_at) select task_id,file_path,file_name,size_bytes,uploaded_by,created_at from jsonb_populate_record(null::public.task_attachments, '{"task_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "uploaded_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|task_attachments|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_attachments (task_id,file_path,file_name,size_bytes,uploaded_by,created_at) select task_id,file_path,file_name,size_bytes,uploaded_by,created_at from jsonb_populate_record(null::public.task_attachments, '{"task_id": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|task_attachments|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_attachments (task_id,file_path,file_name,size_bytes,uploaded_by,created_at) select task_id,file_path,file_name,size_bytes,uploaded_by,created_at from jsonb_populate_record(null::public.task_attachments, '{"task_id": "b0104664-71b0-4297-9d29-942575610100", "uploaded_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|task_attachments|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_attachments (task_id,file_path,file_name,size_bytes,uploaded_by,created_at) select task_id,file_path,file_name,size_bytes,uploaded_by,created_at from jsonb_populate_record(null::public.task_attachments, '{"task_id": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|task_attachments|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.task_attachments (task_id,file_path,file_name,size_bytes,uploaded_by,created_at) select task_id,file_path,file_name,size_bytes,uploaded_by,created_at from jsonb_populate_record(null::public.task_attachments, '{"task_id": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|task_attachments|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.task_attachments (task_id,file_path,file_name,size_bytes,uploaded_by,created_at) select task_id,file_path,file_name,size_bytes,uploaded_by,created_at from jsonb_populate_record(null::public.task_attachments, '{"task_id": "11111111-1111-4111-8111-111111111111", "uploaded_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_events|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"id": 3, "type": "created", "comment": null, "task_id": "9587bae8-1758-40b3-9ba4-060b49536c36", "actor_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "to_value": null, "created_at": "2026-11-09T02:10:00.6194+00:00", "from_value": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_events|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"id": 3, "type": "created", "comment": null, "task_id": "9587bae8-1758-40b3-9ba4-060b49536c36", "actor_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "to_value": null, "created_at": "2026-11-09T02:10:00.6194+00:00", "from_value": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"task_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "actor_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"task_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_events|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"id": 3, "type": "created", "comment": null, "task_id": "9587bae8-1758-40b3-9ba4-060b49536c36", "actor_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "to_value": null, "created_at": "2026-11-09T02:10:00.6194+00:00", "from_value": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_events|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"id": 16, "type": "status_changed", "comment": null, "task_id": "a8da6a2e-7883-4b30-b6c9-be292ff8ace4", "actor_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "to_value": "completed", "created_at": "2026-11-09T02:33:46.75674+00:00", "from_value": "awaiting_approval"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"task_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "actor_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"task_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_events|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"id": 3, "type": "created", "comment": null, "task_id": "9587bae8-1758-40b3-9ba4-060b49536c36", "actor_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "to_value": null, "created_at": "2026-11-09T02:10:00.6194+00:00", "from_value": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_events|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"id": 13, "type": "created", "comment": null, "task_id": "f33d304b-c7e1-413d-bebb-1c6ea190223f", "actor_id": null, "to_value": "1028b402-8a12-467c-adcf-2f1269268df7", "created_at": "2026-11-09T02:10:00.6194+00:00", "from_value": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"task_id": "1028b402-8a12-467c-adcf-2f1269268df7", "actor_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"task_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|task_events|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"id": 3, "type": "created", "comment": null, "task_id": "9587bae8-1758-40b3-9ba4-060b49536c36", "actor_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "to_value": null, "created_at": "2026-11-09T02:10:00.6194+00:00", "from_value": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|task_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"task_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "actor_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|task_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"task_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|task_events|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"id": 3, "type": "created", "comment": null, "task_id": "9587bae8-1758-40b3-9ba4-060b49536c36", "actor_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "to_value": null, "created_at": "2026-11-09T02:10:00.6194+00:00", "from_value": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|task_events|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"task_id": "b0104664-71b0-4297-9d29-942575610100", "actor_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|task_events|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"task_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|task_events|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"id": 3, "type": "created", "comment": null, "task_id": "9587bae8-1758-40b3-9ba4-060b49536c36", "actor_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "to_value": null, "created_at": "2026-11-09T02:10:00.6194+00:00", "from_value": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|task_events|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"task_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|task_events|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.task_events (task_id,actor_id,type,from_value,to_value,comment,created_at) select task_id,actor_id,type,from_value,to_value,comment,created_at from jsonb_populate_record(null::public.task_events, '{"task_id": "11111111-1111-4111-8111-111111111111", "actor_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_helpers|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_helpers (task_id,user_id,added_by,added_at) select task_id,user_id,added_by,added_at from jsonb_populate_record(null::public.task_helpers, '{"task_id": "00000000-0000-4000-8000-109211239296", "user_id": "00000000-0000-4000-8000-109211239296", "added_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_helpers|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_helpers (task_id,user_id,added_by,added_at) select task_id,user_id,added_by,added_at from jsonb_populate_record(null::public.task_helpers, '{"task_id": "00000000-0000-4000-8000-071403372900", "user_id": "00000000-0000-4000-8000-071403372900", "added_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_helpers|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_helpers (task_id,user_id,added_by,added_at) select task_id,user_id,added_by,added_at from jsonb_populate_record(null::public.task_helpers, '{"task_id": "00000000-0000-4000-8000-248264960953", "user_id": "00000000-0000-4000-8000-248264960953", "added_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_helpers|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_helpers (task_id,user_id,added_by,added_at) select task_id,user_id,added_by,added_at from jsonb_populate_record(null::public.task_helpers, '{"task_id": "00000000-0000-4000-8000-286072827349", "user_id": "00000000-0000-4000-8000-286072827349", "added_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_helpers|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_helpers (task_id,user_id,added_by,added_at) select task_id,user_id,added_by,added_at from jsonb_populate_record(null::public.task_helpers, '{"task_id": "00000000-0000-4000-8000-349045197765", "user_id": "00000000-0000-4000-8000-349045197765", "added_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_helpers|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_helpers (task_id,user_id,added_by,added_at) select task_id,user_id,added_by,added_at from jsonb_populate_record(null::public.task_helpers, '{"task_id": "00000000-0000-4000-8000-098218207336", "user_id": "00000000-0000-4000-8000-098218207336", "added_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|task_helpers|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_helpers (task_id,user_id,added_by,added_at) select task_id,user_id,added_by,added_at from jsonb_populate_record(null::public.task_helpers, '{"task_id": "00000000-0000-4000-8000-667528492914", "user_id": "00000000-0000-4000-8000-667528492914", "added_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|task_helpers|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_helpers (task_id,user_id,added_by,added_at) select task_id,user_id,added_by,added_at from jsonb_populate_record(null::public.task_helpers, '{"task_id": "00000000-0000-4000-8000-985388824178", "user_id": "00000000-0000-4000-8000-985388824178", "added_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|task_helpers|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_helpers (task_id,user_id,added_by,added_at) select task_id,user_id,added_by,added_at from jsonb_populate_record(null::public.task_helpers, '{"task_id": "00000000-0000-4000-8000-331972554615", "user_id": "00000000-0000-4000-8000-331972554615", "added_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|task_helpers|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_helpers (task_id,user_id,added_by,added_at) select task_id,user_id,added_by,added_at from jsonb_populate_record(null::public.task_helpers, '{"task_id": "00000000-0000-4000-8000-918854435814", "user_id": "00000000-0000-4000-8000-918854435814", "added_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|task_helpers|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.task_helpers (task_id,user_id,added_by,added_at) select task_id,user_id,added_by,added_at from jsonb_populate_record(null::public.task_helpers, '{"task_id": "00000000-0000-4000-8000-815495504962", "user_id": "00000000-0000-4000-8000-815495504962", "added_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|task_helpers|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.task_helpers (task_id,user_id,added_by,added_at) select task_id,user_id,added_by,added_at from jsonb_populate_record(null::public.task_helpers, '{"task_id": "00000000-0000-4000-8000-853303371358", "user_id": "00000000-0000-4000-8000-853303371358", "added_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_views|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"seen_at": "2026-11-09T19:31:24.449719+00:00", "task_id": "00000000-0000-4000-8000-763167041594", "user_id": "00000000-0000-4000-8000-763167041594"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_views|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"seen_at": "2026-11-09T19:31:24.449719+00:00", "task_id": "00000000-0000-4000-8000-650059447640", "user_id": "00000000-0000-4000-8000-650059447640"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_views|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"task_id": "00000000-0000-4000-8000-023732996763", "user_id": "00000000-0000-4000-8000-023732996763"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|task_views|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"task_id": "00000000-0000-4000-8000-014074869633", "user_id": "00000000-0000-4000-8000-014074869633"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_views|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"seen_at": "2026-11-09T19:31:24.449719+00:00", "task_id": "00000000-0000-4000-8000-767889764347", "user_id": "00000000-0000-4000-8000-767889764347"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_views|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"seen_at": "2026-11-09T19:34:29.083745+00:00", "task_id": "00000000-0000-4000-8000-275577666163", "user_id": "00000000-0000-4000-8000-275577666163"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_views|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"task_id": "00000000-0000-4000-8000-518919748912", "user_id": "00000000-0000-4000-8000-518919748912"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|task_views|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"task_id": "00000000-0000-4000-8000-556727615308", "user_id": "00000000-0000-4000-8000-556727615308"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_views|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"seen_at": "2026-11-09T19:31:24.449719+00:00", "task_id": "00000000-0000-4000-8000-642216296041", "user_id": "00000000-0000-4000-8000-642216296041"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_views|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"seen_at": "2026-11-09T19:36:34.706243+00:00", "task_id": "00000000-0000-4000-8000-055442785275", "user_id": "00000000-0000-4000-8000-055442785275"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_views|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"task_id": "00000000-0000-4000-8000-812100702526", "user_id": "00000000-0000-4000-8000-812100702526"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|task_views|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"task_id": "00000000-0000-4000-8000-774292836130", "user_id": "00000000-0000-4000-8000-774292836130"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|task_views|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"seen_at": "2026-11-09T19:31:24.449719+00:00", "task_id": "00000000-0000-4000-8000-676266999108", "user_id": "00000000-0000-4000-8000-676266999108"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|task_views|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"seen_at": "2026-11-09T19:39:03.07051+00:00", "task_id": "00000000-0000-4000-8000-934659734827", "user_id": "00000000-0000-4000-8000-934659734827"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|task_views|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"task_id": "00000000-0000-4000-8000-178001817576", "user_id": "00000000-0000-4000-8000-178001817576"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|task_views|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"task_id": "00000000-0000-4000-8000-215809683972", "user_id": "00000000-0000-4000-8000-215809683972"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|task_views|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"seen_at": "2026-11-09T19:31:24.449719+00:00", "task_id": "00000000-0000-4000-8000-216612789723", "user_id": "00000000-0000-4000-8000-216612789723"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|task_views|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"seen_at": "2026-11-09T19:40:18.147393+00:00", "task_id": "00000000-0000-4000-8000-803386300489", "user_id": "00000000-0000-4000-8000-803386300489"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|task_views|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"task_id": "00000000-0000-4000-8000-953271616762", "user_id": "00000000-0000-4000-8000-953271616762"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|task_views|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"task_id": "00000000-0000-4000-8000-084536249634", "user_id": "00000000-0000-4000-8000-084536249634"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|task_views|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"seen_at": "2026-11-09T19:31:24.449719+00:00", "task_id": "00000000-0000-4000-8000-687873785852", "user_id": "00000000-0000-4000-8000-687873785852"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|task_views|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"task_id": "00000000-0000-4000-8000-900973747495", "user_id": "00000000-0000-4000-8000-900973747495"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|task_views|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.task_views (task_id,user_id,seen_at) select task_id,user_id,seen_at from jsonb_populate_record(null::public.task_views, '{"task_id": "00000000-0000-4000-8000-938781613891", "user_id": "00000000-0000-4000-8000-938781613891"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|tasks|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-845542336568", "title": "Synthetic task 1081", "number": 2598, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "status": "in_progress", "details": {}, "outcome": "", "due_date": "2026-09-11", "priority": "medium", "client_id": null, "closed_at": null, "escalated": false, "created_at": "2026-11-08T21:14:30.544857+00:00", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "ref_number": 1081, "updated_at": "2026-11-09T21:14:30.544857+00:00", "assigned_to": "eda6a162-8814-48dd-aec7-42fd99b2fdb9", "description": "Test only", "registry_id": "9054811f-a52f-47d9-8986-c82383ee7bbe", "review_date": null, "completed_at": null, "escalated_by": null, "escalated_to": null, "date_reported": "2026-11-09", "parent_task_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|tasks|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-875784457674", "title": "Wet floor near the kitchen: risk review", "number": 5, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "status": "assigned", "details": {}, "outcome": "", "due_date": "2026-11-16", "priority": "medium", "client_id": null, "closed_at": null, "escalated": false, "created_at": "2026-11-09T02:10:00.6194+00:00", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a", "ref_number": 1, "updated_at": "2026-11-09T02:10:00.6194+00:00", "assigned_to": "1028b402-8a12-467c-adcf-2f1269268df7", "description": "Slippery after mopping. Review signage and mopping times.", "registry_id": "066f228e-ecab-463c-85ec-6271a8f95413", "review_date": null, "completed_at": null, "escalated_by": null, "escalated_to": null, "date_reported": "2026-11-07", "parent_task_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|tasks|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-632442374925", "org_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "registry_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "assigned_to": "0a29bd38-850f-4222-b674-d080fe462c2a", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a", "parent_task_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "escalated_by": "0a29bd38-850f-4222-b674-d080fe462c2a", "client_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|tasks|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-594634508529", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "assigned_to": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "parent_task_id": "11111111-1111-4111-8111-111111111111", "escalated_by": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|tasks|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-894918231809", "title": "Synthetic task 1081", "number": 2598, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "status": "in_progress", "details": {}, "outcome": "", "due_date": "2026-09-11", "priority": "medium", "client_id": null, "closed_at": null, "escalated": false, "created_at": "2026-11-08T21:14:30.544857+00:00", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "ref_number": 1081, "updated_at": "2026-11-09T21:14:30.544857+00:00", "assigned_to": "eda6a162-8814-48dd-aec7-42fd99b2fdb9", "description": "Test only", "registry_id": "9054811f-a52f-47d9-8986-c82383ee7bbe", "review_date": null, "completed_at": null, "escalated_by": null, "escalated_to": null, "date_reported": "2026-11-09", "parent_task_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|tasks|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-481691742575", "title": "Synthetic task 1081", "number": 2598, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "status": "in_progress", "details": {}, "outcome": "", "due_date": "2026-09-11", "priority": "medium", "client_id": null, "closed_at": null, "escalated": false, "created_at": "2026-11-08T21:14:30.544857+00:00", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "ref_number": 1081, "updated_at": "2026-11-09T21:14:30.544857+00:00", "assigned_to": "eda6a162-8814-48dd-aec7-42fd99b2fdb9", "description": "Test only", "registry_id": "9054811f-a52f-47d9-8986-c82383ee7bbe", "review_date": null, "completed_at": null, "escalated_by": null, "escalated_to": null, "date_reported": "2026-11-09", "parent_task_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|tasks|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-108018193452", "org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "registry_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "assigned_to": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "parent_task_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "escalated_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "client_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|tasks|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-145826059848", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "assigned_to": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "parent_task_id": "11111111-1111-4111-8111-111111111111", "escalated_by": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|tasks|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-250925674203", "title": "Synthetic task 1081", "number": 2598, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "status": "in_progress", "details": {}, "outcome": "", "due_date": "2026-09-11", "priority": "medium", "client_id": null, "closed_at": null, "escalated": false, "created_at": "2026-11-08T21:14:30.544857+00:00", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "ref_number": 1081, "updated_at": "2026-11-09T21:14:30.544857+00:00", "assigned_to": "eda6a162-8814-48dd-aec7-42fd99b2fdb9", "description": "Test only", "registry_id": "9054811f-a52f-47d9-8986-c82383ee7bbe", "review_date": null, "completed_at": null, "escalated_by": null, "escalated_to": null, "date_reported": "2026-11-09", "parent_task_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|tasks|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-409557388179", "title": "Wet floor near the kitchen: risk review", "number": 5, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "status": "assigned", "details": {}, "outcome": "", "due_date": "2026-11-16", "priority": "medium", "client_id": null, "closed_at": null, "escalated": false, "created_at": "2026-11-09T02:10:00.6194+00:00", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a", "ref_number": 1, "updated_at": "2026-11-09T02:10:00.6194+00:00", "assigned_to": "1028b402-8a12-467c-adcf-2f1269268df7", "description": "Slippery after mopping. Review signage and mopping times.", "registry_id": "066f228e-ecab-463c-85ec-6271a8f95413", "review_date": null, "completed_at": null, "escalated_by": null, "escalated_to": null, "date_reported": "2026-11-07", "parent_task_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|tasks|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-749190855735", "org_id": "1028b402-8a12-467c-adcf-2f1269268df7", "registry_id": "1028b402-8a12-467c-adcf-2f1269268df7", "assigned_to": "1028b402-8a12-467c-adcf-2f1269268df7", "created_by": "1028b402-8a12-467c-adcf-2f1269268df7", "parent_task_id": "1028b402-8a12-467c-adcf-2f1269268df7", "escalated_by": "1028b402-8a12-467c-adcf-2f1269268df7", "client_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|tasks|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-000017846164", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "assigned_to": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "parent_task_id": "11111111-1111-4111-8111-111111111111", "escalated_by": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|tasks|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-356192477771", "title": "Synthetic task 1081", "number": 2598, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "status": "in_progress", "details": {}, "outcome": "", "due_date": "2026-09-11", "priority": "medium", "client_id": null, "closed_at": null, "escalated": false, "created_at": "2026-11-08T21:14:30.544857+00:00", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "ref_number": 1081, "updated_at": "2026-11-09T21:14:30.544857+00:00", "assigned_to": "eda6a162-8814-48dd-aec7-42fd99b2fdb9", "description": "Test only", "registry_id": "9054811f-a52f-47d9-8986-c82383ee7bbe", "review_date": null, "completed_at": null, "escalated_by": null, "escalated_to": null, "date_reported": "2026-11-09", "parent_task_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|tasks|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-325950356665", "title": "Client review meeting: plan goals", "number": 11, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "status": "assigned", "details": {}, "outcome": "", "due_date": "2026-11-13", "priority": "high", "client_id": null, "closed_at": null, "escalated": false, "created_at": "2026-11-09T02:10:00.6194+00:00", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a", "ref_number": 8, "updated_at": "2026-11-09T02:10:00.6194+00:00", "assigned_to": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "description": "Prepare notes for the plan review.", "registry_id": "b7544638-7115-45ce-a201-09afbd15473b", "review_date": null, "completed_at": null, "escalated_by": null, "escalated_to": null, "date_reported": "2026-11-07", "parent_task_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|tasks|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-430707560586", "org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "registry_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "assigned_to": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "created_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "parent_task_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "escalated_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "client_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|tasks|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-607100305810", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "assigned_to": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "parent_task_id": "11111111-1111-4111-8111-111111111111", "escalated_by": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|tasks|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-422726866135", "title": "Synthetic task 1081", "number": 2598, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "status": "in_progress", "details": {}, "outcome": "", "due_date": "2026-09-11", "priority": "medium", "client_id": null, "closed_at": null, "escalated": false, "created_at": "2026-11-08T21:14:30.544857+00:00", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "ref_number": 1081, "updated_at": "2026-11-09T21:14:30.544857+00:00", "assigned_to": "eda6a162-8814-48dd-aec7-42fd99b2fdb9", "description": "Test only", "registry_id": "9054811f-a52f-47d9-8986-c82383ee7bbe", "review_date": null, "completed_at": null, "escalated_by": null, "escalated_to": null, "date_reported": "2026-11-09", "parent_task_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|tasks|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-392484745029", "title": "Car service due: Corolla 1AB 2CD", "number": 6, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "status": "assigned", "details": {}, "outcome": "", "due_date": "2026-11-12", "priority": "medium", "client_id": null, "closed_at": null, "escalated": false, "created_at": "2026-11-09T02:10:00.6194+00:00", "created_by": "0a29bd38-850f-4222-b674-d080fe462c2a", "ref_number": 3, "updated_at": "2026-11-09T02:10:00.6194+00:00", "assigned_to": "b0104664-71b0-4297-9d29-942575610100", "description": "Book the 60,000 km service.", "registry_id": "b7544638-7115-45ce-a201-09afbd15473b", "review_date": null, "completed_at": null, "escalated_by": null, "escalated_to": null, "date_reported": "2026-11-07", "parent_task_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|tasks|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-924461684603", "org_id": "b0104664-71b0-4297-9d29-942575610100", "registry_id": "b0104664-71b0-4297-9d29-942575610100", "assigned_to": "b0104664-71b0-4297-9d29-942575610100", "created_by": "b0104664-71b0-4297-9d29-942575610100", "parent_task_id": "b0104664-71b0-4297-9d29-942575610100", "escalated_by": "b0104664-71b0-4297-9d29-942575610100", "client_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|tasks|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-326365305826", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "assigned_to": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "parent_task_id": "11111111-1111-4111-8111-111111111111", "escalated_by": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|tasks|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-276972230392", "title": "Synthetic task 1081", "number": 2598, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "status": "in_progress", "details": {}, "outcome": "", "due_date": "2026-09-11", "priority": "medium", "client_id": null, "closed_at": null, "escalated": false, "created_at": "2026-11-08T21:14:30.544857+00:00", "created_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "ref_number": 1081, "updated_at": "2026-11-09T21:14:30.544857+00:00", "assigned_to": "eda6a162-8814-48dd-aec7-42fd99b2fdb9", "description": "Test only", "registry_id": "9054811f-a52f-47d9-8986-c82383ee7bbe", "review_date": null, "completed_at": null, "escalated_by": null, "escalated_to": null, "date_reported": "2026-11-09", "parent_task_id": null}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|tasks|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-295002502756", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "assigned_to": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "parent_task_id": "11111111-1111-4111-8111-111111111111", "escalated_by": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|tasks|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.tasks (id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id) select id,org_id,title,description,registry_id,priority,status,assigned_to,created_by,created_at,updated_at,due_date,escalated,completed_at,closed_at,ref_number,details,date_reported,review_date,outcome,parent_task_id,escalated_to,escalated_by,client_id from jsonb_populate_record(null::public.tasks, '{"id": "00000000-0000-4000-8000-527880058431", "org_id": "11111111-1111-4111-8111-111111111111", "registry_id": "11111111-1111-4111-8111-111111111111", "assigned_to": "11111111-1111-4111-8111-111111111111", "created_by": "11111111-1111-4111-8111-111111111111", "parent_task_id": "11111111-1111-4111-8111-111111111111", "escalated_by": "11111111-1111-4111-8111-111111111111", "client_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|team_leaders|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-943655842924", "user_id": "00000000-0000-4000-8000-943655842924"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|team_leaders|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-730555881281", "user_id": "00000000-0000-4000-8000-730555881281"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|team_leaders|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-692748014885", "user_id": "00000000-0000-4000-8000-692748014885"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|team_leaders|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-276904826163", "user_id": "00000000-0000-4000-8000-276904826163"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|team_leaders|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-009904687096", "user_id": "00000000-0000-4000-8000-009904687096"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|team_leaders|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-025996998124", "user_id": "00000000-0000-4000-8000-025996998124"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|team_leaders|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-848768642143", "user_id": "00000000-0000-4000-8000-848768642143"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|team_leaders|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-350503460611", "user_id": "00000000-0000-4000-8000-350503460611"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|team_leaders|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-099676470182", "user_id": "00000000-0000-4000-8000-099676470182"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|team_leaders|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-617822757499", "user_id": "00000000-0000-4000-8000-617822757499"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|team_leaders|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-648064878605", "user_id": "00000000-0000-4000-8000-648064878605"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|team_leaders|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-668986755760", "user_id": "00000000-0000-4000-8000-668986755760"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|team_leaders|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-366914929460", "user_id": "00000000-0000-4000-8000-366914929460"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|team_leaders|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-707597727907", "user_id": "00000000-0000-4000-8000-707597727907"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|team_leaders|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-864377005241", "user_id": "00000000-0000-4000-8000-864377005241"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|team_leaders|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-958505555946", "user_id": "00000000-0000-4000-8000-958505555946"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|team_leaders|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-894850827580", "user_id": "00000000-0000-4000-8000-894850827580"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|team_leaders|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-391958685679", "user_id": "00000000-0000-4000-8000-391958685679"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|team_leaders|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.team_leaders (team_id,user_id) select team_id,user_id from jsonb_populate_record(null::public.team_leaders, '{"team_id": "00000000-0000-4000-8000-429766552075", "user_id": "00000000-0000-4000-8000-429766552075"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|team_members|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-012192419787", "user_id": "00000000-0000-4000-8000-012192419787", "added_at": "2026-11-09T02:33:04.74027+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|team_members|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-513927238255", "user_id": "00000000-0000-4000-8000-513927238255"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|team_members|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-551735104651", "user_id": "00000000-0000-4000-8000-551735104651"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|team_members|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-727759756670", "user_id": "00000000-0000-4000-8000-727759756670", "added_at": "2026-11-09T02:33:04.74027+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|team_members|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-940859718313", "user_id": "00000000-0000-4000-8000-940859718313"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|team_members|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-978667584709", "user_id": "00000000-0000-4000-8000-978667584709"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|team_members|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-220276326640", "user_id": "00000000-0000-4000-8000-220276326640", "added_at": "2026-11-09T02:33:04.74027+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|team_members|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-281458491828", "user_id": "00000000-0000-4000-8000-281458491828"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|team_members|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-969368498601", "user_id": "00000000-0000-4000-8000-969368498601"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|team_members|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-386841825334", "user_id": "00000000-0000-4000-8000-386841825334", "added_at": "2026-11-09T02:33:04.74027+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|team_members|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-356599704228", "user_id": "00000000-0000-4000-8000-356599704228", "added_at": "2026-11-09T02:33:04.74027+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|team_members|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-599941786977", "user_id": "00000000-0000-4000-8000-599941786977"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|team_members|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-637749653373", "user_id": "00000000-0000-4000-8000-637749653373"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|team_members|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-638552759124", "user_id": "00000000-0000-4000-8000-638552759124", "added_at": "2026-11-09T02:33:04.74027+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|team_members|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-774673730110", "user_id": "00000000-0000-4000-8000-774673730110", "added_at": "2026-11-09T02:33:04.74027+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|team_members|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-531331647361", "user_id": "00000000-0000-4000-8000-531331647361"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|team_members|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-493523780965", "user_id": "00000000-0000-4000-8000-493523780965"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|team_members|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-109813755253", "user_id": "00000000-0000-4000-8000-109813755253", "added_at": "2026-11-09T02:33:04.74027+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|team_members|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-322913716896", "user_id": "00000000-0000-4000-8000-322913716896"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|team_members|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.team_members (team_id,user_id,added_at) select team_id,user_id,added_at from jsonb_populate_record(null::public.team_members, '{"team_id": "00000000-0000-4000-8000-360721583292", "user_id": "00000000-0000-4000-8000-360721583292"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|teams|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-344344637190", "name": "Management (core team)", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "is_core": true, "created_at": "2026-11-09T02:09:25.193404+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|teams|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-846079455658", "org_id": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|teams|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-404747534771", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|teams|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-886997382865", "name": "Management (core team)", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "is_core": true, "created_at": "2026-11-09T02:09:25.193404+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|teams|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-684977350283", "org_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|teams|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-137905210904", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|teams|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-271108477365", "name": "Management (core team)", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "is_core": true, "created_at": "2026-11-09T02:09:25.193404+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|teams|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-058008515722", "org_id": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|teams|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-020200649326", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|teams|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-430359185912", "name": "Management (core team)", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "is_core": true, "created_at": "2026-11-09T02:09:25.193404+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|teams|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-932094004380", "org_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|teams|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-318732986049", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|teams|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-412279391601", "name": "Management (core team)", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "is_core": true, "created_at": "2026-11-09T02:09:25.193404+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|teams|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-199179429958", "org_id": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|teams|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-161371563562", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|teams|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-269051381448", "name": "Management (core team)", "active": true, "org_id": "9ba6b068-5b2f-4b21-aa90-d370b289fefc", "is_core": true, "created_at": "2026-11-09T02:09:25.193404+00:00"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|teams|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-302923351700", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|teams|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.teams (id,org_id,name,active,created_at,is_core) select id,org_id,name,active,created_at,is_core from jsonb_populate_record(null::public.teams, '{"id": "00000000-0000-4000-8000-519959209487", "org_id": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|website_enquiries|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-924396027623", "note": "", "asked": "What''s your cancellation policy?", "email": "jordan@example.com", "needs": ["Community access"], "phone": "0412 345 678", "source": "chat", "status": "new", "suburb": "Sampleton 3000", "consent": true, "message": "", "has_plan": "", "best_time": "", "full_name": "Jordan Sample", "created_at": "2026-11-09T02:10:00.6194+00:00", "heard_from": "", "managed_by": "", "updated_at": "2026-11-09T02:10:00.6194+00:00", "support_for": "Me"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|website_enquiries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-137495989266"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|website_enquiries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-175303855662"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|website_enquiries|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-606660778318", "note": "", "asked": "What''s your cancellation policy?", "email": "jordan@example.com", "needs": ["Community access"], "phone": "0412 345 678", "source": "chat", "status": "new", "suburb": "Sampleton 3000", "consent": true, "message": "", "has_plan": "", "best_time": "", "full_name": "Jordan Sample", "created_at": "2026-11-09T02:10:00.6194+00:00", "heard_from": "", "managed_by": "", "updated_at": "2026-11-09T02:10:00.6194+00:00", "support_for": "Me"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|website_enquiries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-393560816675"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|website_enquiries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-355752950279"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|website_enquiries|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-979691943757", "note": "", "asked": "What''s your cancellation policy?", "email": "jordan@example.com", "needs": ["Community access"], "phone": "0412 345 678", "source": "chat", "status": "new", "suburb": "Sampleton 3000", "consent": true, "message": "", "has_plan": "", "best_time": "", "full_name": "Jordan Sample", "created_at": "2026-11-09T02:10:00.6194+00:00", "heard_from": "", "managed_by": "", "updated_at": "2026-11-09T02:10:00.6194+00:00", "support_for": "Me"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|website_enquiries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-477957125289"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|website_enquiries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-728784115718"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|website_enquiries|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-010410576345", "note": "", "asked": "What''s your cancellation policy?", "email": "jordan@example.com", "needs": ["Community access"], "phone": "0412 345 678", "source": "chat", "status": "new", "suburb": "Sampleton 3000", "consent": true, "message": "", "has_plan": "", "best_time": "", "full_name": "Jordan Sample", "created_at": "2026-11-09T02:10:00.6194+00:00", "heard_from": "", "managed_by": "", "updated_at": "2026-11-09T02:10:00.6194+00:00", "support_for": "Me"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|website_enquiries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-223510537988"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|website_enquiries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-261318404384"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|website_enquiries|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-120862857993", "note": "", "asked": "What''s your cancellation policy?", "email": "jordan@example.com", "needs": ["Community access"], "phone": "0412 345 678", "source": "chat", "status": "new", "suburb": "Sampleton 3000", "consent": true, "message": "", "has_plan": "", "best_time": "", "full_name": "Jordan Sample", "created_at": "2026-11-09T02:10:00.6194+00:00", "heard_from": "", "managed_by": "", "updated_at": "2026-11-09T02:10:00.6194+00:00", "support_for": "Me"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|website_enquiries|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-380871960475"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|website_enquiries|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-869955029954"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|website_enquiries|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-224606779735", "note": "", "asked": "What''s your cancellation policy?", "email": "jordan@example.com", "needs": ["Community access"], "phone": "0412 345 678", "source": "chat", "status": "new", "suburb": "Sampleton 3000", "consent": true, "message": "", "has_plan": "", "best_time": "", "full_name": "Jordan Sample", "created_at": "2026-11-09T02:10:00.6194+00:00", "heard_from": "", "managed_by": "", "updated_at": "2026-11-09T02:10:00.6194+00:00", "support_for": "Me"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|website_enquiries|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-011506818092"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|website_enquiries|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.website_enquiries (id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at) select id,full_name,phone,email,suburb,support_for,has_plan,managed_by,needs,best_time,heard_from,message,asked,source,status,note,consent,created_at,updated_at from jsonb_populate_record(null::public.website_enquiries, '{"id": "00000000-0000-4000-8000-973698951696"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|work_overrides|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"id": 1, "reason": "Short staffed this weekend", "user_id": "2b0480ba-ebf9-4699-93bb-5d8e27e12f50", "ended_at": "2026-11-09T10:26:36.011834+00:00", "ended_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T10:26:34.50259+00:00", "granted_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "until_date": "2026-11-14"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|work_overrides|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"user_id": "0a29bd38-850f-4222-b674-d080fe462c2a", "granted_by": "0a29bd38-850f-4222-b674-d080fe462c2a", "ended_by": "0a29bd38-850f-4222-b674-d080fe462c2a"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|system admin|work_overrides|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "0a29bd38-850f-4222-b674-d080fe462c2a", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"user_id": "11111111-1111-4111-8111-111111111111", "granted_by": "11111111-1111-4111-8111-111111111111", "ended_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|work_overrides|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"id": 1, "reason": "Short staffed this weekend", "user_id": "2b0480ba-ebf9-4699-93bb-5d8e27e12f50", "ended_at": "2026-11-09T10:26:36.011834+00:00", "ended_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T10:26:34.50259+00:00", "granted_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "until_date": "2026-11-14"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|work_overrides|their own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"id": 1, "reason": "Short staffed this weekend", "user_id": "2b0480ba-ebf9-4699-93bb-5d8e27e12f50", "ended_at": "2026-11-09T10:26:36.011834+00:00", "ended_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T10:26:34.50259+00:00", "granted_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "until_date": "2026-11-14"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|work_overrides|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"user_id": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "granted_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "ended_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|manager|work_overrides|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"user_id": "11111111-1111-4111-8111-111111111111", "granted_by": "11111111-1111-4111-8111-111111111111", "ended_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|work_overrides|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"id": 1, "reason": "Short staffed this weekend", "user_id": "2b0480ba-ebf9-4699-93bb-5d8e27e12f50", "ended_at": "2026-11-09T10:26:36.011834+00:00", "ended_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T10:26:34.50259+00:00", "granted_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "until_date": "2026-11-14"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|work_overrides|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"user_id": "1028b402-8a12-467c-adcf-2f1269268df7", "granted_by": "1028b402-8a12-467c-adcf-2f1269268df7", "ended_by": "1028b402-8a12-467c-adcf-2f1269268df7"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff admin|work_overrides|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "1028b402-8a12-467c-adcf-2f1269268df7", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"user_id": "11111111-1111-4111-8111-111111111111", "granted_by": "11111111-1111-4111-8111-111111111111", "ended_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|work_overrides|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"id": 1, "reason": "Short staffed this weekend", "user_id": "2b0480ba-ebf9-4699-93bb-5d8e27e12f50", "ended_at": "2026-11-09T10:26:36.011834+00:00", "ended_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T10:26:34.50259+00:00", "granted_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "until_date": "2026-11-14"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|work_overrides|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"user_id": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "granted_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "ended_by": "4c7b3e14-a605-485f-a0ef-d5b3b112503c"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|team leader|work_overrides|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "4c7b3e14-a605-485f-a0ef-d5b3b112503c", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"user_id": "11111111-1111-4111-8111-111111111111", "granted_by": "11111111-1111-4111-8111-111111111111", "ended_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|work_overrides|general
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"id": 1, "reason": "Short staffed this weekend", "user_id": "2b0480ba-ebf9-4699-93bb-5d8e27e12f50", "ended_at": "2026-11-09T10:26:36.011834+00:00", "ended_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T10:26:34.50259+00:00", "granted_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "until_date": "2026-11-14"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|work_overrides|constructed own
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"user_id": "b0104664-71b0-4297-9d29-942575610100", "granted_by": "b0104664-71b0-4297-9d29-942575610100", "ended_by": "b0104664-71b0-4297-9d29-942575610100"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|staff|work_overrides|constructed other
begin; set local role authenticated; select set_config('request.jwt.claims', '{"sub": "b0104664-71b0-4297-9d29-942575610100", "role": "authenticated", "aal": "aal2"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"user_id": "11111111-1111-4111-8111-111111111111", "granted_by": "11111111-1111-4111-8111-111111111111", "ended_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|work_overrides|general
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"id": 1, "reason": "Short staffed this weekend", "user_id": "2b0480ba-ebf9-4699-93bb-5d8e27e12f50", "ended_at": "2026-11-09T10:26:36.011834+00:00", "ended_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "created_at": "2026-11-09T10:26:34.50259+00:00", "granted_by": "9c72ee4d-2aec-4f65-be29-21318783ed9b", "until_date": "2026-11-14"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|work_overrides|constructed own
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"user_id": "11111111-1111-4111-8111-111111111111", "granted_by": "11111111-1111-4111-8111-111111111111", "ended_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
\echo INS|signed out|work_overrides|constructed other
begin; set local role anon; select set_config('request.jwt.claims', '{"role": "anon"}', true) is null;
insert into public.work_overrides (user_id,reason,until_date,granted_by,created_at,ended_at,ended_by) select user_id,reason,until_date,granted_by,created_at,ended_at,ended_by from jsonb_populate_record(null::public.work_overrides, '{"user_id": "11111111-1111-4111-8111-111111111111", "granted_by": "11111111-1111-4111-8111-111111111111", "ended_by": "11111111-1111-4111-8111-111111111111"}'::jsonb);
select 'R|OK';
rollback;
