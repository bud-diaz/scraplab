-- ============================================================
-- Independent per-provider billing entitlements.
--
-- Previously sync-revenuecat/route.ts and both webhook handlers wrote
-- profiles.plan directly and unconditionally, so a lapsed/absent
-- RevenueCat entitlement could silently overwrite a Stripe-paid user's
-- Plus access (and vice versa). Track each provider's grant separately
-- and derive plan as the OR of both, so one provider losing its
-- entitlement never erases another provider's independently-verified
-- grant.
-- ============================================================

alter table public.profiles
  add column if not exists stripe_entitlement_active boolean not null default false,
  add column if not exists revenuecat_entitlement_active boolean not null default false;

-- Backfill from the previous single-winner plan_source so existing paid
-- users keep their access under the new per-provider model.
update public.profiles
set stripe_entitlement_active = true
where plan = 'plus' and plan_source = 'stripe';

update public.profiles
set revenuecat_entitlement_active = true
where plan = 'plus' and plan_source = 'revenuecat';

create or replace function public.apply_billing_reconciliation(
  p_user_id uuid,
  p_provider text,
  p_active boolean
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
begin
  if p_provider not in ('stripe', 'revenuecat') then
    raise exception 'Unknown billing provider: %', p_provider;
  end if;

  perform 1 from public.profiles where id = p_user_id for update;
  if not found then
    raise exception 'Profile not found for user %', p_user_id;
  end if;

  if p_provider = 'stripe' then
    update public.profiles set stripe_entitlement_active = p_active where id = p_user_id;
  else
    update public.profiles set revenuecat_entitlement_active = p_active where id = p_user_id;
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

revoke all on function public.apply_billing_reconciliation(uuid, text, boolean) from public, anon, authenticated;
grant execute on function public.apply_billing_reconciliation(uuid, text, boolean) to service_role;
