-- Staff Portal · © cmeproject. All rights reserved.
-- cmeprojects: each contract can carry the company logo and letterhead on
-- every page of the signed copy (on by default; chosen while it's a draft).
alter table public.contracts add column if not exists letterhead boolean not null default true;
