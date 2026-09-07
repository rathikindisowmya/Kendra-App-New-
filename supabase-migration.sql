-- KENDRA optional metadata migration
-- Keeps the current app's dynamic/imported fields available across devices
-- without changing the visible UI or replacing any existing schema columns.

alter table if exists employees add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists customers add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists products add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists suppliers add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists goods_movements add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists invoices add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists expenses add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists tasks add column if not exists kendra_meta jsonb default '{}'::jsonb;
alter table if exists documents add column if not exists kendra_meta jsonb default '{}'::jsonb;
