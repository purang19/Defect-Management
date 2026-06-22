-- ============================================================================
--  DMS — Supabase schema  (run once in: Supabase Dashboard → SQL Editor → New query)
-- ============================================================================
--  Creates two tables + a Storage bucket, all locked down so ONLY logged-in
--  users can read/write. The frontend ships the public "anon" key; this RLS is
--  what actually protects the data.
-- ============================================================================

-- 1. Shared app configuration (hotels/buildings/floors/rooms + the dropdown
--    catalogs). One single row, id = 1, edited wholesale like the app does today.
create table if not exists public.app_config (
  id           int  primary key default 1,
  hotels       jsonb not null default '[]',
  descriptions jsonb not null default '[]',
  responsibles jsonb not null default '[]',
  updated_at   timestamptz not null default now(),
  constraint app_config_singleton check (id = 1)
);

-- 2. Defects. The whole defect object is stored as JSONB (`data`) so the
--    frontend shape never has to change; a few columns are pulled out for
--    ordering / future filtering.
create table if not exists public.defects (
  id          text primary key,                 -- app-generated id (uid / zite id)
  data        jsonb not null,                    -- full defect object
  created_at  bigint not null default 0,         -- epoch ms, for ordering
  created_by  uuid default auth.uid(),
  inserted_at timestamptz not null default now()
);
create index if not exists defects_created_at_idx on public.defects (created_at desc);

-- 3. Row-Level Security: authenticated users only, full access.
alter table public.app_config enable row level security;
alter table public.defects    enable row level security;

drop policy if exists app_config_rw on public.app_config;
create policy app_config_rw on public.app_config
  for all to authenticated using (true) with check (true);

drop policy if exists defects_rw on public.defects;
create policy defects_rw on public.defects
  for all to authenticated using (true) with check (true);

-- 4. Storage bucket for defect photos (public read of unguessable URLs;
--    only authenticated users can upload).
insert into storage.buckets (id, name, public)
values ('defect-photos', 'defect-photos', true)
on conflict (id) do nothing;

drop policy if exists defect_photos_read   on storage.objects;
drop policy if exists defect_photos_upload on storage.objects;

create policy defect_photos_read on storage.objects
  for select to public using (bucket_id = 'defect-photos');

create policy defect_photos_upload on storage.objects
  for insert to authenticated with check (bucket_id = 'defect-photos');

-- 5. Enable realtime (live cross-device sync) on the defects table.
alter publication supabase_realtime add table public.defects;

-- ============================================================================
--  After running this:
--   • Authentication → Users → "Add user" to create each team login
--     (or Authentication → Providers → Email → enable signups).
--   • Project Settings → API → copy the Project URL + anon public key into
--     project/config.js.
-- ============================================================================
