-- Staff Portal · © cmeproject. All rights reserved.
-- Undo update 51: removes the template library and the setup flag. Registers
-- already added from templates stay. Safe to run again.
begin;
drop function if exists public.add_register_from_template(text);
drop table if exists public.register_templates;
delete from public.app_settings where key = 'setup.completed';
commit;
