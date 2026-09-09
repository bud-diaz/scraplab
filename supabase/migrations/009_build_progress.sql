-- ============================================================
-- Persist guided build start/progress/completion at the DB layer.
--
-- Previously nothing wrote to build_history except an initial POST that
-- nothing called: no start deduplication, no progress/pause persistence,
-- no completion guard. This adds:
--  - current_step, so resume picks up where the user left off.
--  - start_or_resume_build(): serialized so effect replay/request retry
--    can never create two 'started' rows for the same (user, project) —
--    enforced by a unique partial index, not just app-level dedup.
--  - update_build_progress(): locks the row, rejects further changes to
--    a terminal (completed/abandoned) build, requires the last step
--    before allowing 'completed', and preserves completed_at across
--    repeated/idempotent completion calls.
-- ============================================================

alter table public.build_history
  add column if not exists current_step integer not null default 0;

create unique index if not exists build_history_active_start_key
  on public.build_history (user_id, project_id)
  where completion_status = 'started';

create or replace function public.start_or_resume_build(
  p_user_id uuid,
  p_project_id uuid,
  p_child_profile_id uuid default null
)
returns public.build_history
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing_id uuid;
  v_build public.build_history;
begin
  select ranked.id into v_existing_id
  from (
    select id, user_id, project_id,
           row_number() over (partition by user_id, project_id order by started_at desc) as rn
    from public.build_history
    where completion_status = 'started'
  ) ranked
  where ranked.user_id = p_user_id and ranked.project_id = p_project_id and ranked.rn = 1;

  if v_existing_id is not null then
    select * into v_build from public.build_history where id = v_existing_id for update;
    return v_build;
  end if;

  begin
    insert into public.build_history (user_id, project_id, child_profile_id, completion_status, current_step)
    values (p_user_id, p_project_id, p_child_profile_id, 'started', 0)
    returning * into v_build;
    return v_build;
  exception when unique_violation then
    -- Lost the race to a concurrent start for the same (user, project);
    -- the unique partial index guarantees exactly one 'started' row.
    select * into v_build
    from public.build_history
    where user_id = p_user_id and project_id = p_project_id and completion_status = 'started'
    for update;
    return v_build;
  end;
end;
$$;

create or replace function public.update_build_progress(
  p_build_id uuid,
  p_user_id uuid,
  p_current_step integer default null,
  p_completion_status text default null
)
returns public.build_history
language plpgsql
security definer
set search_path = public
as $$
declare
  b public.build_history;
  v_total_steps integer;
begin
  select * into b
  from public.build_history
  where id = p_build_id and user_id = p_user_id
  for update;

  if not found then
    raise exception 'Build not found';
  end if;

  if b.completion_status in ('completed', 'abandoned') then
    -- A duplicate/idempotent request re-affirming the same terminal status
    -- (e.g. a retried completion PATCH) is a no-op, not an error — it must
    -- not reset completed_at. Actually trying to reopen it is rejected.
    if p_completion_status is not null and p_completion_status <> b.completion_status then
      raise exception 'Terminal build cannot change';
    end if;
    return b;
  end if;

  if p_completion_status = 'completed' then
    select jsonb_array_length(coalesce(p.instructions, '[]'::jsonb)) into v_total_steps
    from public.projects p
    where p.id = b.project_id;

    if v_total_steps is not null and v_total_steps > 0
       and coalesce(p_current_step, b.current_step) < v_total_steps - 1 then
      raise exception 'Finish the last step first';
    end if;
  end if;

  update public.build_history
  set
    current_step = coalesce(p_current_step, current_step),
    completion_status = coalesce(p_completion_status, completion_status),
    completed_at = case
      when p_completion_status = 'completed' then coalesce(b.completed_at, now())
      else completed_at
    end
  where id = p_build_id
  returning * into b;

  return b;
end;
$$;

revoke insert, update, delete on public.build_history from public, anon, authenticated;
revoke all on function public.start_or_resume_build(uuid, uuid, uuid) from public, anon, authenticated;
revoke all on function public.update_build_progress(uuid, uuid, integer, text) from public, anon, authenticated;
grant execute on function public.start_or_resume_build(uuid, uuid, uuid) to service_role;
grant execute on function public.update_build_progress(uuid, uuid, integer, text) to service_role;
