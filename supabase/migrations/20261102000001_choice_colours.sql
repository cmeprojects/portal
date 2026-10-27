-- Staff Portal · © cmeproject. All rights reserved.
--
-- Colour-coded dropdown choices, e.g. Risk rating: Low green … Extreme red.
-- option_colors maps a choice to one of: green, yellow, orange, red, blue, grey.

alter table public.registry_fields
  add column option_colors jsonb not null default '{}'::jsonb
    check (jsonb_typeof(option_colors) = 'object');

-- Starting colours for Engaged Care's risk register (managers can change them).
update public.registry_fields f
   set option_colors = '{"Low": "green", "Medium": "yellow", "High": "orange", "Extreme": "red"}'
  from public.registries r
 where r.id = f.registry_id and r.prefix = 'RSK' and f.key = 'risk_rating' and f.option_colors = '{}'::jsonb;

update public.registry_fields f
   set option_colors = '{"Effective": "green", "Partly effective": "orange", "Not effective": "red", "Not yet reviewed": "grey"}'
  from public.registries r
 where r.id = f.registry_id and r.prefix = 'RSK' and f.key = 'effectiveness' and f.option_colors = '{}'::jsonb;
