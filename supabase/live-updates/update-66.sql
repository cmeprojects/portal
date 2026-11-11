-- Staff Portal · © cmeproject. All rights reserved.
-- Update 66: logo and letterhead option on contracts (on by default).
-- Safe to run again. Undo: undo-66.sql. Run update 65 first.
begin;
-- cmeprojects: each contract can carry the company logo and letterhead on
-- every page of the signed copy (on by default; chosen while it's a draft).
alter table public.contracts add column if not exists letterhead boolean not null default true;
commit;
