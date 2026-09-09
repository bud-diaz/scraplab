-- ============================================================
-- Close two gaps found in the endpoint audit:
--
-- 1. profiles.plan / plan_source / stripe_customer_id /
--    revenuecat_app_user_id are billing authority columns. The existing
--    "Users can update own profile" RLS policy has a USING clause but no
--    WITH CHECK / column restriction, so an authenticated client could
--    UPDATE its own plan directly over PostgREST. All legitimate writes
--    already go through server routes using the service-role client,
--    which is unaffected by REVOKE (service_role bypasses grants/RLS).
--
-- 2. build_history.child_profile_id only had a single-column FK to
--    child_profiles(id), so a service-role write (which bypasses RLS)
--    could attach a build to a *different* user's child profile without
--    any error. Widening the FK to (child_profile_id, user_id) makes
--    that a foreign-key violation regardless of which role performs the
--    insert, since FK constraints are never bypassed.
-- ============================================================

revoke insert, update, delete on public.profiles from public, anon, authenticated;
drop policy if exists "Users can update own profile" on public.profiles;

alter table public.child_profiles
  add constraint child_profiles_id_user_id_key unique (id, user_id);

alter table public.build_history
  drop constraint if exists build_history_child_profile_id_fkey;

alter table public.build_history
  add constraint build_history_child_profile_id_user_id_fkey
  foreign key (child_profile_id, user_id)
  references public.child_profiles(id, user_id)
  on delete set null;

-- ============================================================
-- saved_projects currently only enforces the free-plan save limit in
-- application code (getUserPlan + isWithinLimit before insert), which is
-- a check-then-act race and does not protect a direct REST/service-role
-- write. Enforce it at the DB layer too, while keeping duplicate saves
-- idempotent (falling through to the existing unique(user_id, project_id)
-- constraint, which the API already treats as a 409) even once a
-- free-plan user is at the cap.
-- ============================================================

create or replace function public.enforce_saved_project_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing uuid;
  v_plan text;
  v_count integer;
  v_limit constant integer := 10;
begin
  select id into v_existing
  from public.saved_projects
  where user_id = new.user_id and project_id = new.project_id;

  if found then
    return new;
  end if;

  select plan into v_plan
  from public.profiles
  where id = new.user_id
  for update;

  if v_plan = 'plus' then
    return new;
  end if;

  select count(*) into v_count
  from public.saved_projects
  where user_id = new.user_id;

  if v_count >= v_limit then
    raise exception 'Saved project limit reached';
  end if;

  return new;
end;
$$;

drop trigger if exists saved_project_limit_guard on public.saved_projects;
create trigger saved_project_limit_guard
  before insert on public.saved_projects
  for each row execute function public.enforce_saved_project_limit();
