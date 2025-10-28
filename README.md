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
| `services.icc.scaler.algorithm_version` | The version of the algorithm to use | v1 | No |

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
| `services.machinist.name` | Name of all related resources | icc | No |
| `services.machinist.deploy` | Deploy Intelligent Command Center | true | No |
| `services.machinist.monitor.enable` | Monitor ICC so that it can autoscale | true | No |
| `services.machinist.image.repository` | Location of the Intelligent Command Center image | platformatic/intelligent-command-center | No |
| `services.machinist.image.tag` | The tag to deploy | latest | No |
| `services.machinist.image.pullPolicy` | When to pull an image update | IfNotPresent | No |
| `services.machinist.log_level` | The level to log ICC services | warn | No |

#### Features
| Name | Description | Default Value | Required |
| --- | --- | --- | --- |
| `services.machinist.features.event_export.enable` | Export Kubernetes events to Intelligent Command Center | false | No |

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

* Only Helm CLI >= v3.13.2 is supported
* Available versions are found in the [container repository for our helm chart](https://github.com/orgs/platformatic/packages/container/package/helm)
