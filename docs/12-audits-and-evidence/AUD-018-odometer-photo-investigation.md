# AUD-018: Odometer photo storage policy: investigation

| Field | Value |
|---|---|
| Document ID | AUD-018 |
| Title | Odometer photo storage policy: investigation |
| Category | 12 Audits and evidence |
| Status | Evidence (read-only investigation; nothing changed) |
| Prepared by | Technical Lead (prepared by Claude), 16 Nov 2026 |
| Related | DEC-001 D-009 and D-037, SEC-002 C7, RSK-001 RSK-15 |

## Question

Decision D-009 (docs/PLAN.md, 27 Oct 2026): "Vehicles: no odometer photos;
readings typed only." SEC-002 found a storage policy "drivers upload odometer
photos". Is uploading an approved feature?

## Findings (verified in code, migrations and git history)

| Item | Finding | Source |
|---|---|---|
| Decision | "No odometer photos" added 27 Oct 2026 | commit 698c31e, docs/PLAN.md |
| Cars build | 29 Oct 2026, two days later, added the setting **"Odometer photo when returning"**: Off, Optional or Required; **default Optional** | commit d21341a; `supabase/migrations/20261121000001_cars.sql` (setting `vehicles.odo_photo`, column `car_trips.odo_photo_path`) |
| Setting screen | System settings shows the setting with Off / Optional / Required | `src/app/(portal)/system/page.tsx`, `src/lib/setting-choices.ts` |
| Upload in the app | Returning a car shows "Photo of the odometer" unless the setting is Off; required when Required; the file goes to the `car-files` bucket in the driver's own folder | `src/components/cars-desk.tsx` |
| Database | `return_car_trip` stores the photo path unless the setting is Off; refuses a path outside the driver's folder; requires a photo when Required | `supabase/migrations/20261130000003_car_trip_where.sql` |
| Storage policy | "drivers upload odometer photos": INSERT into `car-files` when Cars is on and the first folder is the user's own id. **Doesn't check the setting**, so uploads to their own folder stay possible even when the setting is Off | storage policies (SEC-002 appendix A) |
| Reading | Drivers see their own folder; people with car reports see all | storage policy "car files are seen by the driver and car reports" |
| Other upload | Car managers upload car photos to `cars/` (separate policy; not odometer) | `src/app/(portal)/cars/manage/forms.tsx` |
| Existing files | Local copy: none in `car-files`. **Dev and customer copies: not inspected** (no access from here) | — |
| Later decision changing D-009 | **None found** in the repository (plans, handover, to-do, decision register) | — |

## Conclusion

The odometer photo is an **implemented, configurable feature (default
Optional)** that conflicts with the recorded decision D-009. No evidence
that D-009 was changed. Whether the owner approved the setting in a session
before the decision register existed can't be confirmed from the repository.

## Recommendation (for the owner's approval; nothing done)

If D-009 stands (uploads not approved):
1. On each copy, set **System settings → Vehicles → Odometer photo when
   returning** to **Off** (a setting, not code). The field disappears and no
   new photo paths are saved.
2. Then, as a separate approved live update with undo, remove the
   "drivers upload odometer photos" storage policy (or make it follow the
   setting), so uploads are refused by the database too.
3. **Keep existing files.** Before any later clean-up, the owner checks each
   copy's `car-files` bucket (Supabase → Storage) for folders other than
   `cars/`; any removal is a separate decision.

If the setting was in fact approved: record a new decision superseding D-009
and keep the feature (consider making the policy follow the setting).
