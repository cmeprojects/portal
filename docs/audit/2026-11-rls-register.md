# RLS change register (cmeprojects)

Staff Portal · © cmeproject · Review only: **nothing here has been applied.**

Generated from the database definitions built from `supabase/migrations` (all 76). For each policy: the original rule, the proposed rule, why, and the rollback SQL.

**Pattern A (94 policies, mechanical):** calls that don't depend on the row (no arguments, or fixed-value arguments such as `has_role(ARRAY['manager'])`) are wrapped as `(select …)`, so Postgres evaluates them once per statement instead of once per row. All of these functions are `STABLE` (same result within a statement), so the access condition is unchanged. Row-dependent calls (for example `can_see_task(id)`, `leads_user(user_id)`) are **left as they are**.

**Pattern B (task visibility family, hand-written):** see the end of this file.

## 1. `admin_delegations`: system admin and the delegate read delegations (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `is_system_admin()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(is_system_admin() OR (user_id = auth.uid()))
```
Proposed USING:
```sql
((select public.is_system_admin()) OR (user_id = (select auth.uid())))
```
Apply:
```sql
alter policy "system admin and the delegate read delegations" on public.admin_delegations
  using (((select public.is_system_admin()) OR (user_id = (select auth.uid()))));
```
Rollback:
```sql
alter policy "system admin and the delegate read delegations" on public.admin_delegations
  using ((public.is_system_admin() OR (user_id = auth.uid())));
```

## 2. `app_settings`: anyone reads public settings (SELECT)

- **Roles:** anon, authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(is_public OR is_member())
```
Proposed USING:
```sql
(is_public OR (select public.is_member()))
```
Apply:
```sql
alter policy "anyone reads public settings" on public.app_settings
  using ((is_public OR (select public.is_member())));
```
Rollback:
```sql
alter policy "anyone reads public settings" on public.app_settings
  using ((is_public OR public.is_member()));
```

## 3. `app_settings`: car managers set the client field (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_cars()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
((key = 'vehicles.client_field'::text) AND can_manage_cars())
```
Proposed USING:
```sql
((key = 'vehicles.client_field'::text) AND (select public.can_manage_cars()))
```
Original WITH CHECK:
```sql
((key = 'vehicles.client_field'::text) AND can_manage_cars() AND ((value #>> '{}'::text[]) = ANY (ARRAY['off'::text, 'optional'::text, 'required'::text])))
```
Proposed WITH CHECK:
```sql
((key = 'vehicles.client_field'::text) AND (select public.can_manage_cars()) AND ((value #>> '{}'::text[]) = ANY (ARRAY['off'::text, 'optional'::text, 'required'::text])))
```
Apply:
```sql
alter policy "car managers set the client field" on public.app_settings
  using (((key = 'vehicles.client_field'::text) AND (select public.can_manage_cars())))
  with check (((key = 'vehicles.client_field'::text) AND (select public.can_manage_cars()) AND ((value #>> '{}'::text[]) = ANY (ARRAY['off'::text, 'optional'::text, 'required'::text]))));
```
Rollback:
```sql
alter policy "car managers set the client field" on public.app_settings
  using (((key = 'vehicles.client_field'::text) AND public.can_manage_cars()))
  with check (((key = 'vehicles.client_field'::text) AND public.can_manage_cars() AND ((value #>> '{}'::text[]) = ANY (ARRAY['off'::text, 'optional'::text, 'required'::text]))));
```

## 4. `app_settings`: system admin edits settings (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_system_admin()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_system_admin()
```
Proposed USING:
```sql
(select public.is_system_admin())
```
Original WITH CHECK:
```sql
is_system_admin()
```
Proposed WITH CHECK:
```sql
(select public.is_system_admin())
```
Apply:
```sql
alter policy "system admin edits settings" on public.app_settings
  using ((select public.is_system_admin()))
  with check ((select public.is_system_admin()));
```
Rollback:
```sql
alter policy "system admin edits settings" on public.app_settings
  using (public.is_system_admin())
  with check (public.is_system_admin());
```

## 5. `assistant_chats`: assistant_chats_own (ALL)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
((user_id = auth.uid()) AND is_member())
```
Proposed USING:
```sql
((user_id = (select auth.uid())) AND (select public.is_member()))
```
Original WITH CHECK:
```sql
((user_id = auth.uid()) AND is_member())
```
Proposed WITH CHECK:
```sql
((user_id = (select auth.uid())) AND (select public.is_member()))
```
Apply:
```sql
alter policy "assistant_chats_own" on public.assistant_chats
  using (((user_id = (select auth.uid())) AND (select public.is_member())))
  with check (((user_id = (select auth.uid())) AND (select public.is_member())));
```
Rollback:
```sql
alter policy "assistant_chats_own" on public.assistant_chats
  using (((user_id = auth.uid()) AND public.is_member()))
  with check (((user_id = auth.uid()) AND public.is_member()));
```

## 6. `assistant_documents`: assistant_documents_all (ALL)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_admin_area('website'::text)`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_admin_area('website'::text)
```
Proposed USING:
```sql
(select public.can_admin_area('website'::text))
```
Original WITH CHECK:
```sql
can_admin_area('website'::text)
```
Proposed WITH CHECK:
```sql
(select public.can_admin_area('website'::text))
```
Apply:
```sql
alter policy "assistant_documents_all" on public.assistant_documents
  using ((select public.can_admin_area('website'::text)))
  with check ((select public.can_admin_area('website'::text)));
```
Rollback:
```sql
alter policy "assistant_documents_all" on public.assistant_documents
  using (public.can_admin_area('website'::text))
  with check (public.can_admin_area('website'::text));
```

## 7. `assistant_messages`: assistant_messages_own (ALL)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(EXISTS ( SELECT 1
   FROM assistant_chats c
  WHERE ((c.id = assistant_messages.chat_id) AND (c.user_id = auth.uid()))))
```
Proposed USING:
```sql
(EXISTS ( SELECT 1
   FROM assistant_chats c
  WHERE ((c.id = assistant_messages.chat_id) AND (c.user_id = (select auth.uid())))))
```
Original WITH CHECK:
```sql
(EXISTS ( SELECT 1
   FROM assistant_chats c
  WHERE ((c.id = assistant_messages.chat_id) AND (c.user_id = auth.uid()))))
```
Proposed WITH CHECK:
```sql
(EXISTS ( SELECT 1
   FROM assistant_chats c
  WHERE ((c.id = assistant_messages.chat_id) AND (c.user_id = (select auth.uid())))))
```
Apply:
```sql
alter policy "assistant_messages_own" on public.assistant_messages
  using ((EXISTS ( SELECT 1
   FROM assistant_chats c
  WHERE ((c.id = assistant_messages.chat_id) AND (c.user_id = (select auth.uid()))))))
  with check ((EXISTS ( SELECT 1
   FROM assistant_chats c
  WHERE ((c.id = assistant_messages.chat_id) AND (c.user_id = (select auth.uid()))))));
```
Rollback:
```sql
alter policy "assistant_messages_own" on public.assistant_messages
  using ((EXISTS ( SELECT 1
   FROM assistant_chats c
  WHERE ((c.id = assistant_messages.chat_id) AND (c.user_id = auth.uid())))))
  with check ((EXISTS ( SELECT 1
   FROM assistant_chats c
  WHERE ((c.id = assistant_messages.chat_id) AND (c.user_id = auth.uid())))));
```

## 8. `assistant_questions`: assistant_questions_read (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_admin_area('website'::text)`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_admin_area('website'::text)
```
Proposed USING:
```sql
(select public.can_admin_area('website'::text))
```
Apply:
```sql
alter policy "assistant_questions_read" on public.assistant_questions
  using ((select public.can_admin_area('website'::text)));
```
Rollback:
```sql
alter policy "assistant_questions_read" on public.assistant_questions
  using (public.can_admin_area('website'::text));
```

## 9. `assistant_settings`: assistant_settings_read (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_admin_area('website'::text)`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_admin_area('website'::text)
```
Proposed USING:
```sql
(select public.can_admin_area('website'::text))
```
Apply:
```sql
alter policy "assistant_settings_read" on public.assistant_settings
  using ((select public.can_admin_area('website'::text)));
```
Rollback:
```sql
alter policy "assistant_settings_read" on public.assistant_settings
  using (public.can_admin_area('website'::text));
```

## 10. `assistant_settings`: assistant_settings_write (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_admin_area('website'::text)`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_admin_area('website'::text)
```
Proposed USING:
```sql
(select public.can_admin_area('website'::text))
```
Original WITH CHECK:
```sql
can_admin_area('website'::text)
```
Proposed WITH CHECK:
```sql
(select public.can_admin_area('website'::text))
```
Apply:
```sql
alter policy "assistant_settings_write" on public.assistant_settings
  using ((select public.can_admin_area('website'::text)))
  with check ((select public.can_admin_area('website'::text)));
```
Rollback:
```sql
alter policy "assistant_settings_write" on public.assistant_settings
  using (public.can_admin_area('website'::text))
  with check (public.can_admin_area('website'::text));
```

## 11. `audit_log`: delegated managers read the change log (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_admin_area('audit'::text)`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_admin_area('audit'::text)
```
Proposed USING:
```sql
(select public.can_admin_area('audit'::text))
```
Apply:
```sql
alter policy "delegated managers read the change log" on public.audit_log
  using ((select public.can_admin_area('audit'::text)));
```
Rollback:
```sql
alter policy "delegated managers read the change log" on public.audit_log
  using (public.can_admin_area('audit'::text));
```

## 12. `audit_log`: system admin reads the audit log (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_system_admin()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_system_admin()
```
Proposed USING:
```sql
(select public.is_system_admin())
```
Apply:
```sql
alter policy "system admin reads the audit log" on public.audit_log
  using ((select public.is_system_admin()));
```
Rollback:
```sql
alter policy "system admin reads the audit log" on public.audit_log
  using (public.is_system_admin());
```

## 13. `car_clients`: car managers add clients (INSERT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_cars()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original WITH CHECK:
```sql
can_manage_cars()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_cars())
```
Apply:
```sql
alter policy "car managers add clients" on public.car_clients
  with check ((select public.can_manage_cars()));
```
Rollback:
```sql
alter policy "car managers add clients" on public.car_clients
  with check (public.can_manage_cars());
```

## 14. `car_clients`: car managers change clients (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_cars()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_manage_cars()
```
Proposed USING:
```sql
(select public.can_manage_cars())
```
Original WITH CHECK:
```sql
can_manage_cars()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_cars())
```
Apply:
```sql
alter policy "car managers change clients" on public.car_clients
  using ((select public.can_manage_cars()))
  with check ((select public.can_manage_cars()));
```
Rollback:
```sql
alter policy "car managers change clients" on public.car_clients
  using (public.can_manage_cars())
  with check (public.can_manage_cars());
```

## 15. `car_clients`: car managers see clients (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_cars()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_manage_cars()
```
Proposed USING:
```sql
(select public.can_manage_cars())
```
Apply:
```sql
alter policy "car managers see clients" on public.car_clients
  using ((select public.can_manage_cars()));
```
Rollback:
```sql
alter policy "car managers see clients" on public.car_clients
  using (public.can_manage_cars());
```

## 16. `car_clients`: people managers add clients (INSERT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_people()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original WITH CHECK:
```sql
can_manage_people()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_people())
```
Apply:
```sql
alter policy "people managers add clients" on public.car_clients
  with check ((select public.can_manage_people()));
```
Rollback:
```sql
alter policy "people managers add clients" on public.car_clients
  with check (public.can_manage_people());
```

## 17. `car_clients`: people managers change clients (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_people()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_manage_people()
```
Proposed USING:
```sql
(select public.can_manage_people())
```
Original WITH CHECK:
```sql
can_manage_people()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_people())
```
Apply:
```sql
alter policy "people managers change clients" on public.car_clients
  using ((select public.can_manage_people()))
  with check ((select public.can_manage_people()));
```
Rollback:
```sql
alter policy "people managers change clients" on public.car_clients
  using (public.can_manage_people())
  with check (public.can_manage_people());
```

## 18. `car_clients`: people managers see clients (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_people()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_manage_people()
```
Proposed USING:
```sql
(select public.can_manage_people())
```
Apply:
```sql
alter policy "people managers see clients" on public.car_clients
  using ((select public.can_manage_people()));
```
Rollback:
```sql
alter policy "people managers see clients" on public.car_clients
  using (public.can_manage_people());
```

## 19. `car_purposes`: car managers add purposes (INSERT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_cars()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original WITH CHECK:
```sql
can_manage_cars()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_cars())
```
Apply:
```sql
alter policy "car managers add purposes" on public.car_purposes
  with check ((select public.can_manage_cars()));
```
Rollback:
```sql
alter policy "car managers add purposes" on public.car_purposes
  with check (public.can_manage_cars());
```

## 20. `car_purposes`: car managers change purposes (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_cars()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_manage_cars()
```
Proposed USING:
```sql
(select public.can_manage_cars())
```
Original WITH CHECK:
```sql
can_manage_cars()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_cars())
```
Apply:
```sql
alter policy "car managers change purposes" on public.car_purposes
  using ((select public.can_manage_cars()))
  with check ((select public.can_manage_cars()));
```
Rollback:
```sql
alter policy "car managers change purposes" on public.car_purposes
  using (public.can_manage_cars())
  with check (public.can_manage_cars());
```

## 21. `car_purposes`: staff see purposes (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `cars_on()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
cars_on()
```
Proposed USING:
```sql
(select public.cars_on())
```
Apply:
```sql
alter policy "staff see purposes" on public.car_purposes
  using ((select public.cars_on()));
```
Rollback:
```sql
alter policy "staff see purposes" on public.car_purposes
  using (public.cars_on());
```

## 22. `car_trips`: drivers see their trips, reports see all (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `can_see_car_reports()`, `cars_on()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(cars_on() AND ((driver_id = auth.uid()) OR can_see_car_reports()))
```
Proposed USING:
```sql
((select public.cars_on()) AND ((driver_id = (select auth.uid())) OR (select public.can_see_car_reports())))
```
Apply:
```sql
alter policy "drivers see their trips, reports see all" on public.car_trips
  using (((select public.cars_on()) AND ((driver_id = (select auth.uid())) OR (select public.can_see_car_reports()))));
```
Rollback:
```sql
alter policy "drivers see their trips, reports see all" on public.car_trips
  using ((public.cars_on() AND ((driver_id = auth.uid()) OR public.can_see_car_reports())));
```

## 23. `cars`: car managers add cars (INSERT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_cars()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original WITH CHECK:
```sql
can_manage_cars()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_cars())
```
Apply:
```sql
alter policy "car managers add cars" on public.cars
  with check ((select public.can_manage_cars()));
```
Rollback:
```sql
alter policy "car managers add cars" on public.cars
  with check (public.can_manage_cars());
```

## 24. `cars`: car managers change cars (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_cars()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_manage_cars()
```
Proposed USING:
```sql
(select public.can_manage_cars())
```
Original WITH CHECK:
```sql
can_manage_cars()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_cars())
```
Apply:
```sql
alter policy "car managers change cars" on public.cars
  using ((select public.can_manage_cars()))
  with check ((select public.can_manage_cars()));
```
Rollback:
```sql
alter policy "car managers change cars" on public.cars
  using (public.can_manage_cars())
  with check (public.can_manage_cars());
```

## 25. `cars`: staff see cars (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `cars_on()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
cars_on()
```
Proposed USING:
```sql
(select public.cars_on())
```
Apply:
```sql
alter policy "staff see cars" on public.cars
  using ((select public.cars_on()));
```
Rollback:
```sql
alter policy "staff see cars" on public.cars
  using (public.cars_on());
```

## 26. `client_teams`: members see which team looks after which client (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members see which team looks after which client" on public.client_teams
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members see which team looks after which client" on public.client_teams
  using (public.is_member());
```

## 27. `client_teams`: people managers link clients to teams (INSERT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_people()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original WITH CHECK:
```sql
can_manage_people()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_people())
```
Apply:
```sql
alter policy "people managers link clients to teams" on public.client_teams
  with check ((select public.can_manage_people()));
```
Rollback:
```sql
alter policy "people managers link clients to teams" on public.client_teams
  with check (public.can_manage_people());
```

## 28. `client_teams`: people managers unlink clients from teams (DELETE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_people()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_manage_people()
```
Proposed USING:
```sql
(select public.can_manage_people())
```
Apply:
```sql
alter policy "people managers unlink clients from teams" on public.client_teams
  using ((select public.can_manage_people()));
```
Rollback:
```sql
alter policy "people managers unlink clients from teams" on public.client_teams
  using (public.can_manage_people());
```

## 29. `compliance_items`: compliance managers add items (INSERT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_compliance()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original WITH CHECK:
```sql
can_manage_compliance()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_compliance())
```
Apply:
```sql
alter policy "compliance managers add items" on public.compliance_items
  with check ((select public.can_manage_compliance()));
```
Rollback:
```sql
alter policy "compliance managers add items" on public.compliance_items
  with check (public.can_manage_compliance());
```

## 30. `compliance_items`: compliance managers change items (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_compliance()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_manage_compliance()
```
Proposed USING:
```sql
(select public.can_manage_compliance())
```
Original WITH CHECK:
```sql
can_manage_compliance()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_compliance())
```
Apply:
```sql
alter policy "compliance managers change items" on public.compliance_items
  using ((select public.can_manage_compliance()))
  with check ((select public.can_manage_compliance()));
```
Rollback:
```sql
alter policy "compliance managers change items" on public.compliance_items
  using (public.can_manage_compliance())
  with check (public.can_manage_compliance());
```

## 31. `compliance_items`: members read onboarding items (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read onboarding items" on public.compliance_items
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read onboarding items" on public.compliance_items
  using (public.is_member());
```

## 32. `compliance_opens`: people see their own opens; compliance managers see all (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `can_manage_compliance()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
((user_id = auth.uid()) OR can_manage_compliance())
```
Proposed USING:
```sql
((user_id = (select auth.uid())) OR (select public.can_manage_compliance()))
```
Apply:
```sql
alter policy "people see their own opens; compliance managers see all" on public.compliance_opens
  using (((user_id = (select auth.uid())) OR (select public.can_manage_compliance())));
```
Rollback:
```sql
alter policy "people see their own opens; compliance managers see all" on public.compliance_opens
  using (((user_id = auth.uid()) OR public.can_manage_compliance()));
```

## 33. `compliance_records`: read your own records, or as compliance manager (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `can_manage_compliance()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
((user_id = auth.uid()) OR can_manage_compliance())
```
Proposed USING:
```sql
((user_id = (select auth.uid())) OR (select public.can_manage_compliance()))
```
Apply:
```sql
alter policy "read your own records, or as compliance manager" on public.compliance_records
  using (((user_id = (select auth.uid())) OR (select public.can_manage_compliance())));
```
Rollback:
```sql
alter policy "read your own records, or as compliance manager" on public.compliance_records
  using (((user_id = auth.uid()) OR public.can_manage_compliance()));
```

## 34. `custom_alerts`: the builder manages alerts (ALL)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_build_features()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_build_features()
```
Proposed USING:
```sql
(select public.can_build_features())
```
Original WITH CHECK:
```sql
can_build_features()
```
Proposed WITH CHECK:
```sql
(select public.can_build_features())
```
Apply:
```sql
alter policy "the builder manages alerts" on public.custom_alerts
  using ((select public.can_build_features()))
  with check ((select public.can_build_features()));
```
Rollback:
```sql
alter policy "the builder manages alerts" on public.custom_alerts
  using (public.can_build_features())
  with check (public.can_build_features());
```

## 35. `custom_client_targets`: targets follow their feature (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_build_features()`, `is_member()`
- **Row-dependent calls (unchanged):** `custom_feature_live(feature_id)`
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(can_build_features() OR (is_member() AND custom_feature_live(feature_id)))
```
Proposed USING:
```sql
((select public.can_build_features()) OR ((select public.is_member()) AND public.custom_feature_live(feature_id)))
```
Apply:
```sql
alter policy "targets follow their feature" on public.custom_client_targets
  using (((select public.can_build_features()) OR ((select public.is_member()) AND public.custom_feature_live(feature_id))));
```
Rollback:
```sql
alter policy "targets follow their feature" on public.custom_client_targets
  using ((public.can_build_features() OR (public.is_member() AND public.custom_feature_live(feature_id))));
```

## 36. `custom_client_targets`: the builder sets targets (ALL)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_build_features()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_build_features()
```
Proposed USING:
```sql
(select public.can_build_features())
```
Original WITH CHECK:
```sql
can_build_features()
```
Proposed WITH CHECK:
```sql
(select public.can_build_features())
```
Apply:
```sql
alter policy "the builder sets targets" on public.custom_client_targets
  using ((select public.can_build_features()))
  with check ((select public.can_build_features()));
```
Rollback:
```sql
alter policy "the builder sets targets" on public.custom_client_targets
  using (public.can_build_features())
  with check (public.can_build_features());
```

## 37. `custom_features`: staff see live features, the builder sees all (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_build_features()`, `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(can_build_features() OR (is_member() AND (status = 'published'::text) AND enabled))
```
Proposed USING:
```sql
((select public.can_build_features()) OR ((select public.is_member()) AND (status = 'published'::text) AND enabled))
```
Apply:
```sql
alter policy "staff see live features, the builder sees all" on public.custom_features
  using (((select public.can_build_features()) OR ((select public.is_member()) AND (status = 'published'::text) AND enabled)));
```
Rollback:
```sql
alter policy "staff see live features, the builder sees all" on public.custom_features
  using ((public.can_build_features() OR (public.is_member() AND (status = 'published'::text) AND enabled)));
```

## 38. `custom_features`: the builder adds features (INSERT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_build_features()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original WITH CHECK:
```sql
can_build_features()
```
Proposed WITH CHECK:
```sql
(select public.can_build_features())
```
Apply:
```sql
alter policy "the builder adds features" on public.custom_features
  with check ((select public.can_build_features()));
```
Rollback:
```sql
alter policy "the builder adds features" on public.custom_features
  with check (public.can_build_features());
```

## 39. `custom_features`: the builder changes features (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_build_features()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_build_features()
```
Proposed USING:
```sql
(select public.can_build_features())
```
Original WITH CHECK:
```sql
can_build_features()
```
Proposed WITH CHECK:
```sql
(select public.can_build_features())
```
Apply:
```sql
alter policy "the builder changes features" on public.custom_features
  using ((select public.can_build_features()))
  with check ((select public.can_build_features()));
```
Rollback:
```sql
alter policy "the builder changes features" on public.custom_features
  using (public.can_build_features())
  with check (public.can_build_features());
```

## 40. `custom_features`: the builder removes unused features (DELETE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_build_features()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(can_build_features() AND (NOT (EXISTS ( SELECT 1
   FROM custom_entries e
  WHERE (e.feature_id = custom_features.id)))))
```
Proposed USING:
```sql
((select public.can_build_features()) AND (NOT (EXISTS ( SELECT 1
   FROM custom_entries e
  WHERE (e.feature_id = custom_features.id)))))
```
Apply:
```sql
alter policy "the builder removes unused features" on public.custom_features
  using (((select public.can_build_features()) AND (NOT (EXISTS ( SELECT 1
   FROM custom_entries e
  WHERE (e.feature_id = custom_features.id))))));
```
Rollback:
```sql
alter policy "the builder removes unused features" on public.custom_features
  using ((public.can_build_features() AND (NOT (EXISTS ( SELECT 1
   FROM custom_entries e
  WHERE (e.feature_id = custom_features.id))))));
```

## 41. `custom_fields`: fields follow their feature (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_build_features()`, `is_member()`
- **Row-dependent calls (unchanged):** `custom_feature_live(feature_id)`
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(can_build_features() OR (is_member() AND custom_feature_live(feature_id)))
```
Proposed USING:
```sql
((select public.can_build_features()) OR ((select public.is_member()) AND public.custom_feature_live(feature_id)))
```
Apply:
```sql
alter policy "fields follow their feature" on public.custom_fields
  using (((select public.can_build_features()) OR ((select public.is_member()) AND public.custom_feature_live(feature_id))));
```
Rollback:
```sql
alter policy "fields follow their feature" on public.custom_fields
  using ((public.can_build_features() OR (public.is_member() AND public.custom_feature_live(feature_id))));
```

## 42. `custom_fields`: the builder adds fields (INSERT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_build_features()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original WITH CHECK:
```sql
can_build_features()
```
Proposed WITH CHECK:
```sql
(select public.can_build_features())
```
Apply:
```sql
alter policy "the builder adds fields" on public.custom_fields
  with check ((select public.can_build_features()));
```
Rollback:
```sql
alter policy "the builder adds fields" on public.custom_fields
  with check (public.can_build_features());
```

## 43. `custom_fields`: the builder changes fields (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_build_features()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_build_features()
```
Proposed USING:
```sql
(select public.can_build_features())
```
Original WITH CHECK:
```sql
can_build_features()
```
Proposed WITH CHECK:
```sql
(select public.can_build_features())
```
Apply:
```sql
alter policy "the builder changes fields" on public.custom_fields
  using ((select public.can_build_features()))
  with check ((select public.can_build_features()));
```
Rollback:
```sql
alter policy "the builder changes fields" on public.custom_fields
  using (public.can_build_features())
  with check (public.can_build_features());
```

## 44. `custom_fields`: the builder removes unused fields (DELETE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_build_features()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(can_build_features() AND (NOT (EXISTS ( SELECT 1
   FROM custom_entries e
  WHERE ((e.feature_id = custom_fields.feature_id) AND (e.data ? (custom_fields.id)::text))))))
```
Proposed USING:
```sql
((select public.can_build_features()) AND (NOT (EXISTS ( SELECT 1
   FROM custom_entries e
  WHERE ((e.feature_id = custom_fields.feature_id) AND (e.data ? (custom_fields.id)::text))))))
```
Apply:
```sql
alter policy "the builder removes unused fields" on public.custom_fields
  using (((select public.can_build_features()) AND (NOT (EXISTS ( SELECT 1
   FROM custom_entries e
  WHERE ((e.feature_id = custom_fields.feature_id) AND (e.data ? (custom_fields.id)::text)))))));
```
Rollback:
```sql
alter policy "the builder removes unused fields" on public.custom_fields
  using ((public.can_build_features() AND (NOT (EXISTS ( SELECT 1
   FROM custom_entries e
  WHERE ((e.feature_id = custom_fields.feature_id) AND (e.data ? (custom_fields.id)::text)))))));
```

## 45. `delegation_rules`: members read delegation (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read delegation" on public.delegation_rules
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read delegation" on public.delegation_rules
  using (public.is_member());
```

## 46. `delegation_shares`: members read shares (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read shares" on public.delegation_shares
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read shares" on public.delegation_shares
  using (public.is_member());
```

## 47. `features`: members read features (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read features" on public.features
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read features" on public.features
  using (public.is_member());
```

## 48. `features`: system admin switches features (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_system_admin()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_system_admin()
```
Proposed USING:
```sql
(select public.is_system_admin())
```
Original WITH CHECK:
```sql
is_system_admin()
```
Proposed WITH CHECK:
```sql
(select public.is_system_admin())
```
Apply:
```sql
alter policy "system admin switches features" on public.features
  using ((select public.is_system_admin()))
  with check ((select public.is_system_admin()));
```
Rollback:
```sql
alter policy "system admin switches features" on public.features
  using (public.is_system_admin())
  with check (public.is_system_admin());
```

## 49. `form_collaborators`: the form's maker shares it (ALL)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `is_system_admin()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(is_system_admin() OR (EXISTS ( SELECT 1
   FROM forms
  WHERE ((forms.id = form_collaborators.form_id) AND (forms.created_by = auth.uid())))))
```
Proposed USING:
```sql
((select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM forms
  WHERE ((forms.id = form_collaborators.form_id) AND (forms.created_by = (select auth.uid()))))))
```
Original WITH CHECK:
```sql
(is_system_admin() OR (EXISTS ( SELECT 1
   FROM forms
  WHERE ((forms.id = form_collaborators.form_id) AND (forms.created_by = auth.uid())))))
```
Proposed WITH CHECK:
```sql
((select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM forms
  WHERE ((forms.id = form_collaborators.form_id) AND (forms.created_by = (select auth.uid()))))))
```
Apply:
```sql
alter policy "the form's maker shares it" on public.form_collaborators
  using (((select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM forms
  WHERE ((forms.id = form_collaborators.form_id) AND (forms.created_by = (select auth.uid())))))))
  with check (((select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM forms
  WHERE ((forms.id = form_collaborators.form_id) AND (forms.created_by = (select auth.uid())))))));
```
Rollback:
```sql
alter policy "the form's maker shares it" on public.form_collaborators
  using ((public.is_system_admin() OR (EXISTS ( SELECT 1
   FROM forms
  WHERE ((forms.id = form_collaborators.form_id) AND (forms.created_by = auth.uid()))))))
  with check ((public.is_system_admin() OR (EXISTS ( SELECT 1
   FROM forms
  WHERE ((forms.id = form_collaborators.form_id) AND (forms.created_by = auth.uid()))))));
```

## 50. `form_completions`: completions: your own, or the form's managers (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`
- **Row-dependent calls (unchanged):** `can_manage_form(form_id)`
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
((user_id = auth.uid()) OR can_manage_form(form_id))
```
Proposed USING:
```sql
((user_id = (select auth.uid())) OR public.can_manage_form(form_id))
```
Apply:
```sql
alter policy "completions: your own, or the form's managers" on public.form_completions
  using (((user_id = (select auth.uid())) OR public.can_manage_form(form_id)));
```
Rollback:
```sql
alter policy "completions: your own, or the form's managers" on public.form_completions
  using (((user_id = auth.uid()) OR public.can_manage_form(form_id)));
```

## 51. `form_recipients`: recipients see their own, managers all (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`
- **Row-dependent calls (unchanged):** `can_manage_form(form_id)`
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
((user_id = auth.uid()) OR can_manage_form(form_id))
```
Proposed USING:
```sql
((user_id = (select auth.uid())) OR public.can_manage_form(form_id))
```
Apply:
```sql
alter policy "recipients see their own, managers all" on public.form_recipients
  using (((user_id = (select auth.uid())) OR public.can_manage_form(form_id)));
```
Rollback:
```sql
alter policy "recipients see their own, managers all" on public.form_recipients
  using (((user_id = auth.uid()) OR public.can_manage_form(form_id)));
```

## 52. `form_responses`: replies: your own, or the form's managers (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`
- **Row-dependent calls (unchanged):** `can_manage_form(form_id)`
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
((user_id = auth.uid()) OR ((status = 'submitted'::text) AND can_manage_form(form_id)))
```
Proposed USING:
```sql
((user_id = (select auth.uid())) OR ((status = 'submitted'::text) AND public.can_manage_form(form_id)))
```
Apply:
```sql
alter policy "replies: your own, or the form's managers" on public.form_responses
  using (((user_id = (select auth.uid())) OR ((status = 'submitted'::text) AND public.can_manage_form(form_id))));
```
Rollback:
```sql
alter policy "replies: your own, or the form's managers" on public.form_responses
  using (((user_id = auth.uid()) OR ((status = 'submitted'::text) AND public.can_manage_form(form_id))));
```

## 53. `forms`: form makers add forms (INSERT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `can_make_forms()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original WITH CHECK:
```sql
(can_make_forms() AND (created_by = auth.uid()))
```
Proposed WITH CHECK:
```sql
((select public.can_make_forms()) AND (created_by = (select auth.uid())))
```
Apply:
```sql
alter policy "form makers add forms" on public.forms
  with check (((select public.can_make_forms()) AND (created_by = (select auth.uid()))));
```
Rollback:
```sql
alter policy "form makers add forms" on public.forms
  with check ((public.can_make_forms() AND (created_by = auth.uid())));
```

## 54. `forms`: forms are seen by their managers, or to fill in (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `is_member()`
- **Row-dependent calls (unchanged):** `can_fill_form(id)`, `can_manage_form(id)`
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(((created_by = auth.uid()) AND is_member()) OR can_manage_form(id) OR can_fill_form(id))
```
Proposed USING:
```sql
(((created_by = (select auth.uid())) AND (select public.is_member())) OR public.can_manage_form(id) OR public.can_fill_form(id))
```
Apply:
```sql
alter policy "forms are seen by their managers, or to fill in" on public.forms
  using ((((created_by = (select auth.uid())) AND (select public.is_member())) OR public.can_manage_form(id) OR public.can_fill_form(id)));
```
Rollback:
```sql
alter policy "forms are seen by their managers, or to fill in" on public.forms
  using ((((created_by = auth.uid()) AND public.is_member()) OR public.can_manage_form(id) OR public.can_fill_form(id)));
```

## 55. `invitations`: inviters create general invitations (INSERT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_invite()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original WITH CHECK:
```sql
can_invite()
```
Proposed WITH CHECK:
```sql
(select public.can_invite())
```
Apply:
```sql
alter policy "inviters create general invitations" on public.invitations
  with check ((select public.can_invite()));
```
Rollback:
```sql
alter policy "inviters create general invitations" on public.invitations
  with check (public.can_invite());
```

## 56. `invitations`: managers and admins create invitations (INSERT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_people()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original WITH CHECK:
```sql
can_manage_people()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_people())
```
Apply:
```sql
alter policy "managers and admins create invitations" on public.invitations
  with check ((select public.can_manage_people()));
```
Rollback:
```sql
alter policy "managers and admins create invitations" on public.invitations
  with check (public.can_manage_people());
```

## 57. `invitations`: managers and admins read invitations (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_people()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_manage_people()
```
Proposed USING:
```sql
(select public.can_manage_people())
```
Apply:
```sql
alter policy "managers and admins read invitations" on public.invitations
  using ((select public.can_manage_people()));
```
Rollback:
```sql
alter policy "managers and admins read invitations" on public.invitations
  using (public.can_manage_people());
```

## 58. `invitations`: managers and admins remove pending invitations (DELETE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_people()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(can_manage_people() AND (accepted_at IS NULL))
```
Proposed USING:
```sql
((select public.can_manage_people()) AND (accepted_at IS NULL))
```
Apply:
```sql
alter policy "managers and admins remove pending invitations" on public.invitations
  using (((select public.can_manage_people()) AND (accepted_at IS NULL)));
```
Rollback:
```sql
alter policy "managers and admins remove pending invitations" on public.invitations
  using ((public.can_manage_people() AND (accepted_at IS NULL)));
```

## 59. `invitations`: managers and admins update invitations (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_people()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_manage_people()
```
Proposed USING:
```sql
(select public.can_manage_people())
```
Original WITH CHECK:
```sql
can_manage_people()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_people())
```
Apply:
```sql
alter policy "managers and admins update invitations" on public.invitations
  using ((select public.can_manage_people()))
  with check ((select public.can_manage_people()));
```
Rollback:
```sql
alter policy "managers and admins update invitations" on public.invitations
  using (public.can_manage_people())
  with check (public.can_manage_people());
```

## 60. `job_titles`: delegated people add job titles (INSERT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_admin_area('roles'::text)`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original WITH CHECK:
```sql
can_admin_area('roles'::text)
```
Proposed WITH CHECK:
```sql
(select public.can_admin_area('roles'::text))
```
Apply:
```sql
alter policy "delegated people add job titles" on public.job_titles
  with check ((select public.can_admin_area('roles'::text)));
```
Rollback:
```sql
alter policy "delegated people add job titles" on public.job_titles
  with check (public.can_admin_area('roles'::text));
```

## 61. `job_titles`: delegated people change job titles (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_admin_area('roles'::text)`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_admin_area('roles'::text)
```
Proposed USING:
```sql
(select public.can_admin_area('roles'::text))
```
Original WITH CHECK:
```sql
can_admin_area('roles'::text)
```
Proposed WITH CHECK:
```sql
(select public.can_admin_area('roles'::text))
```
Apply:
```sql
alter policy "delegated people change job titles" on public.job_titles
  using ((select public.can_admin_area('roles'::text)))
  with check ((select public.can_admin_area('roles'::text)));
```
Rollback:
```sql
alter policy "delegated people change job titles" on public.job_titles
  using (public.can_admin_area('roles'::text))
  with check (public.can_admin_area('roles'::text));
```

## 62. `job_titles`: members read job titles (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read job titles" on public.job_titles
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read job titles" on public.job_titles
  using (public.is_member());
```

## 63. `leave_periods`: the person and people managers see leave (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `can_manage_people()`, `is_system_admin()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
((user_id = auth.uid()) OR can_manage_people() OR is_system_admin() OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = auth.uid()) AND (tm.user_id = leave_periods.user_id)))))
```
Proposed USING:
```sql
((user_id = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = (select auth.uid())) AND (tm.user_id = leave_periods.user_id)))))
```
Apply:
```sql
alter policy "the person and people managers see leave" on public.leave_periods
  using (((user_id = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = (select auth.uid())) AND (tm.user_id = leave_periods.user_id))))));
```
Rollback:
```sql
alter policy "the person and people managers see leave" on public.leave_periods
  using (((user_id = auth.uid()) OR public.can_manage_people() OR public.is_system_admin() OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = auth.uid()) AND (tm.user_id = leave_periods.user_id))))));
```

## 64. `notifications`: read your own notifications (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(user_id = auth.uid())
```
Proposed USING:
```sql
(user_id = (select auth.uid()))
```
Apply:
```sql
alter policy "read your own notifications" on public.notifications
  using ((user_id = (select auth.uid())));
```
Rollback:
```sql
alter policy "read your own notifications" on public.notifications
  using ((user_id = auth.uid()));
```

## 65. `organisation`: members read the company (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read the company" on public.organisation
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read the company" on public.organisation
  using (public.is_member());
```

## 66. `organisation`: system admin edits the company (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_system_admin()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_system_admin()
```
Proposed USING:
```sql
(select public.is_system_admin())
```
Original WITH CHECK:
```sql
is_system_admin()
```
Proposed WITH CHECK:
```sql
(select public.is_system_admin())
```
Apply:
```sql
alter policy "system admin edits the company" on public.organisation
  using ((select public.is_system_admin()))
  with check ((select public.is_system_admin()));
```
Rollback:
```sql
alter policy "system admin edits the company" on public.organisation
  using (public.is_system_admin())
  with check (public.is_system_admin());
```

## 67. `people_change_requests`: managers and admins see change requests (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_people()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_manage_people()
```
Proposed USING:
```sql
(select public.can_manage_people())
```
Apply:
```sql
alter policy "managers and admins see change requests" on public.people_change_requests
  using ((select public.can_manage_people()));
```
Rollback:
```sql
alter policy "managers and admins see change requests" on public.people_change_requests
  using (public.can_manage_people());
```

## 68. `profiles`: managers and admins update people (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_people()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_manage_people()
```
Proposed USING:
```sql
(select public.can_manage_people())
```
Original WITH CHECK:
```sql
can_manage_people()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_people())
```
Apply:
```sql
alter policy "managers and admins update people" on public.profiles
  using ((select public.can_manage_people()))
  with check ((select public.can_manage_people()));
```
Rollback:
```sql
alter policy "managers and admins update people" on public.profiles
  using (public.can_manage_people())
  with check (public.can_manage_people());
```

## 69. `profiles`: members read colleagues (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`, `is_system_admin()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(is_member() AND ((role <> 'system_admin'::app_role) OR is_system_admin()))
```
Proposed USING:
```sql
((select public.is_member()) AND ((role <> 'system_admin'::app_role) OR (select public.is_system_admin())))
```
Apply:
```sql
alter policy "members read colleagues" on public.profiles
  using (((select public.is_member()) AND ((role <> 'system_admin'::app_role) OR (select public.is_system_admin()))));
```
Rollback:
```sql
alter policy "members read colleagues" on public.profiles
  using ((public.is_member() AND ((role <> 'system_admin'::app_role) OR public.is_system_admin())));
```

## 70. `profiles`: read own profile (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(id = auth.uid())
```
Proposed USING:
```sql
(id = (select auth.uid()))
```
Apply:
```sql
alter policy "read own profile" on public.profiles
  using ((id = (select auth.uid())));
```
Rollback:
```sql
alter policy "read own profile" on public.profiles
  using ((id = auth.uid()));
```

## 71. `profiles`: update own name (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `my_role()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
((id = auth.uid()) AND (my_role() IS NOT NULL))
```
Proposed USING:
```sql
((id = (select auth.uid())) AND ((select public.my_role()) IS NOT NULL))
```
Original WITH CHECK:
```sql
(id = auth.uid())
```
Proposed WITH CHECK:
```sql
(id = (select auth.uid()))
```
Apply:
```sql
alter policy "update own name" on public.profiles
  using (((id = (select auth.uid())) AND ((select public.my_role()) IS NOT NULL)))
  with check ((id = (select auth.uid())));
```
Rollback:
```sql
alter policy "update own name" on public.profiles
  using (((id = auth.uid()) AND (public.my_role() IS NOT NULL)))
  with check ((id = auth.uid()));
```

## 72. `record_events`: members read record history (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read record history" on public.record_events
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read record history" on public.record_events
  using (public.is_member());
```

## 73. `records`: members read records (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read records" on public.records
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read records" on public.records
  using (public.is_member());
```

## 74. `register_templates`: members read register templates (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read register templates" on public.register_templates
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read register templates" on public.register_templates
  using (public.is_member());
```

## 75. `registries`: delegated people create registries (INSERT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_admin_area('registers'::text)`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original WITH CHECK:
```sql
can_admin_area('registers'::text)
```
Proposed WITH CHECK:
```sql
(select public.can_admin_area('registers'::text))
```
Apply:
```sql
alter policy "delegated people create registries" on public.registries
  with check ((select public.can_admin_area('registers'::text)));
```
Rollback:
```sql
alter policy "delegated people create registries" on public.registries
  with check (public.can_admin_area('registers'::text));
```

## 76. `registries`: members read registries (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read registries" on public.registries
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read registries" on public.registries
  using (public.is_member());
```

## 77. `registry_fields`: members read registry fields (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read registry fields" on public.registry_fields
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read registry fields" on public.registry_fields
  using (public.is_member());
```

## 78. `registry_managers`: members read registry managers (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read registry managers" on public.registry_managers
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read registry managers" on public.registry_managers
  using (public.is_member());
```

## 79. `request_types`: members read request types (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read request types" on public.request_types
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read request types" on public.request_types
  using (public.is_member());
```

## 80. `request_types`: system admin changes request types (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_admin_area('hr'::text)`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_admin_area('hr'::text)
```
Proposed USING:
```sql
(select public.can_admin_area('hr'::text))
```
Original WITH CHECK:
```sql
can_admin_area('hr'::text)
```
Proposed WITH CHECK:
```sql
(select public.can_admin_area('hr'::text))
```
Apply:
```sql
alter policy "system admin changes request types" on public.request_types
  using ((select public.can_admin_area('hr'::text)))
  with check ((select public.can_admin_area('hr'::text)));
```
Rollback:
```sql
alter policy "system admin changes request types" on public.request_types
  using (public.can_admin_area('hr'::text))
  with check (public.can_admin_area('hr'::text));
```

## 81. `requests`: people involved see a request (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `can_manage_people()`, `feature_enabled('hr_requests'::text)`, `is_system_admin()`
- **Row-dependent calls (unchanged):** `can_act_on_request(id)`
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(feature_enabled('hr_requests'::text) AND ((requester = auth.uid()) OR (swap_with = auth.uid()) OR can_manage_people() OR is_system_admin() OR can_act_on_request(id)))
```
Proposed USING:
```sql
((select public.feature_enabled('hr_requests'::text)) AND ((requester = (select auth.uid())) OR (swap_with = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()) OR public.can_act_on_request(id)))
```
Apply:
```sql
alter policy "people involved see a request" on public.requests
  using (((select public.feature_enabled('hr_requests'::text)) AND ((requester = (select auth.uid())) OR (swap_with = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()) OR public.can_act_on_request(id))));
```
Rollback:
```sql
alter policy "people involved see a request" on public.requests
  using ((public.feature_enabled('hr_requests'::text) AND ((requester = auth.uid()) OR (swap_with = auth.uid()) OR public.can_manage_people() OR public.is_system_admin() OR public.can_act_on_request(id))));
```

## 82. `settings_drafts`: see your drafts, the system admin sees all (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `is_system_admin()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(is_system_admin() OR (saved_by = auth.uid()))
```
Proposed USING:
```sql
((select public.is_system_admin()) OR (saved_by = (select auth.uid())))
```
Apply:
```sql
alter policy "see your drafts, the system admin sees all" on public.settings_drafts
  using (((select public.is_system_admin()) OR (saved_by = (select auth.uid()))));
```
Rollback:
```sql
alter policy "see your drafts, the system admin sees all" on public.settings_drafts
  using ((public.is_system_admin() OR (saved_by = auth.uid())));
```

## 83. `shift_changes`: the person and people managers see shift changes (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `can_manage_people()`, `is_system_admin()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
((user_id = auth.uid()) OR can_manage_people() OR is_system_admin() OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = auth.uid()) AND (tm.user_id = shift_changes.user_id)))))
```
Proposed USING:
```sql
((user_id = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = (select auth.uid())) AND (tm.user_id = shift_changes.user_id)))))
```
Apply:
```sql
alter policy "the person and people managers see shift changes" on public.shift_changes
  using (((user_id = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = (select auth.uid())) AND (tm.user_id = shift_changes.user_id))))));
```
Rollback:
```sql
alter policy "the person and people managers see shift changes" on public.shift_changes
  using (((user_id = auth.uid()) OR public.can_manage_people() OR public.is_system_admin() OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = auth.uid()) AND (tm.user_id = shift_changes.user_id))))));
```

## 84. `staff_directory`: members see the staff directory (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `feature_enabled('hr_profiles'::text)`, `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(is_member() AND feature_enabled('hr_profiles'::text))
```
Proposed USING:
```sql
((select public.is_member()) AND (select public.feature_enabled('hr_profiles'::text)))
```
Apply:
```sql
alter policy "members see the staff directory" on public.staff_directory
  using (((select public.is_member()) AND (select public.feature_enabled('hr_profiles'::text))));
```
Rollback:
```sql
alter policy "members see the staff directory" on public.staff_directory
  using ((public.is_member() AND public.feature_enabled('hr_profiles'::text)));
```

## 85. `staff_private`: the person and people managers see private details (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `can_manage_people()`, `feature_enabled('hr_profiles'::text)`, `is_system_admin()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(feature_enabled('hr_profiles'::text) AND ((user_id = auth.uid()) OR can_manage_people() OR is_system_admin() OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = auth.uid()) AND (tm.user_id = staff_private.user_id))))))
```
Proposed USING:
```sql
((select public.feature_enabled('hr_profiles'::text)) AND ((user_id = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = (select auth.uid())) AND (tm.user_id = staff_private.user_id))))))
```
Apply:
```sql
alter policy "the person and people managers see private details" on public.staff_private
  using (((select public.feature_enabled('hr_profiles'::text)) AND ((user_id = (select auth.uid())) OR (select public.can_manage_people()) OR (select public.is_system_admin()) OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = (select auth.uid())) AND (tm.user_id = staff_private.user_id)))))));
```
Rollback:
```sql
alter policy "the person and people managers see private details" on public.staff_private
  using ((public.feature_enabled('hr_profiles'::text) AND ((user_id = auth.uid()) OR public.can_manage_people() OR public.is_system_admin() OR (EXISTS ( SELECT 1
   FROM (team_leaders tl
     JOIN team_members tm ON ((tm.team_id = tl.team_id)))
  WHERE ((tl.user_id = auth.uid()) AND (tm.user_id = staff_private.user_id)))))));
```

## 86. `task_alerts`: read your own alerts (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(user_id = auth.uid())
```
Proposed USING:
```sql
(user_id = (select auth.uid()))
```
Apply:
```sql
alter policy "read your own alerts" on public.task_alerts
  using ((user_id = (select auth.uid())));
```
Rollback:
```sql
alter policy "read your own alerts" on public.task_alerts
  using ((user_id = auth.uid()));
```

## 87. `task_views`: read your own views (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
(user_id = auth.uid())
```
Proposed USING:
```sql
(user_id = (select auth.uid()))
```
Apply:
```sql
alter policy "read your own views" on public.task_views
  using ((user_id = (select auth.uid())));
```
Rollback:
```sql
alter policy "read your own views" on public.task_views
  using ((user_id = auth.uid()));
```

## 88. `team_leaders`: members read team leaders (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read team leaders" on public.team_leaders
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read team leaders" on public.team_leaders
  using (public.is_member());
```

## 89. `team_members`: members read team members (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read team members" on public.team_members
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read team members" on public.team_members
  using (public.is_member());
```

## 90. `teams`: managers and admins manage teams (ALL)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_manage_people()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_manage_people()
```
Proposed USING:
```sql
(select public.can_manage_people())
```
Original WITH CHECK:
```sql
can_manage_people()
```
Proposed WITH CHECK:
```sql
(select public.can_manage_people())
```
Apply:
```sql
alter policy "managers and admins manage teams" on public.teams
  using ((select public.can_manage_people()))
  with check ((select public.can_manage_people()));
```
Rollback:
```sql
alter policy "managers and admins manage teams" on public.teams
  using (public.can_manage_people())
  with check (public.can_manage_people());
```

## 91. `teams`: members read teams (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `is_member()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
is_member()
```
Proposed USING:
```sql
(select public.is_member())
```
Apply:
```sql
alter policy "members read teams" on public.teams
  using ((select public.is_member()));
```
Rollback:
```sql
alter policy "members read teams" on public.teams
  using (public.is_member());
```

## 92. `website_enquiries`: website_enquiries_read (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_see_enquiries()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_see_enquiries()
```
Proposed USING:
```sql
(select public.can_see_enquiries())
```
Apply:
```sql
alter policy "website_enquiries_read" on public.website_enquiries
  using ((select public.can_see_enquiries()));
```
Rollback:
```sql
alter policy "website_enquiries_read" on public.website_enquiries
  using (public.can_see_enquiries());
```

## 93. `website_enquiries`: website_enquiries_update (UPDATE)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `can_see_enquiries()`
- **Row-dependent calls (unchanged):** none
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
can_see_enquiries()
```
Proposed USING:
```sql
(select public.can_see_enquiries())
```
Original WITH CHECK:
```sql
can_see_enquiries()
```
Proposed WITH CHECK:
```sql
(select public.can_see_enquiries())
```
Apply:
```sql
alter policy "website_enquiries_update" on public.website_enquiries
  using ((select public.can_see_enquiries()))
  with check ((select public.can_see_enquiries()));
```
Rollback:
```sql
alter policy "website_enquiries_update" on public.website_enquiries
  using (public.can_see_enquiries())
  with check (public.can_see_enquiries());
```

## 94. `work_overrides`: the person and people who manage staff see overrides (SELECT)

- **Roles:** authenticated
- **Row-independent calls evaluated per row today:** `auth.uid()`, `can_manage_compliance()`, `can_manage_people()`
- **Row-dependent calls (unchanged):** `has_role(ARRAY['manager'::app_role])`, `leads_user(user_id)`
- **Security risk of the change:** Low (same STABLE functions, same arguments, same boolean logic)

Original USING:
```sql
((user_id = auth.uid()) OR can_manage_compliance() OR can_manage_people() OR has_role(ARRAY['manager'::app_role]) OR leads_user(user_id))
```
Proposed USING:
```sql
((user_id = (select auth.uid())) OR (select public.can_manage_compliance()) OR (select public.can_manage_people()) OR public.has_role(ARRAY['manager'::app_role]) OR public.leads_user(user_id))
```
Apply:
```sql
alter policy "the person and people who manage staff see overrides" on public.work_overrides
  using (((user_id = (select auth.uid())) OR (select public.can_manage_compliance()) OR (select public.can_manage_people()) OR public.has_role(ARRAY['manager'::app_role]) OR public.leads_user(user_id)));
```
Rollback:
```sql
alter policy "the person and people who manage staff see overrides" on public.work_overrides
  using (((user_id = auth.uid()) OR public.can_manage_compliance() OR public.can_manage_people() OR public.has_role(ARRAY['manager'::app_role]) OR public.leads_user(user_id)));
```

## Pattern B: task visibility (tasks, task events, task helpers, task attachments)

Today `tasks` uses `can_see_task(id)`, which re-reads the task and re-checks membership, role and team leadership **for every row**. The proposal inlines the same conditions on the row's own columns, evaluates the person-level checks once, and gets the team leader's people once per statement from a new read-only helper:

```sql
create function public.my_led_people() returns setof uuid
language sql stable security definer set search_path = ''
as $$
  select m.user_id from public.team_leaders tl join public.team_members m on m.team_id = tl.team_id
   where tl.user_id = auth.uid() and public.feature_live('teams')
     and public.has_role(array['team_leader', 'manager', 'system_admin']::public.app_role[])
$$;
revoke execute on function public.my_led_people() from public, anon;
grant execute on function public.my_led_people() to authenticated;

alter policy "see tasks you have access to" on public.tasks using (
  (select public.is_member()) and (
    (select public.has_role(array['manager', 'system_admin']::public.app_role[]))
    or assigned_to = (select auth.uid()) or created_by = (select auth.uid())
    or exists (select 1 from public.task_helpers h where h.task_id = tasks.id and h.user_id = (select auth.uid()))
    or assigned_to in (select public.my_led_people()) or created_by in (select public.my_led_people())));
```

Rollback:
```sql
alter policy "see tasks you have access to" on public.tasks using (public.can_see_task(id));
drop function if exists public.my_led_people();
```

**Why it's safe:** it's the same five conditions as `can_see_task` (member AND (manager/system admin OR assigned OR created OR helper OR led by me)). `my_led_people()` uses the same joins and checks as `leads_user()`, returns only IDs of people the caller leads, can't be run by signed-out visitors, and runs with a fixed `search_path`. `can_see_task()` stays for the other places that use it.

**Measured** (local copy, 10,515 synthetic tasks, inside a transaction that was rolled back): manager 7,117 → 5 ms, staff admin 9,112 → 8 ms, team leader 8,822 → 6 ms, support worker 9,954 → 5 ms. Exactly the same task IDs per role (fingerprint of the sorted ID list compared).

The child tables (`task_events`, `task_helpers`, `task_attachments`) use `can_see_task(task_id)`. Proposed: `task_id in (select id from public.tasks)`, which re-uses the optimised task rule above, to be measured and compared per role in the same way before approval.

