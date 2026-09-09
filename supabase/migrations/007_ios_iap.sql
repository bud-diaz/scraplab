-- Support Apple In-App Purchase (via RevenueCat) as a second purchase path
-- alongside the existing Stripe subscription, without either one clobbering
-- the other's plan grant.
alter table profiles
  add column if not exists plan_source text not null default 'stripe',
  add column if not exists revenuecat_app_user_id text unique;
