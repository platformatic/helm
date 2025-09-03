# Helm

Helm chart to install Platformatic on a remote Kubernetes Cluster.

For Enterprise specific instructions, see our [Enterprise
README](./README-ENTERPRISE.md)

## Requirements

The following software is required but not set as an explicit dependency of our
charts due to the vast number of ways the software could be installed.

### Prometheus CRDs

| Name | Kind | Usage | Download |
| --- | --- | --- | --- |
| podmonitors.monitoring.coreos.com | PodMonitor | We apply a PodMonitor into any namespace that wattpro applications are running in. | |
| servicemonitors.monitoring.coreos.com | ServiceMonitor | We use service monitor to track the metrics of Intelligent Command Center and Machinist. | | 

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
| `services.icc.secrets.icc_session` | TODO | "" | Yes |
| `services.icc.secrets.control_plane_keys` | TODO | "" | Yes |
| `services.icc.secrets.user_manager_session` | TODO | "" | Yes |

#### Features

| Name | Description | Default Value | Required |
| --- | --- | --- | --- |
| `services.icc.features.cache_recommendations.enable` | Enable cache recommendations | false | No |
| `services.icc.features.risk_service_dump.enable` | Enable long-term storage for the risk service | false | No |
| `services.icc.features.ffc.enable` | I don't know | false | No |
| `services.icc.features.icc_jobs.enable` | Enable default cron jobs | false | No |

#### Login methods

Configure how the Intelligent Command Center can be accessed

| Name | Description | Default Value | Required |
| --- | --- | --- | --- |
| `services.icc.login_methods.google_oauth.enable` | Enable Google OAuth | false | Yes |
| `services.icc.login_methods.google_oauth.client_id` | Required when Google is enabled | "" | No |
| `services.icc.login_methods.google_oauth.client_secret` | Required when Google is enabled | "" | No |
| `services.icc.login_methods.github_oauth.enable` | Enable Github OAuth | false | Yes |
| `services.icc.login_methods.github_oauth.client_id` | Required when Github is enabled | "" | No |
| `services.icc.login_methods.github_oauth.client_secret` | Required when Github is enabled | "" | No |

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

## Testing

```sh
helm template ./chart -f ./chart/values.yaml
```

## Pulling

#### Authenticate to GHCR

```sh
echo "${GITHUB_TOKEN}" | helm registry login ghcr.io/platformatic --username ${USERNAME} --password-stdin
```

#### Pull from GHCR

```sh
helm pull oci://ghcr.io/platformatic/helm-3 --version ${VERSION}
```

## Installing

#### Authenticate to EKS

```sh
aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${REGION} --profile ${PROFILE}
```

#### Install with Helm

```sh
helm upgrade --install --create-namespace platformatic oci://ghcr.io/platformatic/helm-3 --version ${VERSION} -n platformatic -f values.yml 
```

Available versions are found in the [container repository for our helm chart](https://github.com/orgs/platformatic/packages/container/package/helm)

## Notes

- There is a bug in Helm v3.13.1. You may need to manually upgrade to the latest version: 
  ```sh
  curl -L -s https://git.io/get_helm.sh | bash -s -- --version v3.13.2
  ```

## Links

- [Package Details](https://github.com/orgs/platformatic/packages/container/package/helm)
