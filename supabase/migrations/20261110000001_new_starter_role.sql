-- Staff Portal · © cmeproject. All rights reserved.
--
-- New starters: people who've joined with a general invite but don't have a
-- role yet. (On its own so the new value is saved before it's used.)

alter type public.app_role add value if not exists 'new_starter' before 'support_worker';
