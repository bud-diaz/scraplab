-- Add Stripe customer ID to profiles for billing portal and webhook matching
alter table profiles
  add column if not exists stripe_customer_id text unique;
