# Helm

Helm chart to install Platformatic on a remote Kubernetes Cluster.

For Enterprise specific instructions, see our [Enterprise
README](./README-ENTERPRISE.md)

Navigate:

* [Requirements](#requirements)
* [Architecture](#architecture)
* [Configuration](#configuration)
    * [Common](#common-parameters)
    * [Watt](#watt)
    * [Intelligent Command Center](#intelligent-command-center)
    * [Machinist](#machinist)
    * [Workflow](#workflow)
    * [eBPF Sandbox](#ebpf-sandbox)
* [Installation](#installation)
* [Notes](#notes)

## Requirements

The following software is required but not set as an explicit dependency of our
charts due to the vast number of ways the software could be installed.

### Prometheus CRDs

| Name | Kind | Usage | Download |
| --- | --- | --- | --- |
| podmonitors.monitoring.coreos.com | PodMonitor | We apply a PodMonitor into any namespace that wattpro applications are running in. | [From ArtifactHub](https://artifacthub.io/packages/helm/prometheus-community/prometheus-operator-crds) |
| servicemonitors.monitoring.coreos.com | ServiceMonitor | We use service monitor to track the metrics of Intelligent Command Center and Machinist. | [From ArtifactHub](https://artifacthub.io/packages/helm/prometheus-community/prometheus-operator-crds) |

### Gateway API (Skew Protection)

Skew protection uses the Kubernetes Gateway API to route requests to specific
application versions. This is **opt-in** — when disabled, ICC behaves exactly
as today with no Gateway API interaction.

When skew protection is enabled:

- **Gateway API CRDs** must be installed in the cluster (provided by the Gateway
  controller, e.g. Envoy Gateway)
- The chart grants Machinist RBAC for `gateway.networking.k8s.io` resources
  (`httproutes` and `gateways`). These rules are safe even without the CRDs
  installed — Kubernetes silently ignores RBAC rules for unknown API groups
- The Gateway API controller must support **Extended conformance**, specifically
  `RegularExpression` header matching on the `Cookie` header for session-to-version
  affinity

See the [Skew Protection Prerequisites](https://icc.platformatic.dev/skew-protection/prerequisites/)
documentation for a list of compatible Gateway API controllers.

## Architecture

The default values for this chart are in _chart/values.yaml_. This is a
production-ready set of values except for the `secrets` portion.

## Configuration

### Common parameters

| Name | Description | Value |
| --- | --- | --- |
| `platformaticNamespace` | Where to install Platformatic services | "platformatic" |
| `cloud` | Install provider-specific annotations, labels, and/or resources | "" |
| `applicationNamespaces` | Where `watt` applications will be running | [] |

### Watt

| Name | Description | Value |
| --- | --- | --- |
| `watt.monitor.enable` | Enable monitoring of watt applications so that ICC can scale them | true |
| `watt.monitor.name` | The name of the PodMonitor resource | plt-watt |
| `watt.monitor.matchLabels` | Labels that will be applied to watt applications after they connect to ICC | `platformatic.dev/monitor: "prometheus"` |
| `watt.monitor.port` | The name of the port to get metrics from | metrics |
| `watt.scaling.labels.minimum_pods.name` | The label key for minimum pod scaling | icc.platformatic.dev/scaler-min |
| `watt.scaling.labels.minimum_pods.default_value` | Minimum number of pods to scale down to if the label is not set | 1 |
| `watt.scaling.labels.maximum_pods.name` | The label key for maximum pod scaling | icc.platformatic.dev/scaler-max |
| `watt.scaling.labels.maximum_pods.default_value` | Maximum number of pods to scale up to if the label is not set | 10 |

### Intelligent Command Center

| Name | Description | Default Value | Required |
| --- | --- | --- | --- |
| `services.icc.name` | Name of all related resources | icc | No |
| `services.icc.deploy` | Deploy Intelligent Command Center | true | No |
| `services.icc.monitor.enable` | Monitor ICC so that it can autoscale | true | No |
| `services.icc.image.repository` | Location of the Intelligent Command Center image | platformatic/intelligent-command-center | No |
| `services.icc.image.tag` | The tag to deploy | latest | No |
| `services.icc.image.pullPolicy` | When to pull an image update | IfNotPresent | No |
| `services.icc.log_level` | The level to log ICC services | warn | No |
| `services.icc.public_url` | The URL to access Intelligent Command Center (Note: ingress and domain must be configured by the user | "" | Yes |
| `services.icc.database_url` | The database connection string | "" | Yes |
| `services.icc.valkey.apps_url` | Valkey connection string | "" | Yes |
| `services.icc.valkey.icc_url` | Valkey connection string | "" | Yes |
| `services.icc.prometheus.url` | Prometheus API URL | "" | Yes |
| `services.icc.secrets.icc_session` | Random value to secure sessions | "" | Yes |
| `services.icc.secrets.control_plane_keys` | Random value to secure sessions | "" | Yes |
| `services.icc.secrets.user_manager_session` | Random value to secure sessions | "" | Yes |

#### Elasticache

| Name | Description | Default Value | Required |
| --- | --- | --- | --- |
| `services.icc.elasticache.role_arn` | The role ARN | "" | No |
| `services.icc.elasticache.region` | Region the cluster is in | "" | No |
| `services.icc.elasticache.cluster_name` | Name of the Elasticache cluster | "" | No |

#### Features

| Name | Description | Default Value | Required |
| --- | --- | --- | --- |
| `services.icc.features.cache.enable` | Enable caching | false | No |
| `services.icc.features.cache_recommendations.enable` | Enable cache recommendations | false | No |
| `services.icc.features.risk_service_dump.enable` | Enable long-term storage for the risk service | false | No |
| `services.icc.features.ffc.enable` | Fussion, Fission & Cascade | false | No |
| `services.icc.features.scaler_trends_learning.enable` | Enable scaler trend learning | false | No |
| `services.icc.features.skew_protection.enable` | Enable version skew protection via Gateway API (opt-in, see [Requirements](#gateway-api-skew-protection)) | false | No |
| `services.icc.features.skew_protection.auto_cleanup` | Delete expired Deployment and Service resources | false | No |
| `services.icc.features.skew_protection.http_grace_period_ms` | Min time to keep an HTTP version draining | 1800000 | No |
| `services.icc.features.skew_protection.http_max_alive_ms` | Hard deadline for HTTP versions | 86400000 | No |
| `services.icc.features.skew_protection.workflow_grace_period_ms` | Min time to keep a workflow version draining | 3600000 | No |
| `services.icc.features.skew_protection.workflow_max_alive_ms` | Hard deadline for workflow versions | 259200000 | No |
| `services.icc.features.skew_protection.check_interval_ms` | How often to check draining versions | 60000 | No |
| `services.icc.features.skew_protection.traffic_window_ms` | Time window for traffic activity tracking | 1800000 | No |
| `services.icc.features.skew_protection.cookie_max_age` | Max age for the session cookie (seconds) | 43200 | No |

#### Scaler

| Name | Description | Default Value | Required |
| --- | --- | --- | --- |
| `services.icc.scaler.algorithm_version` | The version of the scaling algorithm to use (v1, v2) | v1 | No |
| `services.icc.scaler.cooldown` | Cooldown period in seconds between scaling operations | 15 | No |
| `services.icc.scaler.periodic_trigger` | How often to check metrics and trigger scaling decisions (seconds) | 60 | No |

#### Login methods

Configure how the Intelligent Command Center can be accessed

| Name | Description | Default Value | Required |
| --- | --- | --- | --- |
| `services.icc.login_methods.google.enable` | Enable Google OAuth | false | Yes |
| `services.icc.login_methods.google.client_id` | Required when Google is enabled | "" | No |
| `services.icc.login_methods.google.client_secret` | Required when Google is enabled | "" | No |
| `services.icc.login_methods.google.valid_emails` | Required when Google is enabled | "" | No |
| `services.icc.login_methods.github.enable` | Enable Github OAuth | false | Yes |
| `services.icc.login_methods.github.client_id` | Required when Github is enabled | "" | No |
| `services.icc.login_methods.github.client_secret` | Required when Github is enabled | "" | No |
| `services.icc.login_methods.github.valid_emails` | Required when Github is enabled | "" | No |

### Machinist

| Name | Description | Default Value | Required |
| --- | --- | --- | --- |
| `services.machinist.name` | Name of all related resources | machinist | No |
| `services.machinist.deploy` | Deploy Machinist | true | No |
| `services.machinist.monitor.enable` | Monitor Machinist so that it can autoscale | true | No |
| `services.machinist.serviceAccountName` | ServiceAccount used to manage Pods and scaling | plt-pod-manager | No |
| `services.machinist.image.repository` | Location of the Machinist image | platformatic/machinist | No |
| `services.machinist.image.tag` | The tag to deploy | latest | No |
| `services.machinist.image.pullPolicy` | When to pull an image update | IfNotPresent | No |
| `services.machinist.log_level` | The level to log Machinist services | warn | No |

#### Features
| Name | Description | Default Value | Required |
| --- | --- | --- | --- |
| `services.machinist.features.event_export.enable` | Export Kubernetes events to Intelligent Command Center | false | No |

### Workflow

The Workflow Service is a durable workflow execution engine. It is **disabled by
default** (`services.workflow.deploy: false`). When enabled, ICC is wired to it
via `PLT_WORKFLOW_URL` and the `platformatic` ServiceAccount is granted RBAC to
validate Kubernetes ServiceAccount tokens through the TokenReview API.

| Name | Description | Default Value | Required |
| --- | --- | --- | --- |
| `services.workflow.name` | Name of all related resources | workflow | No |
| `services.workflow.deploy` | Deploy the Workflow Service | false | No |
| `services.workflow.monitor.enable` | Monitor via Prometheus | true | No |
| `services.workflow.image.repository` | Location of the Workflow image | platformatic/workflow | No |
| `services.workflow.image.tag` | The tag to deploy | latest | No |
| `services.workflow.image.pullPolicy` | When to pull an image update | IfNotPresent | No |
| `services.workflow.log_level` | The level to log Workflow services | warn | No |

### eBPF Sandbox

The eBPF Sandbox Server provides per-node, eBPF-based sandbox enforcement. It is
deployed as a **DaemonSet** (one Pod per node) and is **disabled by default**
(`services.ebpfSandbox.deploy: false`).

> [!WARNING]
> The sandbox Pod runs **privileged** with `hostPID` and the `SYS_ADMIN`, `BPF`,
> `NET_ADMIN`, and `SYS_RESOURCE` capabilities, and mounts the host `cgroup`,
> `bpf`, `debugfs`, and `tracefs` filesystems. The node kernel must support BPF
> LSM. Set `disableEBPFPolicies: true` for environments without BPF LSM (e.g.
> macOS development clusters).

| Name | Description | Default Value | Required |
| --- | --- | --- | --- |
| `services.ebpfSandbox.name` | Name of all related resources | ebpf-sandbox | No |
| `services.ebpfSandbox.deploy` | Deploy the eBPF Sandbox Server | false | No |
| `services.ebpfSandbox.monitor.enable` | Monitor via Prometheus ServiceMonitor | true | No |
| `services.ebpfSandbox.image.repository` | Location of the eBPF Sandbox image | platformatic/ebpf-sandbox-server | No |
| `services.ebpfSandbox.image.tag` | The tag to deploy | latest | No |
| `services.ebpfSandbox.image.pullPolicy` | When to pull an image update | IfNotPresent | No |
| `services.ebpfSandbox.log_level` | The level to log the sandbox server | info | No |
| `services.ebpfSandbox.socketPath` | Unix socket path for sandbox communication | /var/run/platformatic-sandbox/sandbox.sock | No |
| `services.ebpfSandbox.metricsPort` | Metrics endpoint port | 8443 | No |
| `services.ebpfSandbox.bpfDir` | Directory containing compiled BPF programs | /app/bpf | No |
| `services.ebpfSandbox.cgroupBase` | Base cgroup path for Platformatic workloads | /sys/fs/cgroup/platformatic | No |
| `services.ebpfSandbox.disableEBPFPolicies` | Disable eBPF policy enforcement (uses NoopEbpfManager) | false | No |

## Installation

> [!TIP]
> We highly recommend using our install script which provides both interactive
> and non-interactive forms of installing Intelligent Command Center,
> Machinist, and a secure database configuration. Visit [our install script documentation]().

Prerequisites:

* Postgres cluster with databases configured
* Prometheus installation
* Valkey installation

This is the minimal Helm installation command with Github OAuth for the
Intelligent Command Center dashboard. Copy this into a file, update the
variables, and execute the script.

```sh
# Name of the cloud provider being deployed to. Valid values are: aws, gcp, or left empty
PLT_CLOUD_PROVIDER=""

# Connection string to Postgres cluster
PLT_DATABASE_URL=""

# The URL from which Intelligent Command Center will be available
# Note: These charts do not create or setup any Ingress
PLT_PUBLIC_URL=""

# Prometheus API URL
PLT_PROMETHEUS_URL=""

# Intelligent Command Center uses Valkey for caching. The same address can be
# used for both variables
PLT_VALKEY_APPS_ADDRESS=""
PLT_VALKEY_ICC_ADDRESS=""

# Github OAuth Credentials
GITHUB_OAUTH_CLIENT_ID=""
GITHUB_OAUTH_CLIENT_SECRET=""

helm install platformatic oci://ghcr.io/platformatic/helm \
    --version "^4.0.0" \
    --create-namespace \
    --namespace platformatic \
    --set "cloud=$PLT_CLOUD_PROVIDER" \
    --set "services.icc.database_url=$PLT_DATABASE_URL" \
    --set "services.icc.public_url=$PLT_PUBLIC_URL" \
    --set "services.icc.prometheus.url=$PLT_PROMETHEUS_URL" \
    --set "services.icc.valkey.apps_url=$PLT_VALKEY_APPS_ADDRESS" \
    --set "services.icc.valkey.icc_url=$PLT_VALKEY_ICC_ADDRESS" \
    --set "services.icc.secrets.user_manager_session=$(openssl rand -base64 32)" \
    --set "services.icc.secrets.icc_session=$(openssl rand -hex 32)" \
    --set "services.icc.secrets.control_plane_keys=$(openssl rand -hex 32)" \
    --set "services.icc.login_methods.github.enable=true" \
    --set "services.icc.login_methods.github.client_id=$GITHUB_OAUTH_CLIENT_ID" \
    --set "services.icc.login_methods.github.client_secret=$GITHUB_OAUTH_CLIENT_SECRET"
```

## Notes

* Kubernetes >= 1.30 is required (enforced by `kubeVersion` in `Chart.yaml`).
  Skew protection additionally relies on Envoy Gateway 1.4.x, whose supported
  Kubernetes range starts at 1.30.
* Only Helm CLI >= v3.13.2 is supported
* Available versions are found in the [container repository for our helm chart](https://github.com/orgs/platformatic/packages/container/package/helm)
