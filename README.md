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
