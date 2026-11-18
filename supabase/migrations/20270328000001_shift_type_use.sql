-- Staff Portal · © cmeproject. All rights reserved.
--
-- cmeprojects (update 142): each shift type says what it's used for: client
-- shifts, internal work (no client: office, training, meetings) or both. The
-- shift panel offers only the types that fit; Manager Administrators change it
-- on the Shift types page. Safe to run again.

alter table public.shift_types add column if not exists used_for text not null default 'client';
alter table public.shift_types drop constraint if exists shift_types_used_for_check;
alter table public.shift_types add constraint shift_types_used_for_check check (used_for in ('client', 'internal', 'both'));
update public.shift_types set used_for = 'internal' where key in ('admin', 'training', 'meeting', 'remote_work', 'on_call') and used_for = 'client';
update public.shift_types set used_for = 'both' where key = 'other' and used_for = 'client';
-- "Other": what it is, in a few words.
alter table public.shifts add column if not exists shift_type_other text not null default '';
alter table public.shifts drop constraint if exists shifts_shift_type_other_check;
alter table public.shifts add constraint shifts_shift_type_other_check check (length(shift_type_other) <= 60);
