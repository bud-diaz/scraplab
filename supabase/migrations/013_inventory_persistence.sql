-- ============================================================
-- household_inventory POST applied zod .default() values on every
-- upsert, so re-adding an existing material with only materialId
-- silently reset staple_flag to false, source to 'manual', and
-- confidence_score to null — clobbering previously scanned/starred data.
-- Replace the app-level upsert with an atomic function that only writes
-- fields actually present in the patch, and enforce staple-flag Plus
-- gating at the DB layer (previously UI-only).
-- ============================================================

create or replace function public.upsert_household_inventory(
  p_user_id uuid,
  p_material_id uuid,
  p_patch jsonb
)
returns public.household_inventory
language plpgsql
security definer
set search_path = public
as $$
declare
  v_plan text;
  v_row public.household_inventory;
begin
  if p_patch ? 'stapleFlag' and (p_patch->>'stapleFlag')::boolean then
    select plan into v_plan from public.profiles where id = p_user_id;
    if v_plan <> 'plus' then
      raise exception 'Household staples require ScrapLab Plus';
    end if;
  end if;

  insert into public.household_inventory (user_id, material_id, source, staple_flag, confidence_score, updated_at)
  values (
    p_user_id,
    p_material_id,
    coalesce(p_patch->>'source', 'manual'),
    coalesce((p_patch->>'stapleFlag')::boolean, false),
    case when p_patch ? 'confidenceScore' then (p_patch->>'confidenceScore')::numeric else null end,
    now()
  )
  on conflict (user_id, material_id) do update
  set
    source = case when p_patch ? 'source' then excluded.source else household_inventory.source end,
    staple_flag = case when p_patch ? 'stapleFlag' then excluded.staple_flag else household_inventory.staple_flag end,
    confidence_score = case when p_patch ? 'confidenceScore' then excluded.confidence_score else household_inventory.confidence_score end,
    updated_at = now()
  returning * into v_row;

  return v_row;
end;
$$;

revoke insert, update, delete on public.household_inventory from public, anon, authenticated;
revoke all on function public.upsert_household_inventory(uuid, uuid, jsonb) from public, anon, authenticated;
grant execute on function public.upsert_household_inventory(uuid, uuid, jsonb) to service_role;
