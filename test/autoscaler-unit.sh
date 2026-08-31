#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CHART_DIR="$ROOT_DIR/chart"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

autoscaler_unit() {
  awk '
    $1 == "-" && $2 == "name:" && $3 == "VITE_AUTOSCALER_UNIT" { found = 1; next }
    found && $1 == "value:" { gsub(/"/, "", $2); print $2; exit }
  '
}

required_values=(
  --set-string services.icc.database_url=postgres://user:pass@db:5432
  --set-string services.icc.valkey.apps_url=redis://valkey:6379/0
  --set-string services.icc.valkey.icc_url=redis://valkey:6379/1
  --set-string services.icc.prometheus.url=http://prometheus:9090
)

default_value=$(helm template autoscaler-unit "$CHART_DIR" \
  --kube-version 1.30.0 \
  "${required_values[@]}" | autoscaler_unit)

[[ "$default_value" == 'pod' ]] || \
  fail "default autoscaler unit is $default_value, expected pod"

custom_value=$(helm template autoscaler-unit "$CHART_DIR" \
  --kube-version 1.30.0 \
  "${required_values[@]}" \
  --set-string services.icc.autoscaler_unit=task | autoscaler_unit)

[[ "$custom_value" == 'task' ]] || \
  fail "custom autoscaler unit is $custom_value, expected task"

echo 'Autoscaler unit tests passed'
