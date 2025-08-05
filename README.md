# Helm

Helm chart to install Platformatic on a remote Kubernetes Cluster.

## Architecture

The default values for this chart are in _chart/values.yaml_. This is a
production-ready set of values except for the `secrets` portion.

The values for development live in a separate yaml (_chart/values.dev.yaml_) and
are meant to be applied on-top of the default values. This allows for overriding
key settings.

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
