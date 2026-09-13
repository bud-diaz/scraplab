#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

read -r -p "Supabase URL (https://...supabase.co): " SUPABASE_URL
read -r -p "Supabase anon key: " SUPABASE_ANON_KEY
read -r -p "RevenueCat iOS public API key (appl_...): " REVENUECAT_IOS_API_KEY

xcconfig_url() {
  local value="$1"
  value="${value%\"}"
  value="${value#\"}"
  printf '%s\n' "${value/:\/\//:\/\$()\/}"
}

CONFIG="Config/Local.xcconfig"
umask 077
{
  printf 'SCRAPLAB_SUPABASE_URL = %s\n' "$(xcconfig_url "$SUPABASE_URL")"
  printf 'SCRAPLAB_SUPABASE_ANON_KEY = %s\n' "$SUPABASE_ANON_KEY"
  printf 'SCRAPLAB_REVENUECAT_IOS_API_KEY = %s\n' "$REVENUECAT_IOS_API_KEY"
} > "$CONFIG"

printf '\nWrote %s. It is git-ignored. Re-run make gen, then build/install ScrapLab.\n' "$CONFIG"
