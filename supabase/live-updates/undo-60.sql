-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 60: puts the 94 security policies back exactly as they were
-- (functions called per row). Safe to run again.
begin;
alter policy "system admin and the delegate read delegations" on public.admin_delegations
  using ((public.is_system_admin() OR (user_id = auth.uid())));

alter policy "anyone reads public settings" on public.app_settings
  using ((is_public OR public.is_member()));

alter policy "car managers set the client field" on public.app_settings
  using (((key = 'vehicles.client_field'::text) AND public.can_manage_cars()))
  with check (((key = 'vehicles.client_field'::text) AND public.can_manage_cars() AND ((value #>> '{}'::text[]) = ANY (ARRAY['off'::text, 'optional'::text, 'required'::text]))));

alter policy "system admin edits settings" on public.app_settings
  using (public.is_system_admin())
  with check (public.is_system_admin());

alter policy "assistant_chats_own" on public.assistant_chats
  using (((user_id = auth.uid()) AND public.is_member()))
  with check (((user_id = auth.uid()) AND public.is_member()));

alter policy "assistant_documents_all" on public.assistant_documents
  using (public.can_admin_area('website'::text))
  with check (public.can_admin_area('website'::text));

alter policy "assistant_messages_own" on public.assistant_messages
  using ((EXISTS ( SELECT 1
   FROM assistant_chats c
  WHERE ((c.id = assistant_messages.chat_id) AND (c.user_id = auth.uid())))))
  with check ((EXISTS ( SELECT 1
   FROM assistant_chats c
  WHERE ((c.id = assistant_messages.chat_id) AND (c.user_id = auth.uid())))));

alter policy "assistant_questions_read" on public.assistant_questions
  using (public.can_admin_area('website'::text));

alter policy "assistant_settings_read" on public.assistant_settings
  using (public.can_admin_area('website'::text));

alter policy "assistant_settings_write" on public.assistant_settings
  using (public.can_admin_area('website'::text))
  with check (public.can_admin_area('website'::text));

alter policy "delegated managers read the change log" on public.audit_log
  using (public.can_admin_area('audit'::text));

alter policy "system admin reads the audit log" on public.audit_log
  using (public.is_system_admin());

alter policy "car managers add clients" on public.car_clients
  with check (public.can_manage_cars());

alter policy "car managers change clients" on public.car_clients
  using (public.can_manage_cars())
  with check (public.can_manage_cars());

alter policy "car managers see clients" on public.car_clients
  using (public.can_manage_cars());

alter policy "people managers add clients" on public.car_clients
  with check (public.can_manage_people());

alter policy "people managers change clients" on public.car_clients
  using (public.can_manage_people())
  with check (public.can_manage_people());

alter policy "people managers see clients" on public.car_clients
  using (public.can_manage_people());

alter policy "car managers add purposes" on public.car_purposes
  with check (public.can_manage_cars());

alter policy "car managers change purposes" on public.car_purposes
  using (public.can_manage_cars())
  with check (public.can_manage_cars());

alter policy "staff see purposes" on public.car_purposes
  using (public.cars_on());

alter policy "drivers see their trips, reports see all" on public.car_trips
  using ((public.cars_on() AND ((driver_id = auth.uid()) OR public.can_see_car_reports())));

alter policy "car managers add cars" on public.cars
  with check (public.can_manage_cars());

alter policy "car managers change cars" on public.cars
  using (public.can_manage_cars())
  with check (public.can_manage_cars());

alter policy "staff see cars" on public.cars
  using (public.cars_on());

alter policy "members see which team looks after which client" on public.client_teams
  using (public.is_member());

alter policy "people managers link clients to teams" on public.client_teams
  with check (public.can_manage_people());

alter policy "people managers unlink clients from teams" on public.client_teams
  using (public.can_manage_people());

alter policy "compliance managers add items" on public.compliance_items
  with check (public.can_manage_compliance());

alter policy "compliance managers change items" on public.compliance_items
  using (public.can_manage_compliance())
  with check (public.can_manage_compliance());

alter policy "members read onboarding items" on public.compliance_items
  using (public.is_member());

alter policy "people see their own opens; compliance managers see all" on public.compliance_opens
  using (((user_id = auth.uid()) OR public.can_manage_compliance()));

alter policy "read your own records, or as compliance manager" on public.compliance_records
  using (((user_id = auth.uid()) OR public.can_manage_compliance()));

alter policy "the builder manages alerts" on public.custom_alerts
  using (public.can_build_features())
  with check (public.can_build_features());

alter policy "targets follow their feature" on public.custom_client_targets
  using ((public.can_build_features() OR (public.is_member() AND public.custom_feature_live(feature_id))));

alter policy "the builder sets targets" on public.custom_client_targets
  using (public.can_build_features())
  with check (public.can_build_features());

alter policy "staff see live features, the builder sees all" on public.custom_features
  using ((public.can_build_features() OR (public.is_member() AND (status = 'published'::text) AND enabled)));

alter policy "the builder adds features" on public.custom_features
  with check (public.can_build_features());

alter policy "the builder changes features" on public.custom_features
  using (public.can_build_features())
  with check (public.can_build_features());

alter policy "the builder removes unused features" on public.custom_features
  using ((public.can_build_features() AND (NOT (EXISTS ( SELECT 1
   FROM custom_entries e
  WHERE (e.feature_id = custom_features.id))))));

alter policy "fields follow their feature" on public.custom_fields
  using ((public.can_build_features() OR (public.is_member() AND public.custom_feature_live(feature_id))));

alter policy "the builder adds fields" on public.custom_fields
  with check (public.can_build_features());

alter policy "the builder changes fields" on public.custom_fields
  using (public.can_build_features())
  with check (public.can_build_features());

alter policy "the builder removes unused fields" on public.custom_fields
  using ((public.can_build_features() AND (NOT (EXISTS ( SELECT 1
   FROM custom_entries e
  WHERE ((e.feature_id = custom_fields.feature_id) AND (e.data ? (custom_fields.id)::text)))))));

alter policy "members read delegation" on public.delegation_rules
  using (public.is_member());

alter policy "members read shares" on public.delegation_shares
  using (public.is_member());

alter policy "members read features" on public.features
  using (public.is_member());

alter policy "system admin switches features" on public.features
  using (public.is_system_admin())
  with check (public.is_system_admin());

alter policy "the form's maker shares it" on public.form_collaborators
  using ((public.is_system_admin() OR (EXISTS ( SELECT 1
   FROM forms
  WHERE ((forms.id = form_collaborators.form_id) AND (forms.created_by = auth.uid()))))))
  with check ((public.is_system_admin() OR (EXISTS ( SELECT 1
   FROM forms
  WHERE ((forms.id = form_collaborators.form_id) AND (forms.created_by = auth.uid()))))));

alter policy "completions: your own, or the form's managers" on public.form_completions
  using (((user_id = auth.uid()) OR public.can_manage_form(form_id)));

alter policy "recipients see their own, managers all" on public.form_recipients
  using (((user_id = auth.uid()) OR public.can_manage_form(form_id)));

alter policy "replies: your own, or the form's managers" on public.form_responses
  using (((user_id = auth.uid()) OR ((status = 'submitted'::text) AND public.can_manage_form(form_id))));

alter policy "form makers add forms" on public.forms
  with check ((public.can_make_forms() AND (created_by = auth.uid())));

alter policy "forms are seen by their managers, or to fill in" on public.forms
  using ((((created_by = auth.uid()) AND public.is_member()) OR public.can_manage_form(id) OR public.can_fill_form(id)));

alter policy "inviters create general invitations" on public.invitations
  with check (public.can_invite());

alter policy "managers and admins create invitations" on public.invitations
  with check (public.can_manage_people());

alter policy "managers and admins read invitations" on public.invitations
  using (public.can_manage_people());

alter policy "managers and admins remove pending invitations" on public.invitations
  using ((public.can_manage_people() AND (accepted_at IS NULL)));

alter policy "managers and admins update invitations" on public.invitations
  using (public.can_manage_people())
  with check (public.can_manage_people());

alter policy "delegated people add job titles" on public.job_titles
  with check (public.can_admin_area('roles'::text));

alter policy "delegated people change job titles" on public.job_titles
  using (public.can_admin_area('roles'::text))
  with check (public.can_admin_area('roles'::text));

alter policy "members read job titles" on public.job_titles
  using (public.is_member());

alter policy "the person and people managers see leave" on public.leave_periods
  using (((user_id = auth.uid()) OR public.can_manage_people() OR public.is_system_admin() OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = auth.uid()) AND (tm.user_id = leave_periods.user_id))))));

alter policy "read your own notifications" on public.notifications
  using ((user_id = auth.uid()));

alter policy "members read the company" on public.organisation
  using (public.is_member());

alter policy "system admin edits the company" on public.organisation
  using (public.is_system_admin())
  with check (public.is_system_admin());

alter policy "managers and admins see change requests" on public.people_change_requests
  using (public.can_manage_people());

alter policy "managers and admins update people" on public.profiles
  using (public.can_manage_people())
  with check (public.can_manage_people());

alter policy "members read colleagues" on public.profiles
  using ((public.is_member() AND ((role <> 'system_admin'::app_role) OR public.is_system_admin())));

alter policy "read own profile" on public.profiles
  using ((id = auth.uid()));

alter policy "update own name" on public.profiles
  using (((id = auth.uid()) AND (public.my_role() IS NOT NULL)))
  with check ((id = auth.uid()));

alter policy "members read record history" on public.record_events
  using (public.is_member());

alter policy "members read records" on public.records
  using (public.is_member());

alter policy "members read register templates" on public.register_templates
  using (public.is_member());

alter policy "delegated people create registries" on public.registries
  with check (public.can_admin_area('registers'::text));

alter policy "members read registries" on public.registries
  using (public.is_member());

alter policy "members read registry fields" on public.registry_fields
  using (public.is_member());

alter policy "members read registry managers" on public.registry_managers
  using (public.is_member());

alter policy "members read request types" on public.request_types
  using (public.is_member());

alter policy "system admin changes request types" on public.request_types
  using (public.can_admin_area('hr'::text))
  with check (public.can_admin_area('hr'::text));

alter policy "people involved see a request" on public.requests
  using ((public.feature_enabled('hr_requests'::text) AND ((requester = auth.uid()) OR (swap_with = auth.uid()) OR public.can_manage_people() OR public.is_system_admin() OR public.can_act_on_request(id))));

alter policy "see your drafts, the system admin sees all" on public.settings_drafts
  using ((public.is_system_admin() OR (saved_by = auth.uid())));

alter policy "the person and people managers see shift changes" on public.shift_changes
  using (((user_id = auth.uid()) OR public.can_manage_people() OR public.is_system_admin() OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = auth.uid()) AND (tm.user_id = shift_changes.user_id))))));

alter policy "members see the staff directory" on public.staff_directory
  using ((public.is_member() AND public.feature_enabled('hr_profiles'::text)));

alter policy "the person and people managers see private details" on public.staff_private
  using ((public.feature_enabled('hr_profiles'::text) AND ((user_id = auth.uid()) OR public.can_manage_people() OR public.is_system_admin() OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = auth.uid()) AND (tm.user_id = staff_private.user_id)))))));

alter policy "read your own alerts" on public.task_alerts
  using ((user_id = auth.uid()));

alter policy "read your own views" on public.task_views
  using ((user_id = auth.uid()));

alter policy "members read team leaders" on public.team_leaders
  using (public.is_member());

alter policy "members read team members" on public.team_members
  using (public.is_member());

alter policy "managers and admins manage teams" on public.teams
  using (public.can_manage_people())
  with check (public.can_manage_people());

alter policy "members read teams" on public.teams
  using (public.is_member());

alter policy "website_enquiries_read" on public.website_enquiries
  using (public.can_see_enquiries());

alter policy "website_enquiries_update" on public.website_enquiries
  using (public.can_see_enquiries())
  with check (public.can_see_enquiries());

alter policy "the person and people who manage staff see overrides" on public.work_overrides
  using (((user_id = auth.uid()) OR public.can_manage_compliance() OR public.can_manage_people() OR public.has_role(ARRAY['manager'::app_role]) OR public.leads_user(user_id)));
commit;
