#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CHART_DIR="$ROOT_DIR/chart"
FIXTURE="$ROOT_DIR/test/fixtures/database-urls.yaml"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

secret_value() {
  local manifest=$1
  local key=$2
  local encoded

  encoded=$(awk -v key="\"$key\":" '
    $0 == "  name: icc-databases" { in_secret = 1; next }
    in_secret && $0 == "---" { in_secret = 0 }
    in_secret && $1 == key { print $2; exit }
  ' <<< "$manifest")

  [[ -n "$encoded" ]] || return 1
  printf '%s' "$encoded" | base64 --decode
}

assert_secret_value() {
  local manifest=$1
  local key=$2
  local expected=$3
  local actual

  actual=$(secret_value "$manifest" "$key") || fail "missing icc-databases key $key"
  [[ "$actual" == "$expected" ]] || fail "$key is $actual, expected $expected"
}

assert_env_secret_key() {
  local manifest=$1
  local env_name=$2
  local expected=$3
  local actual

  actual=$(awk -v env_name="$env_name" '
    $1 == "-" && $2 == "name:" && $3 == env_name { in_env = 1; next }
    in_env && $1 == "key:" { gsub(/"/, "", $2); print $2; exit }
  ' <<< "$manifest")

  [[ "$actual" == "$expected" ]] || \
    fail "$env_name references $actual, expected $expected"
}

common_values=(
  --set-string services.icc.valkey.apps_url=redis://valkey:6379/0
  --set-string services.icc.valkey.icc_url=redis://valkey:6379/1
  --set-string services.icc.prometheus.url=http://prometheus:9090
)

base_manifest=$(helm template database-base "$CHART_DIR" \
  --kube-version 1.30.0 \
  "${common_values[@]}" \
  --set-string services.icc.database_url=postgresql://shared:secret@db:5432)

assert_secret_value "$base_manifest" activities \
  postgresql://shared:secret@db:5432/activities
assert_secret_value "$base_manifest" cold_storage \
  postgresql://shared:secret@db:5432/risk_cold_storage
assert_secret_value "$base_manifest" traffic_inspector \
  postgresql://shared:secret@db:5432/trafficante
assert_secret_value "$base_manifest" risk_cold_storage \
  postgresql://shared:secret@db:5432/risk_cold_storage
assert_secret_value "$base_manifest" workflow \
  postgresql://shared:secret@db:5432/workflow

mixed_manifest=$(helm template database-mixed "$CHART_DIR" \
  --kube-version 1.30.0 \
  "${common_values[@]}" \
  --set-string services.icc.database_url=postgresql://shared:secret@db:5432 \
  --set-string services.icc.database_urls.activities=postgresql://activities_user:secret@db:5432/plt_activities)

assert_secret_value "$mixed_manifest" activities \
  postgresql://activities_user:secret@db:5432/plt_activities
assert_secret_value "$mixed_manifest" cold_storage \
  postgresql://shared:secret@db:5432/risk_cold_storage

migration_manifest=$(helm template database-migration "$CHART_DIR" \
  --kube-version 1.30.0 \
  -f "$FIXTURE")

helm lint "$CHART_DIR" -f "$FIXTURE" >/dev/null

for database in \
  activities cluster_manager cold_storage compliance control_plane cron scaler \
  trafficante traffic_inspector user_manager; do
  expected=$(awk -v key="$database:" '$1 == key { print $2; exit }' "$FIXTURE")
  assert_secret_value "$migration_manifest" "$database" "$expected"
  env_name="PLT_$(printf '%s' "$database" | tr '[:lower:]' '[:upper:]')_DATABASE_URL"
  assert_env_secret_key "$migration_manifest" "$env_name" "$database"
done

if secret_value "$migration_manifest" workflow >/dev/null; then
  fail 'workflow database rendered without an exact or base URL'
fi

trafficante_fallback_manifest=$(helm template trafficante-fallback "$CHART_DIR" \
  --kube-version 1.30.0 \
  -f "$FIXTURE" \
  --set-string services.icc.database_urls.traffic_inspector=)

assert_secret_value "$trafficante_fallback_manifest" traffic_inspector \
  postgresql://trafficante_user:secret@db:5432/plt_trafficante

if helm template workflow-missing-database "$CHART_DIR" \
  --kube-version 1.30.0 \
  -f "$FIXTURE" \
  --set services.workflow.deploy=true >/dev/null 2>&1; then
  fail 'workflow rendered without a workflow database URL or base URL'
fi

workflow_manifest=$(helm template workflow-database "$CHART_DIR" \
  --kube-version 1.30.0 \
  -f "$FIXTURE" \
  --set services.workflow.deploy=true \
  --set-string services.icc.database_urls.workflow=postgresql://workflow_user:secret@db:5432/plt_workflow)

assert_secret_value "$workflow_manifest" workflow \
  postgresql://workflow_user:secret@db:5432/plt_workflow

echo 'Database URL tests passed'
