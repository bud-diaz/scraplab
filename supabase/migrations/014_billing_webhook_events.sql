-- ============================================================
-- Webhook idempotency + event-ordering guard.
--
-- Neither billing webhook previously deduplicated retried deliveries or
-- guarded against an out-of-order event undoing a later one (e.g. a
-- redelivered stale INITIAL_PURCHASE arriving after EXPIRATION was
-- already applied). Record every processed (provider, event_id) once,
-- and track the timestamp of the last event applied per provider so a
-- stale/out-of-order event reports current state instead of reapplying.
-- ============================================================

create table if not exists public.billing_webhook_events (
  provider    text not null check (provider in ('stripe', 'revenuecat')),
  event_id    text not null,
  received_at timestamptz not null default now(),
  primary key (provider, event_id)
);

alter table public.billing_webhook_events enable row level security;
revoke all on public.billing_webhook_events from public, anon, authenticated;
grant select, insert on public.billing_webhook_events to service_role;

alter table public.profiles
  add column if not exists stripe_event_at timestamptz,
  add column if not exists revenuecat_event_at timestamptz;

-- Replaces the 3-arg version from 012_billing_reconciliation.sql with a
-- 4-arg one (extra param changes the signature, so the old overload must
-- be dropped explicitly rather than replaced in place).
drop function if exists public.apply_billing_reconciliation(uuid, text, boolean);

create or replace function public.apply_billing_reconciliation(
  p_user_id uuid,
  p_provider text,
  p_active boolean,
  p_event_time timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_stripe boolean;
  v_revenuecat boolean;
  v_plan text;
  v_plan_source text;
  v_last_event_at timestamptz;
begin
  if p_provider not in ('stripe', 'revenuecat') then
    raise exception 'Unknown billing provider: %', p_provider;
  end if;

  select case p_provider when 'stripe' then stripe_event_at else revenuecat_event_at end
  into v_last_event_at
  from public.profiles
  where id = p_user_id
  for update;

  if not found then
    raise exception 'Profile not found for user %', p_user_id;
  end if;

  if p_event_time is not null and v_last_event_at is not null and p_event_time <= v_last_event_at then
    select stripe_entitlement_active, revenuecat_entitlement_active
    into v_stripe, v_revenuecat
    from public.profiles
    where id = p_user_id;

    v_plan := case when v_stripe or v_revenuecat then 'plus' else 'free' end;
    return jsonb_build_object('status', 'stale', 'plan', v_plan);
  end if;

  if p_provider = 'stripe' then
    update public.profiles
    set stripe_entitlement_active = p_active,
        stripe_event_at = coalesce(p_event_time, stripe_event_at)
    where id = p_user_id;
  else
    update public.profiles
    set revenuecat_entitlement_active = p_active,
        revenuecat_event_at = coalesce(p_event_time, revenuecat_event_at)
    where id = p_user_id;
  end if;

  select stripe_entitlement_active, revenuecat_entitlement_active
  into v_stripe, v_revenuecat
  from public.profiles
  where id = p_user_id;

  v_plan := case when v_stripe or v_revenuecat then 'plus' else 'free' end;
  v_plan_source := case
    when v_stripe and v_revenuecat then 'stripe+revenuecat'
    when v_stripe then 'stripe'
    when v_revenuecat then 'revenuecat'
    else 'none'
  end;

  update public.profiles
  set plan = v_plan, plan_source = v_plan_source
  where id = p_user_id;

  return jsonb_build_object('status', 'applied', 'plan', v_plan);
end;
$$;

revoke all on function public.apply_billing_reconciliation(uuid, text, boolean, timestamptz) from public, anon, authenticated;
grant execute on function public.apply_billing_reconciliation(uuid, text, boolean, timestamptz) to service_role;
