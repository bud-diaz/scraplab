-- ============================================================
-- Recommendation usage: previously both /api/recommendations and
-- /api/me/access derived "recommendations used today" from build_history
-- start rows — a count of started builds, not actual recommendation
-- calls. /api/activity-recommendations had no usage tracking (or auth) at
-- all. Track actual recommendation requests in their own table, gated by
-- an atomic per-identity daily reservation so concurrent requests can't
-- both slip through at the limit.
-- ============================================================

create table if not exists public.recommendation_usage (
  id uuid primary key default gen_random_uuid(),
  -- 'user:<uuid>' for signed-in callers, 'guest:<hashed-ip>' for guests.
  -- Never a raw identifier that could itself be treated as a foreign key.
  identity text not null,
  request_id text,
  created_at timestamptz not null default now()
);

create index if not exists idx_recommendation_usage_identity_day
  on public.recommendation_usage (identity, created_at);

-- Request-id idempotency: a retried call with the same id doesn't consume
-- a second unit of quota.
create unique index if not exists recommendation_usage_identity_request_key
  on public.recommendation_usage (identity, request_id)
  where request_id is not null;

alter table public.recommendation_usage enable row level security;
revoke all on public.recommendation_usage from public, anon, authenticated;
grant select, insert on public.recommendation_usage to service_role;

create or replace function public.reserve_recommendation_usage(
  p_identity text,
  p_daily_limit integer,
  p_request_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  -- Explicit UTC day boundary, independent of the session's timezone.
  v_day_start timestamptz := date_trunc('day', now() at time zone 'utc') at time zone 'utc';
  v_count integer;
begin
  -- Serializes concurrent requests for the same identity so two requests
  -- racing at the limit can't both be admitted.
  perform pg_advisory_xact_lock(hashtext(p_identity));

  if p_request_id is not null and exists (
    select 1 from public.recommendation_usage
    where identity = p_identity and request_id = p_request_id and created_at >= v_day_start
  ) then
    select count(*) into v_count from public.recommendation_usage
    where identity = p_identity and created_at >= v_day_start;
    return jsonb_build_object(
      'allowed', true, 'remaining', greatest(p_daily_limit - v_count, 0),
      'usedToday', v_count, 'idempotentReplay', true
    );
  end if;

  select count(*) into v_count
  from public.recommendation_usage
  where identity = p_identity and created_at >= v_day_start;

  if v_count >= p_daily_limit then
    return jsonb_build_object('allowed', false, 'remaining', 0, 'usedToday', v_count);
  end if;

  insert into public.recommendation_usage (identity, request_id) values (p_identity, p_request_id);

  return jsonb_build_object('allowed', true, 'remaining', p_daily_limit - v_count - 1, 'usedToday', v_count + 1);
end;
$$;

revoke all on function public.reserve_recommendation_usage(text, integer, text) from public, anon, authenticated;
grant execute on function public.reserve_recommendation_usage(text, integer, text) to service_role;

-- ============================================================
-- Close direct client reads of premium-gated content. The existing
-- "public read" RLS policies on activities/projects only govern row
-- visibility, not whether anon/authenticated may SELECT at all — an
-- API-side filter alone would not stop a direct PostgREST/anon-key read
-- of full premium content. All reads now go through server API
-- routes/pages using the service-role client, which enforce premium
-- gating in application code.
-- ============================================================

revoke select on public.activities from public, anon, authenticated;
revoke select on public.projects from public, anon, authenticated;
