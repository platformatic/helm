# Migrating from chart v3 to v4

Chart v4 changes the values structure used to configure ICC and Machinist. Do
not reuse the v3 values file and do not pass `--reuse-values` during the
upgrade. Build a new v4 values file using this guide.

This procedure keeps Workflow, skew protection, the ICC deployer, and scaler v2
disabled.

Test the upgrade in a non-production cluster first.

## Requirements

- Kubernetes 1.30 or newer. The chart refuses to install on older clusters.
- Helm 3.13.2 or newer.
- PostgreSQL, Valkey or Redis, and Prometheus reachable from the ICC Pod.
- A replacement for any Ingress or persistent storage created by chart v3. See
  [Resources removed or changed](#resources-removed-or-changed).

## 1. Back up the v3 release

Use the namespace that contains the Helm release record. It may differ from the
namespace where ICC and Machinist run.

```sh
helm list --all-namespaces

RELEASE=plt
RELEASE_NAMESPACE=default

helm get values "$RELEASE" --namespace "$RELEASE_NAMESPACE" -o yaml \
  > v3-values.yaml
helm get manifest "$RELEASE" --namespace "$RELEASE_NAMESPACE" \
  > v3-manifest.yaml
```

Also record the current image tags and back up PostgreSQL. The values backup
contains credentials, so store it securely.

## 2. Create a v4 values file

Start from a clean file and save it as `v4-values.yaml`. The following example
preserves the v3 defaults where they differ from v4 and explicitly disables
features that are not part of this migration.

```yaml
# Set this to the namespace where the v3 ICC and Machinist workloads run.
# This is required even when the Helm release record is in another namespace.
platformaticNamespace: platformatic

# Namespaces containing Watt applications managed by ICC.
applicationNamespaces:
  - platformatic

watt:
  monitor:
    enable: true
    name: plt-watt
    matchLabels:
      platformatic.dev/monitor: prometheus
    port: metrics
  scaling:
    labels:
      minimum_pods:
        name: icc.platformatic.dev/scaler-min
        default_value: "1"
      maximum_pods:
        name: icc.platformatic.dev/scaler-max
        default_value: "10"

services:
  icc:
    deploy: true
    public_url: https://icc.example.com

    # Base PostgreSQL URL without a database name.
    database_url: postgres://USER:PASSWORD@HOST:5432

    valkey:
      apps_url: redis://VALKEY_HOST:6379/0
      icc_url: redis://VALKEY_HOST:6379/1

    prometheus:
      url: http://prometheus.monitoring.svc.cluster.local:9090

    login_methods:
      github:
        enable: true
        client_id: YOUR_GITHUB_CLIENT_ID
        client_secret: YOUR_GITHUB_CLIENT_SECRET
        valid_emails: user@example.com

    # Copy these three values from the corresponding v3 secrets.
    secrets:
      icc_session: REPLACE_FROM_V3
      control_plane_keys: REPLACE_FROM_V3
      user_manager_session: REPLACE_FROM_V3

    features:
      cache:
        enable: false
      cache_recommendations:
        enable: false
      risk_service_dump:
        enable: false
      ffc:
        enable: false
      scaler_trends_learning:
        enable: false
      deployer:
        enable: false
      skew_protection:
        enable: false

    scaler:
      algorithm_version: v1
      # Preserve the v3 values. The v3 defaults were 300 and 60.
      cooldown: 300
      periodic_trigger: 60

  machinist:
    deploy: true
    features:
      event_export:
        enable: false

  workflow:
    deploy: false
```

Keep credentials and session secrets out of source control. Use the same three
session values on every upgrade. Changing them can invalidate sessions and
control-plane credentials.

### Namespace mapping

| v3 | v4 |
| --- | --- |
| `namespace` | `platformaticNamespace` |
| `podManagerServiceAccount.bindToNamespaces` | `applicationNamespaces` |
| `wattpro.monitor.namespaces` | `applicationNamespaces` |
| `wattpro.monitor.*` | `watt.monitor.*` |

Set `platformaticNamespace` explicitly to the existing workload namespace. In
v3 it defaulted to `platformatic`; in v4 an unset value resolves to the Helm
release namespace. This chart version still uses `platformatic` in several ICC
internal service URLs, so this guide assumes the workloads already run in that
namespace. Do not move a non-`platformatic` installation with this chart
version.

### ICC mapping

| v3 | v4 |
| --- | --- |
| `env.VITE_SERVER_URL` or `env.VITE_API_BASE_URL` | `public_url` |
| `env.PLT_METRICS_PROMETHEUS_URL` | `prometheus.url` |
| `env.PLT_ICC_LOGGER_LEVEL` | `log_level` |
| `monitor.enabled` | `monitor.enable` |
| `env.PLT_FEATURE_CACHE` | `features.cache.enable` |
| `env.PLT_FEATURE_CACHE_RECOMMENDATIONS` | `features.cache_recommendations.enable` |
| `env.PLT_FEATURE_RISK_SERVICE_DUMP` | `features.risk_service_dump.enable` |
| `env.PLT_FEATURE_FFC` | `features.ffc.enable` |
| `env.PLT_SCALER_COOLDOWN` | `scaler.cooldown` |
| `env.PLT_SCALER_PERIODIC_TRIGGER` | `scaler.periodic_trigger` |
| `env.PLT_SCALER_POD_MIN_*` | `watt.scaling.labels.minimum_pods.*` |
| `env.PLT_SCALER_POD_MAX_*` | `watt.scaling.labels.maximum_pods.*` |
| `secrets.PLT_ICC_SESSION_SECRET` | `secrets.icc_session` |
| `secrets.PLT_CONTROL_PLANE_SECRET_KEYS` | `secrets.control_plane_keys` |
| `secrets.PLT_USER_MANAGER_SESSION_SECRET_KEY` | `secrets.user_manager_session` |

v4 no longer uses `PLT_MAIN_SESSION_SECRET_KEY`. The chart generates the
internal ICC URLs, ports, and health checks itself; do not copy them from the
v3 file.

For GitHub or Google login, enable the method previously listed in
`VITE_SUPPORTED_LOGINS`, copy its OAuth client ID and secret, and set
`valid_emails` from the old `PLT_USER_MANAGER_SUPER_ADMIN_EMAIL` value. At least
one login method must be enabled for users to sign in.

### PostgreSQL

v3 accepted a complete URL for each ICC database. v4 accepts one URL prefix and
appends the database name for each ICC service. For example:

```yaml
database_url: postgres://icc:secret@postgres.example.com:5432
```

The base URL must not contain a database name or a trailing slash. The required
databases are `activities`, `risk_cold_storage`, `control_plane`, `cron`,
`scaler`, `trafficante`, `user_manager`, `cluster_manager`, and `compliance`.
They must exist and be accessible to the configured role. ICC applies its schema
migrations automatically when it starts. The `workflow` database is not used
while `services.workflow.deploy` is `false`.

### Valkey and login

Both `services.icc.valkey.apps_url` and `services.icc.valkey.icc_url` are
required in v4. They may point to separate servers or to separate databases on
one server.

Map the v3 GitHub or Google OAuth client ID and secret under
`services.icc.login_methods`. Do not copy the entire old `env` or `secrets`
maps; doing so can duplicate generated environment variables and leave the new
Secret keys unset.

### Machinist mapping

| v3 | v4 |
| --- | --- |
| `env.PLT_LOGGER_LEVEL` | `log_level` |
| `env.PLT_DISABLE_EVENT_EXPORT: true` | `features.event_export.enable: false` |
| `env.PLT_K8S_INSTALLED_NAMESPACE` | generated from `platformaticNamespace` |
| `monitor.enabled` | `monitor.enable` |
| `serviceAccountName` | unchanged |

## 3. Check image settings

v3 used private GHCR images by default. v4 defaults to public images. If this is
an Enterprise installation, add these settings to the same `v4-values.yaml`
file. Keep the registry credentials and use the image repositories and release
tags supplied by Platformatic:

```yaml
imagePullSecret:
  registry: ghcr.io
  user: YOUR_USER
  token: YOUR_TOKEN

services:
  icc:
    image:
      repository: ghcr.io/platformatic/plt-icc-3
      tag: YOUR_SUPPORTED_ICC_TAG
  machinist:
    image:
      repository: ghcr.io/platformatic/machinist
      tag: YOUR_SUPPORTED_MACHINIST_TAG
```

The Machinist repository changed from `plt-machinist-3` to `machinist`. Pin
release tags; do not keep the v3 `demo` tag.

## 4. Resources removed or changed

Helm deletes resources that v3 rendered and v4 no longer does. Before
upgrading, replace or preserve any resource you use:

- Ingress
- GCP `BackendConfig`
- GCP `ManagedCertificate`
- chart-managed PersistentVolumeClaims
- the Machinist HorizontalPodAutoscaler

v4 always creates an ICC HPA with CPU and memory targets of 80 percent. Map the
old ICC `autoscaling.minReplicas` and `autoscaling.maxReplicas` to
`services.icc.replicas.min` and `services.icc.replicas.max`. The Machinist HPA
has no v4 replacement.

Service settings are no longer configurable: ICC and Machinist Services are
`NodePort`, expose port 80, and route to fixed application ports. Check any load
balancer or network policy that depended on v3 service overrides.

v4 does not create PVCs. If a v3 PVC contains data you need, back it up and
move that storage outside the Helm release before upgrading.

## 5. Render and upgrade

Use the same Helm release name and release namespace as v3. Pin the exact v4
chart version that you tested.

```sh
CHART_VERSION=4.1.0

helm upgrade "$RELEASE" oci://ghcr.io/platformatic/helm \
  --version "$CHART_VERSION" \
  --namespace "$RELEASE_NAMESPACE" \
  -f v4-values.yaml \
  --dry-run

helm upgrade "$RELEASE" oci://ghcr.io/platformatic/helm \
  --version "$CHART_VERSION" \
  --namespace "$RELEASE_NAMESPACE" \
  -f v4-values.yaml
```

Review the dry-run for unexpected namespace changes. Compare it with the saved
v3 manifest to confirm the resources Helm will remove. Do not add
`--reuse-values`.

## 6. Verify

```sh
kubectl rollout status deployment/icc --namespace platformatic
kubectl rollout status deployment/machinist --namespace platformatic
helm test "$RELEASE" --namespace "$RELEASE_NAMESPACE"
```

Then confirm:

- ICC `GET /api/status` returns 200.
- Machinist `GET /status` returns 200.
- ICC and Machinist Prometheus targets are up.
- Existing users and ICC application data are present.
- The scaler still uses algorithm v1, and Watt applications keep their
  minimum and maximum replica limits.
