-- ============================================================
-- Link curated activities to a reviewed projects row with real
-- step-by-step instructions.
--
-- Activities have text ids and no instructions column — projects have
-- UUID ids and a reviewed `instructions` jsonb array. These are
-- deliberately different content types; this is an opt-in link for the
-- subset of activities that have a matching guided build, not a way to
-- relabel every activity as a project. No rows are populated here —
-- linking is a curation decision made per-activity, separate from this
-- schema change. ON DELETE SET NULL means a removed project can never
-- leave a dangling reference.
-- ============================================================

alter table public.activities
  add column if not exists project_id uuid references public.projects(id) on delete set null;

create index if not exists idx_activities_project_id on public.activities (project_id);
