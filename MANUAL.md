# Installing Intelligent Command Center (ICC)

A short guide to installing ICC on Kubernetes with this Helm chart.

## 1. Prerequisites

- Kubernetes cluster, version 1.30 or newer.
- Helm 3.13.2 or newer.
- PostgreSQL reachable from the cluster (one server; ICC uses several databases
  on it, listed in section 2).
- Valkey (or Redis), reachable from the cluster.
- Prometheus, reachable from the cluster. It must scrape kubelet
  `/metrics/cadvisor` and kube-state-metrics so ICC can read container resource
  usage, requests, limits, and Pod labels. kube-state-metrics must export the
  `platformatic.dev/monitor` Pod label.
- A Kubernetes resource metrics API (`metrics.k8s.io`) for the ICC HPA.
- Prometheus Operator CRDs (`PodMonitor`, `ServiceMonitor`) installed. The
  chart renders both by default; to install without them, disable the monitors
  (`watt.monitor.enable` and the per-service `monitor.enable`).
- At least one OAuth application (GitHub or Google) for login.
- For Enterprise images: registry credentials from Platformatic.

## 2. Prepare a values file

Create `my-values.yaml`. The values below are the minimum required.

```yaml
services:
  icc:
    deploy: true

    # PostgreSQL server URL, WITHOUT a database name in the path.
    # The chart derives one URL per ICC database on this server.
    database_url: "postgres://USER:PASSWORD@HOST:5432"

    # Valkey / Redis URLs.
    valkey:
      apps_url: "redis://VALKEY_HOST:6379/0"
      icc_url:  "redis://VALKEY_HOST:6379/1"

    # Prometheus base URL.
    prometheus:
      url: "http://prometheus.monitoring.svc.cluster.local:9090"

    # The URL users will open ICC from.
    public_url: "https://icc.example.com"

    # Enable at least one login method.
    login_methods:
      github:
        enable: true
        client_id: "YOUR_GITHUB_CLIENT_ID"
        client_secret: "YOUR_GITHUB_CLIENT_SECRET"
        valid_emails: "you@example.com"   # comma-separated; these users become super admins

  machinist:
    deploy: true
```

Before installing, create these databases on the PostgreSQL server:
`activities`, `risk_cold_storage`, `control_plane`, `cron`, `scaler`,
`trafficante`, `user_manager`, `cluster_manager`, and `compliance`. They must
be accessible to the user in `database_url`. ICC applies its schema migrations
automatically when it starts. A `workflow` database is only needed if you
deploy the optional workflow service.

For Enterprise installs, also add the registry credentials and the Enterprise
image references. Without the `image` overrides the chart pulls the public
Docker Hub images and the pull secret has no effect. Use the repositories and
release tags supplied by Platformatic:

```yaml
imagePullSecret:
  registry: "<registry host>"
  user: "<user>"
  token: "<token>"

services:
  icc:
    image:
      repository: "<icc repository>"
      tag: "<icc release tag>"
  machinist:
    image:
      repository: "<machinist repository>"
      tag: "<machinist release tag>"
```

See `README-ENTERPRISE.md` for details.

Keep credentials out of source control (use a secrets manager).

## 3. Install

The chart is published as an OCI artifact at `oci://ghcr.io/platformatic/helm`.

Generate the session secrets once and store the file in your secrets manager.
You must pass it again on every upgrade, so do not lose it:

```sh
# The subshell keeps the umask change local; the file is owner-readable only.
(umask 077; cat > my-secrets.yaml <<EOF
services:
  icc:
    secrets:
      icc_session: "$(openssl rand -hex 32)"
      control_plane_keys: "$(openssl rand -hex 32)"
      user_manager_session: "$(openssl rand -base64 32)"
EOF
)
```

```sh
helm install platformatic oci://ghcr.io/platformatic/helm \
  --version "^4.1.0" \
  --namespace platformatic --create-namespace \
  -f my-values.yaml -f my-secrets.yaml
```

> Available chart versions:
> <https://github.com/orgs/platformatic/packages/container/package/helm>

## 4. Verify

```sh
# Deployments should roll out and pods reach Running / Ready.
kubectl rollout status deployment/icc -n platformatic
kubectl rollout status deployment/machinist -n platformatic

# ICC health check. The ICC image has no wget or curl, so check
# from your machine through a port-forward:
kubectl port-forward -n platformatic svc/icc 8080:80
# then, in another terminal:
curl --fail --silent --show-error http://localhost:8080/api/status
```

Run the chart's built-in smoke test:

```sh
helm test platformatic -n platformatic
```

## 5. Access ICC

Expose the `icc` Service at the `public_url` you configured, using your own
Ingress or Gateway (this chart does not create one). For a quick local check:

```sh
kubectl port-forward -n platformatic svc/icc 8080:80
# then open http://localhost:8080
```

## 6. Upgrade / uninstall

```sh
helm upgrade platformatic oci://ghcr.io/platformatic/helm \
  --version "^4.1.0" -n platformatic \
  -f my-values.yaml -f my-secrets.yaml \
  --wait --timeout 10m

helm uninstall platformatic -n platformatic
```

> Pass `my-secrets.yaml` on every upgrade. Without it Helm resets the release
> values, the ICC Secret loses its keys, and the pods fail to start; new secret
> values also sign out logged-in users. If you lose the file, recover the
> values with `helm get values platformatic -n platformatic -o yaml`.

## Troubleshooting

- `services.icc.database_url is required` (or valkey / prometheus): a required
  value is missing from `my-values.yaml`. See section 2.
- `chart requires kubeVersion: >= 1.30.0-0`: your cluster (or Helm's default
  capabilities) is below 1.30. Upgrade the cluster.
- `no matches for kind "PodMonitor"` (or `"ServiceMonitor"`): the Prometheus
  Operator CRDs are missing. Install them, or disable the monitors (section 1).
- ICC CPU metrics are empty or zero: confirm Prometheus contains
  `container_cpu_usage_seconds_total`, `kube_pod_container_resource_limits` or
  `kube_pod_container_resource_requests`, and
  `kube_pod_labels{label_platformatic_dev_monitor="prometheus"}`.
- ICC pod not ready: check `kubectl logs -n platformatic deploy/icc`; usually
  the database, Valkey, or Prometheus URL is unreachable.

For the full list of options see `README.md` (and `README-ENTERPRISE.md` for
Enterprise). Migrating from the 3.x chart? See `MIGRATING-v3-to-v4.md`.
