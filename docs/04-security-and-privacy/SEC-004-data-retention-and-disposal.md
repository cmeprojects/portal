# SEC-004: Data Retention and Disposal (draft for approval)

| Field | Value |
|---|---|
| Document ID | SEC-004 |
| Title | Data Retention and Disposal |
| Category | 04 Security and privacy |
| Version | 0.1 (proposal) |
| Status | **Draft for the owner's approval**, then a privacy adviser's check of the periods. Nothing is removed automatically until this is approved and built. |
| Owner / Reviewer / Approver | Product Owner / Privacy adviser / Product Owner |
| Created | 18 Nov 2026 (cmeprojects) |
| Related | SEC-003 (privacy), settings `records.retention_years` (7) and `records.private_retention_years` (5) |

## 1. Principles

1. Keep records as long as the law and funding bodies need, then remove them.
2. The clock starts when the relationship ends: a client archived or
   discharged, a staff member's last day.
3. **Nothing is removed without a person approving it.** The portal lists
   what is due; the owner (or a delegated manager) approves; removal is
   logged (what kind of record, how many, who approved, when; never the
   content).
4. A **hold** stops removal (complaint, incident under review, legal or
   insurance matter, request from a regulator).

## 2. Proposed periods (to be checked by the adviser)

| Records | Kept for | Starts from |
|---|---|---|
| Client records: details, contacts, services, care plans, reviews, agreements, funding, documents | `records.retention_years` (7 years) | Client archived or discharged |
| Shift notes, incidents, shifts, signatures, timesheets | 7 years | The shift date |
| Allied Health access and practitioner notes, page-opening logs | 7 years | The access ending |
| Staff private records: bank, super, TFN form, identity | `records.private_retention_years` (5 years) | Last day of work |
| Staff employment records (role, onboarding, performance, offboarding) | 7 years | Last day of work |
| Change log and access logs (who saw or changed what) | 7 years | The entry |
| Notices (bell) | 12 months | Sent |

Children's records may need longer (to age 25 or more, depending on the
state): **adviser to confirm** before any client under 18 is entered.

## 3. How removal would work (to build once approved)

1. A monthly check lists records past their period with no hold.
2. The owner gets a notice: "N client records are due for removal".
3. A Retention page shows the list (names and dates only) with Approve or
   Hold for each.
4. On approval, the records and their files are permanently deleted, and a
   tombstone row keeps the reference (CL-number), the kind of record, the
   dates and who approved.
5. Backups age out on the hosting provider's schedule (Supabase point-in-time
   recovery), which is stated in the privacy notice.

## 4. Decisions for the owner

1. Approve the periods in §2 (or change them).
2. Who can approve removals: the owner only, or delegated managers too.
3. Build the Retention page now, or before the first client reaches 7 years
   after archiving (no records are due yet).
