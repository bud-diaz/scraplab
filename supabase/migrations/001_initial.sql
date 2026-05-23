-- Enable UUID generation
create extension if not exists "pgcrypto";

-- ============================================================
-- PROFILES (extends auth.users)
-- ============================================================
create table if not exists profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  plan        text not null default 'free' check (plan in ('free', 'plus')),
  created_at  timestamptz not null default now()
);

alter table profiles enable row level security;

create policy "Users can read own profile"
  on profiles for select using (auth.uid() = id);

create policy "Users can update own profile"
  on profiles for update using (auth.uid() = id);

-- Auto-create profile on signup
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- ============================================================
-- CHILD PROFILES
-- ============================================================
create table if not exists child_profiles (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references profiles(id) on delete cascade,
  name       text,
  age        integer not null check (age >= 0 and age <= 18),
  created_at timestamptz not null default now()
);

alter table child_profiles enable row level security;

create policy "Users manage own child profiles"
  on child_profiles for all using (auth.uid() = user_id);

-- ============================================================
-- MATERIALS
-- ============================================================
create table if not exists materials (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  aliases    text[] not null default '{}',
  category   text not null,
  icon       text,
  created_at timestamptz not null default now()
);

alter table materials enable row level security;

create policy "Materials are public"
  on materials for select using (true);

-- ============================================================
-- PROJECTS
-- ============================================================
create table if not exists projects (
  id                uuid primary key default gen_random_uuid(),
  title             text not null,
  slug              text not null unique,
  description       text not null,
  age_min           integer not null default 3,
  age_max           integer not null default 12,
  time_minutes      integer not null,
  cleanup_level     text not null check (cleanup_level in ('low', 'medium', 'high')),
  supervision_level text not null check (supervision_level in ('independent', 'check_in', 'adult_assist', 'full_supervision')),
  difficulty        text not null check (difficulty in ('easy', 'medium', 'advanced')),
  safety_notes      text[] not null default '{}',
  instructions      jsonb not null default '[]',
  image_url         text,
  premium_only      boolean not null default false,
  created_at        timestamptz not null default now()
);

alter table projects enable row level security;

create policy "Projects are public"
  on projects for select using (true);

create index idx_projects_slug on projects(slug);
create index idx_projects_age on projects(age_min, age_max);

-- ============================================================
-- PROJECT MATERIALS
-- ============================================================
create table if not exists project_materials (
  id            uuid primary key default gen_random_uuid(),
  project_id    uuid not null references projects(id) on delete cascade,
  material_id   uuid not null references materials(id) on delete cascade,
  required      boolean not null default true,
  quantity_note text
);

alter table project_materials enable row level security;

create policy "Project materials are public"
  on project_materials for select using (true);

create index idx_pm_project on project_materials(project_id);
create index idx_pm_material on project_materials(material_id);

-- ============================================================
-- MATERIAL SUBSTITUTIONS
-- ============================================================
create table if not exists material_substitutions (
  id                     uuid primary key default gen_random_uuid(),
  source_material_id     uuid not null references materials(id) on delete cascade,
  replacement_material_id uuid not null references materials(id) on delete cascade,
  substitution_notes     text,
  unique (source_material_id, replacement_material_id)
);

alter table material_substitutions enable row level security;

create policy "Substitutions are public"
  on material_substitutions for select using (true);

-- ============================================================
-- SAVED PROJECTS
-- ============================================================
create table if not exists saved_projects (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references profiles(id) on delete cascade,
  project_id uuid not null references projects(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, project_id)
);

alter table saved_projects enable row level security;

create policy "Users manage own saved projects"
  on saved_projects for all using (auth.uid() = user_id);

-- ============================================================
-- BUILD HISTORY
-- ============================================================
create table if not exists build_history (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references profiles(id) on delete cascade,
  project_id        uuid not null references projects(id) on delete cascade,
  child_profile_id  uuid references child_profiles(id) on delete set null,
  completion_status text not null default 'started' check (completion_status in ('started', 'completed', 'abandoned')),
  started_at        timestamptz not null default now(),
  completed_at      timestamptz
);

alter table build_history enable row level security;

create policy "Users manage own build history"
  on build_history for all using (auth.uid() = user_id);

create index idx_bh_user on build_history(user_id, started_at desc);

-- ============================================================
-- HOUSEHOLD INVENTORY
-- ============================================================
create table if not exists household_inventory (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references profiles(id) on delete cascade,
  material_id      uuid not null references materials(id) on delete cascade,
  confidence_score numeric(3,2) check (confidence_score >= 0 and confidence_score <= 1),
  source           text not null default 'manual' check (source in ('manual', 'detected', 'saved')),
  staple_flag      boolean not null default false,
  updated_at       timestamptz not null default now(),
  unique (user_id, material_id)
);

alter table household_inventory enable row level security;

create policy "Users manage own inventory"
  on household_inventory for all using (auth.uid() = user_id);

create index idx_inv_user on household_inventory(user_id);
