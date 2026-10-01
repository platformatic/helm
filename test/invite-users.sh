#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CHART_DIR="$ROOT_DIR/chart"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

invite_users() {
  awk '
    $1 == "-" && $2 == "name:" && $3 == "PLT_FEATURE_INVITE_USERS" { found = 1; next }
    found && $1 == "value:" { gsub(/["\047]/, "", $2); print $2; exit }
  '
}

required_values=(
  --set-string services.icc.database_url=postgres://user:pass@db:5432
  --set-string services.icc.valkey.apps_url=redis://valkey:6379/0
  --set-string services.icc.valkey.icc_url=redis://valkey:6379/1
  --set-string services.icc.prometheus.url=http://prometheus:9090
)

default_value=$(helm template invite-users "$CHART_DIR" \
  --kube-version 1.30.0 \
  "${required_values[@]}" | invite_users)

[[ "$default_value" == 'false' ]] || \
  fail "default invite users flag is $default_value, expected false"

enabled_value=$(helm template invite-users "$CHART_DIR" \
  --kube-version 1.30.0 \
  "${required_values[@]}" \
  --set services.icc.features.invite_users.enable=true | invite_users)

[[ "$enabled_value" == 'true' ]] || \
  fail "enabled invite users flag is $enabled_value, expected true"

# Values files written before this option existed have no invite_users key.
missing_value=$(helm template invite-users "$CHART_DIR" \
  --kube-version 1.30.0 \
  "${required_values[@]}" \
  --set services.icc.features.invite_users=null | invite_users)

[[ "$missing_value" == 'false' ]] || \
  fail "invite users flag without the key is $missing_value, expected false"

echo 'Invite users tests passed'
