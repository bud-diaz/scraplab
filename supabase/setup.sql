-- ============================================================
-- ScrapLab — one-shot database setup
-- Run this entire file in Supabase → SQL Editor
--
-- NOTE: this predates migrations/004_stripe.sql onward (Stripe billing
-- columns, activities, activity_materials, iOS IAP columns, and
-- 008_endpoint_access_hardening.sql's ownership/limit hardening are not
-- included below). After running this file, apply supabase/migrations/
-- 004 through the latest numbered migration to reach current schema.
-- ============================================================

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

drop policy if exists "Users can read own profile" on profiles;
create policy "Users can read own profile"
  on profiles for select using (auth.uid() = id);

-- No client-writable UPDATE policy on profiles: plan/billing columns are
-- written exclusively by server routes using the service-role client
-- (service_role bypasses RLS and grants). See migrations/008_endpoint_access_hardening.sql.
drop policy if exists "Users can update own profile" on profiles;
revoke insert, update, delete on public.profiles from public, anon, authenticated;

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
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

drop policy if exists "Users manage own child profiles" on child_profiles;
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

drop policy if exists "Materials are public" on materials;
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

drop policy if exists "Projects are public" on projects;
create policy "Projects are public"
  on projects for select using (true);

create index if not exists idx_projects_slug on projects(slug);
create index if not exists idx_projects_age on projects(age_min, age_max);

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

drop policy if exists "Project materials are public" on project_materials;
create policy "Project materials are public"
  on project_materials for select using (true);

create index if not exists idx_pm_project on project_materials(project_id);
create index if not exists idx_pm_material on project_materials(material_id);

-- ============================================================
-- MATERIAL SUBSTITUTIONS
-- ============================================================
create table if not exists material_substitutions (
  id                      uuid primary key default gen_random_uuid(),
  source_material_id      uuid not null references materials(id) on delete cascade,
  replacement_material_id uuid not null references materials(id) on delete cascade,
  substitution_notes      text,
  unique (source_material_id, replacement_material_id)
);

alter table material_substitutions enable row level security;

drop policy if exists "Substitutions are public" on material_substitutions;
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

drop policy if exists "Users manage own saved projects" on saved_projects;
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

drop policy if exists "Users manage own build history" on build_history;
create policy "Users manage own build history"
  on build_history for all using (auth.uid() = user_id);

create index if not exists idx_bh_user on build_history(user_id, started_at desc);

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

drop policy if exists "Users manage own inventory" on household_inventory;
create policy "Users manage own inventory"
  on household_inventory for all using (auth.uid() = user_id);

create index if not exists idx_inv_user on household_inventory(user_id);

-- ============================================================
-- SEED: MATERIALS
-- ============================================================
insert into materials (id, name, aliases, category, icon) values
  ('00000000-0000-0000-0000-000000000001', 'Cardboard', '{"cardboard box","corrugated cardboard","box"}', 'paper', '📦'),
  ('00000000-0000-0000-0000-000000000002', 'Toilet Paper Roll', '{"cardboard tube","paper roll","tp roll"}', 'tubes', '🧻'),
  ('00000000-0000-0000-0000-000000000003', 'Tape', '{"scotch tape","masking tape","duct tape","sticky tape"}', 'connectors', '🩹'),
  ('00000000-0000-0000-0000-000000000004', 'Markers', '{"marker","felt tip","crayons","pens"}', 'art', '🖊️'),
  ('00000000-0000-0000-0000-000000000005', 'Plastic Cup', '{"plastic cup","disposable cup","cup"}', 'containers', '🥤'),
  ('00000000-0000-0000-0000-000000000006', 'Bottle Caps', '{"bottle cap","lid","cap"}', 'containers', '🪙'),
  ('00000000-0000-0000-0000-000000000007', 'String', '{"twine","yarn","thread","cord"}', 'connectors', '🧵'),
  ('00000000-0000-0000-0000-000000000008', 'Egg Carton', '{"egg box","egg container","egg tray"}', 'containers', '🥚'),
  ('00000000-0000-0000-0000-000000000009', 'Foil', '{"aluminum foil","tin foil","silver foil"}', 'paper', '✨'),
  ('00000000-0000-0000-0000-000000000010', 'Glue', '{"glue stick","white glue","craft glue","pva glue"}', 'connectors', '🗜️'),
  ('00000000-0000-0000-0000-000000000011', 'Paper', '{"copy paper","printer paper","construction paper","newspaper"}', 'paper', '📄'),
  ('00000000-0000-0000-0000-000000000012', 'Cereal Box', '{"cereal box","food box","cardboard box"}', 'containers', '🥣'),
  ('00000000-0000-0000-0000-000000000013', 'Rubber Bands', '{"elastic band","rubber band","hair tie"}', 'connectors', '🔁'),
  ('00000000-0000-0000-0000-000000000014', 'Popsicle Sticks', '{"craft sticks","ice pop sticks","wooden sticks"}', 'wood', '🪵'),
  ('00000000-0000-0000-0000-000000000015', 'Paint', '{"acrylic paint","watercolor","tempera paint","craft paint"}', 'art', '🎨')
on conflict (id) do nothing;

-- ============================================================
-- SEED: PROJECTS (8 initial)
-- ============================================================

insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000001',
  'Cardboard Rocket Ship',
  'cardboard-rocket-ship',
  'Build a towering rocket ship from cardboard and toilet paper tubes. Decorate with foil and markers for a space-ready finish.',
  4, 10, 30, 'low', 'check_in', 'easy',
  '{"Use scissors carefully — adult should pre-cut shapes for young children","Avoid sharp edges on cardboard"}',
  '[
    {"step":1,"instruction":"Cut a large triangle from cardboard for the rocket nose cone.","tip":"Make it about as tall as a ruler for good proportions."},
    {"step":2,"instruction":"Stand two toilet paper rolls upright side by side and tape them together to form the rocket body.","tip":"Overlap by about an inch so it stays sturdy."},
    {"step":3,"instruction":"Tape the triangle nose cone to the top of the rocket body."},
    {"step":4,"instruction":"Cut two small fins from leftover cardboard and tape one to each side near the bottom."},
    {"step":5,"instruction":"Wrap a piece of foil around the rocket body and smooth it flat.","tip":"Crinkle it slightly for a metallic texture."},
    {"step":6,"instruction":"Use markers to draw windows, flames, and your astronaut''s name on the rocket.","tip":"A red and orange flame at the bottom looks great!"}
  ]'::jsonb,
  false
) on conflict (slug) do nothing;

insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000002',
  'Bottle Cap Robot',
  'bottle-cap-robot',
  'Assemble a quirky little robot from bottle caps and cardboard scraps. Give it a face and a personality!',
  5, 12, 25, 'low', 'check_in', 'easy',
  '{"Let glue dry fully before handling the finished robot","Bottle caps may have sharp edges — inspect before use"}',
  '[
    {"step":1,"instruction":"Cut a small rectangle of cardboard (about the size of your hand) for the robot body."},
    {"step":2,"instruction":"Glue two bottle caps onto the upper body as eyes.","tip":"Use more glue than you think you need — caps are heavy."},
    {"step":3,"instruction":"Glue a row of three caps across the middle as buttons or a chest panel."},
    {"step":4,"instruction":"Cut two thin strips of cardboard for arms and glue them to each side."},
    {"step":5,"instruction":"Use markers to draw a mouth, nose, and any circuit lines or details."},
    {"step":6,"instruction":"Let everything dry for 10 minutes before standing it up or playing with it.","tip":"Prop it against a cup while it dries."}
  ]'::jsonb,
  false
) on conflict (slug) do nothing;

insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000003',
  'Egg Carton Creature',
  'egg-carton-creature',
  'Turn an egg carton into a bumpy, colorful creature — could be a caterpillar, a monster, or something totally new!',
  3, 8, 20, 'medium', 'adult_assist', 'easy',
  '{"Keep paint off clothing — use an old shirt or apron","Wash hands after painting","Adult should cut the egg carton if scissors are needed"}',
  '[
    {"step":1,"instruction":"Cut the egg carton lengthwise into a strip of 6 cups — this is your creature body.","safety_note":"Adult should do this step with scissors."},
    {"step":2,"instruction":"Paint the whole strip your favourite creature colour.","tip":"Two coats gives a brighter result. Let each coat dry before adding the next."},
    {"step":3,"instruction":"While the body dries, cut two small antennae or horns from leftover cardboard."},
    {"step":4,"instruction":"Glue the antennae to the first cup (the head)."},
    {"step":5,"instruction":"Draw or paint eyes, a mouth, and spots when the base coat is dry."},
    {"step":6,"instruction":"Name your creature and show it off!","tip":"You can make a whole family using a full egg carton."}
  ]'::jsonb,
  false
) on conflict (slug) do nothing;

insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000004',
  'Cup-and-String Phone',
  'cup-and-string-phone',
  'Make a real working telephone with two cups and a piece of string. Talk to a friend across the room!',
  4, 10, 10, 'low', 'check_in', 'easy',
  '{"An adult should make the hole in the cup bottom to avoid injury","Keep the string taut during use — do not wrap around fingers or neck"}',
  '[
    {"step":1,"instruction":"Ask a grown-up to poke a small hole in the bottom of each plastic cup using a pencil or pin.","safety_note":"Adult step — sharp point required."},
    {"step":2,"instruction":"Thread one end of a long piece of string through the hole in the first cup, going from the outside in."},
    {"step":3,"instruction":"Tie a big knot at the end inside the cup so it cannot pull back through."},
    {"step":4,"instruction":"Thread the other end of the string through the second cup the same way and tie a knot."},
    {"step":5,"instruction":"Hold one cup each with a friend and walk apart until the string is tight."},
    {"step":6,"instruction":"One person talks into the cup while the other holds their cup to their ear.","tip":"The string must be straight and tight — it carries the sound vibrations!"}
  ]'::jsonb,
  false
) on conflict (slug) do nothing;

insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000005',
  'Cereal Box Puppet Theater',
  'cereal-box-puppet-theater',
  'Transform a cereal box into a mini stage. Put on a show with paper puppets behind the curtain!',
  5, 12, 45, 'low', 'check_in', 'medium',
  '{"Adult should cut the stage opening with a craft knife or strong scissors","Watch fingers when cutting"}',
  '[
    {"step":1,"instruction":"Lay the cereal box flat with the large face up. Cut a rectangle out of the center — leave a 1-inch border all around.","safety_note":"Adult should make this cut.","tip":"This rectangle is your stage opening."},
    {"step":2,"instruction":"Decorate the frame around the opening with markers — draw curtains, stars, the theater name."},
    {"step":3,"instruction":"Cut two small rectangles of paper or fabric scraps to be curtains and tape them to the inside top corners."},
    {"step":4,"instruction":"Cut paper puppets — characters, animals, trees — and tape each to a popsicle stick or strip of cardboard."},
    {"step":5,"instruction":"Prop the theater box upright. Hold puppets up through the bottom opening so they appear in the stage window."},
    {"step":6,"instruction":"Write a short play and perform it for family!","tip":"You can make ticket stubs from paper scraps for extra fun."}
  ]'::jsonb,
  false
) on conflict (slug) do nothing;

insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000006',
  'Paper Binoculars',
  'paper-binoculars',
  'Make pretend binoculars from two toilet paper rolls. Perfect for backyard bird-watching adventures.',
  3, 8, 15, 'low', 'check_in', 'easy',
  '{"Do not look at the sun through any tubes or lenses"}',
  '[
    {"step":1,"instruction":"Place two toilet paper rolls side by side so the openings line up."},
    {"step":2,"instruction":"Wrap tape around the middle where they touch to hold them together.","tip":"Go around at least three times for a sturdy grip."},
    {"step":3,"instruction":"Decorate the outside with markers — camouflage, bright colours, or a space design."},
    {"step":4,"instruction":"Punch a small hole on the outer side of each tube near one end."},
    {"step":5,"instruction":"Thread a piece of string through both holes and tie knots to make a neck strap."},
    {"step":6,"instruction":"Head outside and look for birds, bugs, or neighbours!","tip":"The closer you hold them to your eyes, the better it feels."}
  ]'::jsonb,
  false
) on conflict (slug) do nothing;

insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000007',
  'Foil Moon Rocks',
  'foil-moon-rocks',
  'Scrunch and shape aluminium foil into a collection of lumpy, shiny moon rocks. Simple, tactile, and endlessly fun.',
  3, 8, 10, 'low', 'check_in', 'easy',
  '{"Foil edges can be sharp — smooth any points with your fingers","Small pieces: supervise toddlers closely"}',
  '[
    {"step":1,"instruction":"Tear off a sheet of foil about as big as a piece of paper."},
    {"step":2,"instruction":"Scrunch the foil loosely into a ball — squeeze it until it holds its shape.","tip":"The lumpier and craggier, the more it looks like a real rock."},
    {"step":3,"instruction":"Gently press dents, craters, and ridges into the surface with your fingers."},
    {"step":4,"instruction":"Make more rocks of different sizes — a collection of five looks great."},
    {"step":5,"instruction":"Arrange your moon rocks on a dark piece of paper or a tray for a moon-surface display.","tip":"Add a small paper flag or a Lego astronaut for the full effect."}
  ]'::jsonb,
  false
) on conflict (slug) do nothing;

insert into projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only) values (
  '10000000-0000-0000-0000-000000000008',
  'Tape-and-Cardboard Marble Ramp',
  'marble-ramp',
  'Engineer a zigzag marble run using cardboard strips, tape, and a box for catching. Watch physics in action!',
  6, 12, 45, 'medium', 'check_in', 'medium',
  '{"Marbles are a choking hazard — not for children under 3","Keep marbles off the floor where people walk","Supervise closely for young builders"}',
  '[
    {"step":1,"instruction":"Cut four long strips of cardboard (about 30 cm × 5 cm each) for your ramp sections."},
    {"step":2,"instruction":"Fold each strip lengthwise along the middle to form a shallow V-channel — this guides the marble.","tip":"A 90-degree fold works best."},
    {"step":3,"instruction":"Tape the first ramp to the inside of a large open box at a gentle angle, starting near the top."},
    {"step":4,"instruction":"Tape the second ramp below and going the opposite direction, slightly lower — creating a zigzag."},
    {"step":5,"instruction":"Add the remaining ramps continuing the zigzag pattern. Place a small cup or container at the bottom to catch the marble."},
    {"step":6,"instruction":"Test by dropping a marble at the top. Adjust the angles with extra tape if the marble gets stuck.","tip":"Steeper angles = faster marble. Flatter = slower and more dramatic drops."},
    {"step":7,"instruction":"Time how fast the marble travels and experiment with different angles!","tip":"Use rubber bands stretched across the path to slow the marble down for extra challenge."}
  ]'::jsonb,
  false
) on conflict (slug) do nothing;

-- ============================================================
-- SEED: PROJECT MATERIALS (initial 8)
-- ============================================================
insert into project_materials (project_id, material_id, required, quantity_note) values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', true,  'One large flat piece'),
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', true,  '2 rolls'),
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000003', true,  'A roll of tape'),
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000004', false, null),
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000009', false, 'One sheet'),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000006', true,  'At least 5 caps'),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', true,  'Small scraps'),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000010', true,  null),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000004', false, null),
  ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000011', false, 'Small scraps'),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000008', true,  '1 carton'),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000015', true,  'Any colour'),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000010', false, null),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000004', false, null),
  ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000007', false, 'For antennae'),
  ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000005', true,  '2 cups'),
  ('10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000007', true,  'At least 3 metres'),
  ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000012', true,  '1 large box'),
  ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000004', true,  null),
  ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000003', true,  null),
  ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000011', false, 'For puppet bodies'),
  ('10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000014', false, 'For puppet handles'),
  ('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000002', true,  '2 rolls'),
  ('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000003', true,  null),
  ('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000004', false, null),
  ('10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000007', false, 'For neck strap'),
  ('10000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000009', true,  'Several sheets'),
  ('10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000001', true,  'Several strips'),
  ('10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000003', true,  'Plenty'),
  ('10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000014', false, 'For ramp supports'),
  ('10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000013', false, 'For marble obstacles');

-- ============================================================
-- SEED: MATERIAL SUBSTITUTIONS
-- ============================================================
insert into material_substitutions (source_material_id, replacement_material_id, substitution_notes) values
  ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000012', 'Flatten a cereal box for thinner but usable cardboard'),
  ('00000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000001', 'Use corrugated cardboard as a sturdier alternative'),
  ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000010', 'Glue works for flat surfaces; allow extra drying time'),
  ('00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000003', 'Tape can hold most joins while glue dries'),
  ('00000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000015', 'Paint gives more colour coverage; needs drying time'),
  ('00000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000004', 'Markers are faster and less messy than paint'),
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000011', 'Roll and tape a sheet of paper into a tube'),
  ('00000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000013', 'Loop rubber bands together to form a short string')
on conflict (source_material_id, replacement_material_id) do nothing;

-- ============================================================
-- MIGRATION 002: fix supervision levels
-- ============================================================
update projects
set supervision_level = 'check_in'
where slug in ('paper-binoculars', 'foil-moon-rocks');

-- ============================================================
-- MIGRATION 003: 25 more projects
-- ============================================================

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000009','Paper Airplane','paper-airplane','Fold a classic dart-style paper airplane and launch it across the room. A timeless activity that teaches basic aerodynamics through play.',5,12,5,'low','check_in','easy','{"Throw away from people''s faces","Use only indoors or in calm outdoor areas"}','[{"step":1,"instruction":"Start with a sheet of paper held landscape (wide side facing you). Fold it in half lengthways, then unfold so you have a centre crease.","tip":"A crisp centre crease makes everything line up later."},{"step":2,"instruction":"Fold the top-left and top-right corners down to meet the centre crease, forming a triangle at the top."},{"step":3,"instruction":"Fold the two slanted edges in to the centre crease again to make a sharper point."},{"step":4,"instruction":"Fold the whole plane in half along the centre crease so the point faces forward."},{"step":5,"instruction":"Fold each wing down so its edge aligns with the bottom of the fuselage. Repeat on the other side.","tip":"Equal wings mean a straighter flight."},{"step":6,"instruction":"Hold the fuselage near the middle and throw smoothly forward at a slight upward angle. Adjust wing tips up or down to tune the flight."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000010','Handprint Art','handprint-art','Press painted hands onto paper to create colourful prints. A wonderful keepsake craft that doubles as a sensory experience for young children.',3,7,20,'high','adult_assist','easy','{"Use only child-safe, non-toxic paint","Keep paint away from eyes and mouth","Have wet wipes or a sink ready for clean-up"}','[{"step":1,"instruction":"Cover the work surface with newspaper or an old plastic bag to protect it."},{"step":2,"instruction":"Pour a small amount of paint onto a flat tray or plate and spread it into a thin, even layer.","tip":"A foam roller works great for an even coat."},{"step":3,"instruction":"Help the child press their palm and fingers firmly into the paint, coating the whole hand."},{"step":4,"instruction":"Guide the child to press their painted hand onto the paper, holding it still for three seconds, then lift straight up.","tip":"Wiggling smears the print — lift straight up."},{"step":5,"instruction":"Repeat with different colours, rinsing hands between colours if desired."},{"step":6,"instruction":"Allow prints to dry fully (about 20 minutes), then use markers to add details like tree branches, animal features, or flower petals."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000011','Cereal Box Car','cereal-box-car','Transform an empty cereal box into a rolling toy car with bottle-cap wheels. Great for imaginative play and basic engineering thinking.',5,10,25,'low','check_in','easy','{"Adult should help with any sharp cutting","Keep small bottle caps away from children under 3"}','[{"step":1,"instruction":"Seal the open end of the cereal box with tape so you have a solid rectangular box."},{"step":2,"instruction":"Use a marker to draw windows, doors, and a windscreen on the sides and front of the box.","tip":"Draw lightly first in pencil so you can adjust before going over with marker."},{"step":3,"instruction":"Colour in the windows and any other details with markers."},{"step":4,"instruction":"Cut two pieces of string or a thin strip of cardboard, each about the width of the box, to act as axles. Thread or tape each axle across the underside of the box at the front and rear."},{"step":5,"instruction":"Push a bottle cap onto each end of both axles (or glue them flat to the underside as fixed wheels)."},{"step":6,"instruction":"Stand the car upright and give it a gentle push across a smooth surface to test the wheels.","tip":"If wheels wobble, re-tape the axles so they are parallel."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000012','Rubber Band Guitar','rubber-band-guitar','Stretch rubber bands of different thicknesses across an open cereal box to create a real-sounding mini guitar. Explore how tension and thickness change the pitch.',6,12,15,'low','check_in','easy','{"Do not snap rubber bands at people","Check bands for cracks before stretching; discard worn ones"}','[{"step":1,"instruction":"Cut a large oval or round hole in the front face of a cereal box — this is the sound hole. An adult should help with the cutting."},{"step":2,"instruction":"Decorate the box with markers to make it look like a guitar body."},{"step":3,"instruction":"Select 4–6 rubber bands of varying thicknesses."},{"step":4,"instruction":"Stretch each rubber band lengthways over the box so it crosses over the sound hole, spacing them evenly across the width.","tip":"Thicker bands make lower notes; thinner bands make higher notes."},{"step":5,"instruction":"Gently pluck each band over the hole and listen to the different tones."},{"step":6,"instruction":"Try tightening or loosening individual bands to tune your guitar, or press a finger behind a band to change its pitch."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000013','Tin Foil Boat','tin-foil-boat','Shape a piece of aluminium foil into a boat and see how many small objects it can carry before sinking. A classic engineering challenge for curious kids.',4,9,10,'low','check_in','easy','{"Use a shallow container of water on a stable surface","Supervise near water at all times"}','[{"step":1,"instruction":"Tear off a sheet of foil roughly 30 cm × 30 cm (about one foot square)."},{"step":2,"instruction":"Place the foil flat on the table and fold up each edge about 2–3 cm to form the sides of the boat.","tip":"Press the corners firmly so there are no gaps where water can sneak in."},{"step":3,"instruction":"Pinch and fold the corners neatly to seal them."},{"step":4,"instruction":"Gently lower your foil boat onto the surface of the water in a bowl or tray."},{"step":5,"instruction":"Slowly add small items (coins, pebbles, bottle caps) one at a time and count how many the boat holds."},{"step":6,"instruction":"When the boat sinks, dry the foil and experiment with a different shape — wider, higher sides — and try again to beat your record."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000014','Popsicle Stick Picture Frame','popsicle-stick-picture-frame','Glue popsicle sticks together to build a charming photo frame that makes a wonderful personalised gift.',6,12,30,'medium','check_in','easy','{"Allow glue to dry fully before handling","Keep glue away from eyes"}','[{"step":1,"instruction":"Lay four popsicle sticks in a square, overlapping at the corners. This is your frame shape."},{"step":2,"instruction":"Apply a small dot of glue to each overlapping corner and press firmly. Leave to dry for 5 minutes."},{"step":3,"instruction":"Add a second layer of four sticks on top in the opposite orientation and glue again, building up thickness and strength."},{"step":4,"instruction":"Once fully dry, decorate the frame with markers, paint, or by gluing on small scraps — bottle caps, bits of foil — for texture.","tip":"Keep decorations relatively flat so the frame can rest against a surface."},{"step":5,"instruction":"Cut or fold a favourite drawing or photo to fit behind the frame opening."},{"step":6,"instruction":"Glue a folded piece of cardboard to the back as a stand, or tape a loop of string for hanging."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000015','Toilet Roll Owl','toilet-roll-owl','Turn an empty toilet paper tube into an adorable owl with paper wings and big expressive eyes.',4,9,20,'low','check_in','easy','{"Use child-safe glue","Supervise use of scissors"}','[{"step":1,"instruction":"Gently pinch the top of the toilet paper roll and press inward on both sides to form two pointed ear tufts."},{"step":2,"instruction":"Draw or cut two large circles from paper for eyes. Colour in a smaller dark circle in the centre of each for the pupils and glue them onto the front of the roll."},{"step":3,"instruction":"Cut a small diamond shape from paper or foil, fold it in half, and glue it below the eyes as a beak."},{"step":4,"instruction":"Cut two wing shapes from paper — roughly teardrop-shaped — and draw feather lines on them with a marker."},{"step":5,"instruction":"Glue or tape the wings to the sides of the roll."},{"step":6,"instruction":"Draw feather patterns across the body of the roll with a marker, then stand your owl on a shelf and admire it.","tip":"Add feet cut from paper for extra character."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000016','Cardboard Box Playhouse','cardboard-box-playhouse','Use a large cardboard box to build a mini playhouse complete with windows and a door. Perfect for imaginative play and a rainy-day project.',4,10,45,'medium','check_in','medium','{"Adult must do all box-cutter or heavy scissor cuts","Do not allow children inside the box while cutting","Ensure the box is stable before play"}','[{"step":1,"instruction":"Stand a large cardboard box upright and make sure the bottom is sealed firmly with tape."},{"step":2,"instruction":"On one side, draw a door shape — a rectangle with a rounded top. An adult cuts three sides so the door swings open."},{"step":3,"instruction":"On the remaining sides, draw and cut out one or two window holes."},{"step":4,"instruction":"Decorate the outside with markers: add brick or stone patterns, window shutters, flower boxes, and a house number."},{"step":5,"instruction":"Decorate the inside with drawn-on shelves, pictures, or a rug outline on the floor."},{"step":6,"instruction":"Reinforce any sagging edges with strips of tape and place the playhouse on a flat surface ready for imaginative adventures.","tip":"For a roof, cut four triangular flaps from a second box and tape them together over the top."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000017','Friendship Bracelet','friendship-bracelet','Braid or knot colourful pieces of string into a bracelet to gift to a friend. A calming craft that builds fine motor skills and patience.',8,12,25,'low','check_in','easy','{"Ensure the finished bracelet is not too tight on the wrist"}','[{"step":1,"instruction":"Cut three pieces of string, each about 60 cm long. Choose different colours for a striped effect."},{"step":2,"instruction":"Hold all three strings together and tie a knot at one end, leaving a 5 cm tail. Tape or clip this end to a table so it stays put while you braid."},{"step":3,"instruction":"Spread the three strings out and begin a simple three-strand braid: right strand over the centre, then left strand over the new centre, repeating.","tip":"Keep even tension for a neat braid."},{"step":4,"instruction":"Continue braiding until the bracelet is long enough to wrap around a wrist with a couple of centimetres to spare."},{"step":5,"instruction":"Tie a knot at the end to secure the braid."},{"step":6,"instruction":"Wrap around the recipient''s wrist and tie the two end knots together. Trim any excess string."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000018','Cup Stacking Game','cup-stacking-game','Decorate plastic cups and then race to build the tallest tower or fastest pyramid. An active game that sharpens hand-eye coordination.',4,9,10,'low','check_in','easy','{"Use only on stable, flat surfaces to prevent toppling"}','[{"step":1,"instruction":"Gather at least 10 plastic cups."},{"step":2,"instruction":"Use markers to decorate each cup with patterns, faces, or colours — let creativity run wild.","tip":"Permanent markers work best on plastic; let them dry before stacking."},{"step":3,"instruction":"Practise stacking the cups into a simple pyramid: 4 cups on the bottom row, 3 on the next, then 2, then 1 on top."},{"step":4,"instruction":"Time yourself building the pyramid and then collapsing it back into a single stack."},{"step":5,"instruction":"Try different formations: a tall single tower, a star shape, or a staircase."},{"step":6,"instruction":"Challenge a friend or sibling to see who can build the tallest tower without it falling."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000019','Bottle Cap Wind Chime','bottle-cap-wind-chime','Thread painted bottle caps onto string and hang them from a popsicle stick to make a colourful wind chime that chimes in the breeze.',6,12,20,'low','check_in','easy','{"An adult should help punch holes in bottle caps","Avoid sharp edges on bent caps"}','[{"step":1,"instruction":"Collect 6–10 bottle caps and use a hammer and nail (adult only) or a hole punch to make one small hole near the edge of each cap."},{"step":2,"instruction":"Decorate the caps with paint or markers and leave to dry."},{"step":3,"instruction":"Cut 4–6 lengths of string, each between 15 and 25 cm, varying the lengths for visual interest."},{"step":4,"instruction":"Thread 1–3 bottle caps onto each string and knot below each cap so it hangs at the desired position."},{"step":5,"instruction":"Tie the strings at regular intervals along a popsicle stick or short twig."},{"step":6,"instruction":"Tie a final string across both ends of the stick to create a hanger. Hang outside or near a window and listen for the gentle clinking."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000020','Egg Carton Garden','egg-carton-garden','Paint the cups of an egg carton in bright colours and fill them with soil or cotton wool to sprout seeds — or simply turn them into flower sculptures.',4,9,25,'high','check_in','easy','{"Use non-toxic paint","Wash hands after handling soil","Keep painted items away from mouth"}','[{"step":1,"instruction":"Cut the lid off the egg carton and set it aside. You will use the bottom half with its 12 individual cups."},{"step":2,"instruction":"Paint the outside of each cup a different colour and let dry completely (about 10 minutes)."},{"step":3,"instruction":"To make flower sculptures: cut petal shapes from paper and glue them around the outside rim of each cup; push a popsicle stick through the bottom for a stem."},{"step":4,"instruction":"Alternatively, fill each cup with a small amount of damp cotton wool or potting soil."},{"step":5,"instruction":"Press 2–3 seeds (cress or sunflower work well) into each cup and lightly cover."},{"step":6,"instruction":"Place on a sunny windowsill and water lightly every day. Watch your garden sprout in just a few days!","tip":"Cress sprouts in as little as 3 days — perfect for impatient young gardeners."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000021','Paper Collage','paper-collage','Tear and cut colourful pieces of paper, then glue them together to make a vibrant picture. A wonderful open-ended art activity for toddlers and pre-schoolers.',3,7,20,'medium','adult_assist','easy','{"Use child-safe glue sticks","Supervise tearing to avoid paper cuts","Keep glue away from eyes"}','[{"step":1,"instruction":"Set out a large sheet of paper as the background and arrange a selection of colourful scrap paper, old magazine pages, or tissue paper."},{"step":2,"instruction":"Help the child tear or cut the scrap paper into small pieces — different shapes and sizes add interest."},{"step":3,"instruction":"Apply glue to the back of each piece and press it onto the background paper.","tip":"A glue stick is less messy than liquid glue for young children."},{"step":4,"instruction":"Layer pieces on top of each other, overlapping colours to discover mixing effects."},{"step":5,"instruction":"Add drawn details with markers — faces, outlines, or patterns — once the glue has dried."},{"step":6,"instruction":"Allow the finished collage to dry flat for 10 minutes before displaying."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000022','Periscope','periscope','Build a working periscope from two toilet rolls and pieces of foil to see around corners and over obstacles — just like a submarine!',7,12,30,'low','check_in','medium','{"Adult should help with any cutting","Handle foil edges carefully to avoid small cuts"}','[{"step":1,"instruction":"Tape two toilet paper rolls end to end with a strip of tape to create one long tube."},{"step":2,"instruction":"Cut two squares of foil slightly larger than the diameter of the tube."},{"step":3,"instruction":"Carefully smooth each foil square as flat and wrinkle-free as possible — this is your mirror surface."},{"step":4,"instruction":"Cut a small square viewing hole near the bottom of the tube on one side, and another near the top on the opposite side."},{"step":5,"instruction":"Angle and tape a foil square at 45° inside the tube at each end, facing the corresponding viewing hole so that light from the top hole reflects down to the bottom hole.","tip":"Getting the 45° angle right is the tricky part — check by looking through the bottom hole and adjusting until you see light from above."},{"step":6,"instruction":"Look through the lower hole while holding the tube vertically to see over walls or around the corner of a door."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000023','Cardboard Shield','cardboard-shield','Cut a shield shape from cardboard, cover it in foil for a metallic finish, and decorate it with a crest design. Perfect for imaginative battles and costume play.',5,12,25,'low','check_in','easy','{"Adult should help with cutting the cardboard","Do not use the shield to hit people or objects"}','[{"step":1,"instruction":"Draw a shield shape on a piece of flat cardboard — a classic kite shape or a rounded-bottom rectangle both work well."},{"step":2,"instruction":"An adult cuts along the outline with scissors or a craft knife."},{"step":3,"instruction":"Cover the front of the shield with foil, wrapping the edges around the back and taping them securely.","tip":"Smooth the foil from the centre outwards to reduce wrinkles and get a shiny finish."},{"step":4,"instruction":"Draw your crest design on paper — a dragon, lightning bolt, or family symbol — cut it out, and glue it to the centre of the shield."},{"step":5,"instruction":"Cut a strip of cardboard about 25 cm long and 4 cm wide. Arch it into a handle shape and tape both ends firmly to the back of the shield."},{"step":6,"instruction":"Allow all glue and tape to set, then slide your arm through the handle and head into battle."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000024','Glue String Art','glue-string-art','Dip string in craft glue and arrange it on cardboard to create stunning abstract or geometric designs. When dry, the hardened string holds its shape beautifully.',9,12,50,'high','check_in','advanced','{"Keep liquid glue away from eyes","Work on a covered surface — glue is hard to remove","Wash hands thoroughly after handling glue"}','[{"step":1,"instruction":"Cover your work surface with plastic wrap or a bin bag. Cut several lengths of string between 20 and 50 cm each."},{"step":2,"instruction":"Pour a generous pool of craft glue into a shallow dish."},{"step":3,"instruction":"Submerge a length of string in the glue and run it between two fingers to remove excess, leaving the string fully saturated but not dripping."},{"step":4,"instruction":"Arrange the string on a piece of cardboard in your chosen design — swirls, geometric angles, letters, or an abstract shape. Press gently so it adheres.","tip":"Work quickly; glue-soaked string dries faster than you expect."},{"step":5,"instruction":"Repeat with more strings, layering and crossing them to build up the design."},{"step":6,"instruction":"Leave to dry completely — at least 2 hours, ideally overnight. Once dry, the string will be stiff and hold its form. You can paint over the whole piece or leave the natural string colour."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000025','Paper Hat','paper-hat','Fold a classic newspaper-style paper hat that actually fits on your head. A quick and satisfying origami-inspired project for young crafters.',4,10,10,'low','check_in','easy','{"Use paper large enough to fit the child''s head — standard A4 may be too small; use a sheet of newspaper instead"}','[{"step":1,"instruction":"Fold a large sheet of paper in half widthways (the short way) so you have a long rectangle."},{"step":2,"instruction":"Fold it in half again lengthways, then unfold to reveal a centre crease running down the middle."},{"step":3,"instruction":"Fold the top-left and top-right corners down to meet the centre crease, forming a triangle across the top half."},{"step":4,"instruction":"Fold the bottom strip of the front layer up over the base of the triangle, then flip the hat over and repeat on the other side."},{"step":5,"instruction":"Open the hat gently from the bottom by pushing in on the sides, shaping it into a hat you can wear."},{"step":6,"instruction":"Decorate with markers — add a band, stars, or a name badge — then pop it on your head."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000026','Popsicle Stick Raft','popsicle-stick-raft','Lash or glue popsicle sticks together with string to build a raft and test how much weight it can float. A fun introduction to buoyancy and construction.',7,12,35,'medium','check_in','medium','{"Supervise near water","Use a shallow basin — not a deep bath or outdoor water feature","Allow glue to dry fully before water testing"}','[{"step":1,"instruction":"Lay 8–10 popsicle sticks side by side on a flat surface, touching, to form the deck of the raft."},{"step":2,"instruction":"Spread a line of glue across two popsicle sticks positioned perpendicular to the deck sticks, one near each end. Press the deck sticks onto these crosspieces and hold until the glue grips.","tip":"Clothes pegs or bulldog clips are excellent for holding joints while the glue dries."},{"step":3,"instruction":"Leave to dry for at least 20 minutes (or as instructed on your glue packaging)."},{"step":4,"instruction":"For extra strength, tie short lengths of string around each crosspiece and the deck sticks beside it, knotting tightly."},{"step":5,"instruction":"Make a small sail from paper and a popsicle stick mast. Glue or tape the mast to the centre of the raft."},{"step":6,"instruction":"Lower the raft gently onto water in a bowl or tray. Gradually add small items — coins, pebbles — to measure its load capacity."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000027','Toilet Roll Stamp Printing','toilet-roll-stamp-printing','Squish toilet paper rolls into different shapes and use them as stamps to print colourful patterns and pictures on paper.',3,7,15,'high','adult_assist','easy','{"Use only non-toxic, washable paint","Keep paint away from eyes and mouth","Protect clothes and surfaces before starting"}','[{"step":1,"instruction":"Cover the table with newspaper and put on an apron or old clothes."},{"step":2,"instruction":"Pour small amounts of different coloured paints onto separate flat plates or trays."},{"step":3,"instruction":"Take a toilet paper roll and, to make a heart shape, pinch the tube at the top to create two bumps and a point at the bottom."},{"step":4,"instruction":"Press the shaped end of the roll into the paint, coating the rim evenly."},{"step":5,"instruction":"Press the painted rim firmly onto paper and lift straight up to reveal the stamp.","tip":"Try other shapes: leave the roll round for circles, or pinch it flat for a rectangle."},{"step":6,"instruction":"Create a picture using multiple stamps — trees, flowers, caterpillars, or fireworks. Allow the paint to dry before touching."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000028','Painted Bottle Cap Magnets','painted-bottle-cap-magnets','Paint bottle caps with tiny designs and turn them into fridge magnets. A great way to recycle and create personalised gifts.',5,10,20,'medium','check_in','easy','{"Keep small magnets away from children under 3","Ensure paint is fully dry before sticking to the fridge","Use non-toxic paint"}','[{"step":1,"instruction":"Wash and dry the bottle caps thoroughly."},{"step":2,"instruction":"Apply a base coat of paint to the inside of each cap and leave to dry for 5 minutes."},{"step":3,"instruction":"Paint a small design on each cap: a tiny face, a star, a heart, a letter of your name, or a miniature landscape.","tip":"Use the tip of a toothpick to add fine details."},{"step":4,"instruction":"Allow the paint to dry completely."},{"step":5,"instruction":"If desired, apply a thin coat of clear craft glue on top as a sealant and leave to dry again."},{"step":6,"instruction":"Stick a small adhesive magnet to the back of each cap (or use a glue gun with adult help) and press onto the fridge to display your collection."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000029','Rubber Band Ball','rubber-band-ball','Wind rubber bands around each other to build a bouncy ball from scratch. Satisfying to make and surprisingly good at bouncing!',6,12,15,'low','check_in','easy','{"Do not snap rubber bands at people","Check bands for cracks before use","Supervise to ensure no one puts bands near their mouth"}','[{"step":1,"instruction":"Start with one rubber band and fold it over itself several times until it forms a small, tight wad — this is your core."},{"step":2,"instruction":"Stretch a second rubber band around the core in one direction, then a third in a different direction to start making it round."},{"step":3,"instruction":"Continue adding rubber bands one at a time, rotating after each one to keep the ball as round as possible.","tip":"Vary the direction of each band — think of wrapping a ball of yarn."},{"step":4,"instruction":"As the ball grows, you will need to use larger bands or double up smaller ones to stretch around the outside."},{"step":5,"instruction":"Keep adding bands until the ball reaches your desired size."},{"step":6,"instruction":"Drop it on a hard floor to test the bounce. The more tightly wound the bands, the higher it will bounce."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000030','Marble Maze','marble-maze','Design and build a marble run maze inside a cardboard box using folded card and popsicle stick barriers. Then race your marble to the finish!',8,12,45,'low','check_in','medium','{"Keep marbles away from children under 3","Work on a low, stable surface to prevent falling marbles","Adult should help with heavy-duty cutting"}','[{"step":1,"instruction":"Start with the lid of a large cardboard box or cut the sides of a box down to about 5 cm tall to create a shallow tray."},{"step":2,"instruction":"Plan your maze on paper first — sketch out a path from start to finish with bends, dead ends, and obstacles."},{"step":3,"instruction":"Cut strips of cardboard about 4 cm wide and fold a 1 cm tab along one long edge. Glue or tape the tabs to the floor of the tray to create walls and channels."},{"step":4,"instruction":"Use popsicle sticks as additional barriers, gluing them at angles to redirect the marble.","tip":"Let each wall set for a few minutes before adding the next so nothing shifts."},{"step":5,"instruction":"Mark a clear START and FINISH with a marker. Place a bottle cap at the finish as the target hole if you want."},{"step":6,"instruction":"Test the maze with a marble. If it gets stuck, adjust the walls. Challenge friends to guide the marble from start to finish by tilting the tray."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000031','Paper Puppet','paper-puppet','Draw, colour, and cut out a character from paper, then attach it to a popsicle stick handle to create a puppet for storytelling and imaginative play.',3,8,15,'low','adult_assist','easy','{"Adult should help young children with scissors","Supervise the popsicle stick handle — avoid waving it near faces"}','[{"step":1,"instruction":"Draw a character on a piece of paper — it could be an animal, a fairy, a robot, or a person. Make it big enough to hold comfortably, roughly the size of a hand."},{"step":2,"instruction":"Colour in the character using markers, making it as bright and detailed as you like."},{"step":3,"instruction":"Carefully cut around the outline of the character. An adult should help younger children with the scissors."},{"step":4,"instruction":"Flip the character over and apply a strip of glue or tape down the centre of the back."},{"step":5,"instruction":"Press a popsicle stick onto the glued area so that it sticks out below the character like a handle. Hold it in place for a minute until secure."},{"step":6,"instruction":"Once dry, use your puppet to act out a story. Try making two or three different characters to put on a full puppet show!"}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000032','Cereal Box Piggy Bank','cereal-box-piggy-bank','Transform an empty cereal box into a painted piggy bank complete with a coin slot. A fun way to teach saving while recycling.',6,12,20,'medium','check_in','easy','{"Adult should help cut the coin slot","Keep coins away from children under 3","Allow paint to dry fully before use"}','[{"step":1,"instruction":"Seal all openings of the cereal box firmly with tape so it is a solid block."},{"step":2,"instruction":"On the top of the box, draw a rectangle about 4 cm long and 0.5 cm wide — the coin slot. An adult cuts this out with a craft knife or scissors."},{"step":3,"instruction":"Paint the whole box in a solid colour — pink for a classic pig, or any colour you like. Allow to dry."},{"step":4,"instruction":"Add details with markers or extra paint: eyes, a snout (a circle), ears (cut from cardboard and taped on), and curly tail details."},{"step":5,"instruction":"If you want feet, cut four small rectangles of cardboard, fold a tab on each, and tape them to the underside."},{"step":6,"instruction":"Drop a coin through the slot to test. To retrieve savings, simply open the bottom tape seal carefully.","tip":"Write your saving goal on a sticky note and attach it to the bank for motivation."}]',false) ON CONFLICT (slug) DO NOTHING;

INSERT INTO projects (id, title, slug, description, age_min, age_max, time_minutes, cleanup_level, supervision_level, difficulty, safety_notes, instructions, premium_only)
VALUES ('10000000-0000-0000-0000-000000000033','Foil Jewellery','foil-jewellery','Mould and twist pieces of aluminium foil into shiny rings, bracelets, and pendants. No glue required — just foil and imagination.',5,10,15,'low','check_in','easy','{"Fold any sharp foil edges back to avoid scratching skin","Do not wear jewellery in water"}','[{"step":1,"instruction":"Tear off a strip of foil about 30 cm long and 5 cm wide."},{"step":2,"instruction":"Fold the strip in half lengthways, then fold again (and again if needed) until you have a narrow, sturdy band about 1 cm wide."},{"step":3,"instruction":"For a ring: wrap the band around a finger, overlap the ends, and press firmly to join. Slide off and reshape if needed.","tip":"Wrap around a marker barrel to get an even circle before putting it on."},{"step":4,"instruction":"For a bracelet: make a longer band (use two strips joined together) and wrap around the wrist, shaping it into a cuff."},{"step":5,"instruction":"For a pendant: cut a smaller square of foil and mould it around a bottle cap or fold it into a shape (star, heart). Twist a small loop of foil at the top and thread a piece of string through as a necklace cord."},{"step":6,"instruction":"Combine pieces to make a full set. Use a marker to draw patterns on the foil for extra decoration."}]',false) ON CONFLICT (slug) DO NOTHING;

-- ============================================================
-- MIGRATION 003: PROJECT MATERIALS (25 new projects)
-- ============================================================
INSERT INTO project_materials (project_id, material_id, required, quantity_note) VALUES
  ('10000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000011', true,  '1 sheet of A4 or letter-size paper'),
  ('10000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000004', false, 'For decorating'),
  ('10000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000015', true,  '2–3 colours of washable paint'),
  ('10000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000011', true,  '1 large sheet of paper'),
  ('10000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000004', false, 'For adding details after drying'),
  ('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000012', true,  '1 empty cereal box'),
  ('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000003', true,  'Several strips'),
  ('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000006', true,  '4 bottle caps for wheels'),
  ('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000004', true,  'For decoration'),
  ('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000007', false, 'For axles'),
  ('10000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000012', true,  '1 empty cereal box'),
  ('10000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000013', true,  '4–6 rubber bands of varying thickness'),
  ('10000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000004', false, 'For decorating the guitar body'),
  ('10000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000009', true,  '1 sheet approx 30 cm × 30 cm'),
  ('10000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000014', true,  '8–10 popsicle sticks'),
  ('10000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000010', true,  'Craft glue'),
  ('10000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000004', false, 'For decoration'),
  ('10000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000015', false, 'For painting the frame'),
  ('10000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000002', true,  '1 toilet paper roll'),
  ('10000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000011', true,  'Scraps for eyes, beak, and wings'),
  ('10000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000004', true,  'For drawing features'),
  ('10000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000010', false, 'Craft glue for attaching wings'),
  ('10000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000003', false, 'Tape as alternative to glue'),
  ('10000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000001', true,  '1 large cardboard box (appliance-sized ideal)'),
  ('10000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000003', true,  'Strong packing tape'),
  ('10000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000004', false, 'For decorating inside and outside'),
  ('10000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000007', true,  '3 colours of string, each 60 cm long'),
  ('10000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000005', true,  'At least 10 plastic cups'),
  ('10000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000004', true,  'Permanent markers for decoration'),
  ('10000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000006', true,  '6–10 bottle caps'),
  ('10000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000007', true,  '4–6 lengths of string (15–25 cm each) plus a hanger length'),
  ('10000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000014', false, '1 popsicle stick or short twig for the crossbar'),
  ('10000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000015', false, 'To decorate the caps'),
  ('10000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000008', true,  '1 egg carton (12-egg size)'),
  ('10000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000015', true,  'Assorted colours of paint'),
  ('10000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000014', false, 'Popsicle stick stems for flower sculptures'),
  ('10000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000011', false, 'For cutting petal shapes'),
  ('10000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000011', true,  'Assorted scraps plus 1 large background sheet'),
  ('10000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000010', true,  'Glue stick or craft glue'),
  ('10000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000004', true,  'For drawn details'),
  ('10000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000002', true,  '2 toilet paper rolls'),
  ('10000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000003', true,  'Several strips of tape'),
  ('10000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000009', true,  '2 small squares of foil (mirror surfaces)'),
  ('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000001', true,  '1 large piece of flat cardboard'),
  ('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000009', true,  'Enough foil to cover the shield face'),
  ('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000003', true,  'For securing the foil and handle'),
  ('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000004', false, 'For crest details'),
  ('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000010', false, 'To glue on a paper crest'),
  ('10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000011', false, 'For cutting out a crest design'),
  ('10000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000010', true,  'Generous amount of craft glue'),
  ('10000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000007', true,  'Several lengths of string (various colours optional)'),
  ('10000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000001', true,  '1 piece of flat cardboard as the canvas'),
  ('10000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000015', false, 'To paint the finished piece'),
  ('10000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000011', true,  '1 large sheet (newspaper or A3 recommended)'),
  ('10000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000004', false, 'For decorating the hat'),
  ('10000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000014', true,  '10–12 popsicle sticks'),
  ('10000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000007', true,  'Short lengths to lash the crosspieces'),
  ('10000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000010', true,  'Craft glue'),
  ('10000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000011', false, 'For the sail'),
  ('10000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000002', true,  '2–3 toilet paper rolls'),
  ('10000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000015', true,  'Several colours of washable paint'),
  ('10000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000011', true,  'Several sheets of paper'),
  ('10000000-0000-0000-0000-000000000028', '00000000-0000-0000-0000-000000000006', true,  '8–12 bottle caps'),
  ('10000000-0000-0000-0000-000000000028', '00000000-0000-0000-0000-000000000015', true,  'Assorted colours of paint'),
  ('10000000-0000-0000-0000-000000000028', '00000000-0000-0000-0000-000000000004', false, 'For fine details'),
  ('10000000-0000-0000-0000-000000000028', '00000000-0000-0000-0000-000000000010', false, 'Clear craft glue as sealant'),
  ('10000000-0000-0000-0000-000000000029', '00000000-0000-0000-0000-000000000013', true,  'A large collection of rubber bands in mixed sizes'),
  ('10000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000001', true,  '1 large box lid or flat box plus extra cardboard for walls'),
  ('10000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000003', true,  'Plenty of tape'),
  ('10000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000014', true,  '6–10 popsicle sticks for barriers'),
  ('10000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000006', false, '1 bottle cap as a target hole'),
  ('10000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000004', false, 'For labelling the maze path'),
  ('10000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000011', true,  '1–2 sheets of paper'),
  ('10000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000014', true,  '1 popsicle stick per puppet'),
  ('10000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000004', true,  'Markers for colouring the character'),
  ('10000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000010', false, 'Craft glue to attach stick'),
  ('10000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000003', false, 'Tape as alternative to glue'),
  ('10000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000012', true,  '1 empty cereal box'),
  ('10000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000015', true,  'Pink or any colour paint'),
  ('10000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000003', true,  'To seal the box and attach details'),
  ('10000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000001', false, 'Small scraps for ears and feet'),
  ('10000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000004', false, 'For drawing on features'),
  ('10000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000009', true,  'Several strips and squares of foil'),
  ('10000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000007', false, 'For necklace cord'),
  ('10000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000006', false, 'As a mould for pendant shapes'),
  ('10000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000004', false, 'For drawing patterns on the foil')
ON CONFLICT DO NOTHING;
