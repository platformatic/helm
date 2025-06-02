# Helm

Helm chart to install Platformatic on a remote Kubernetes Cluster.

## Testing
```
helm template ./chart -f values.example.yml
```

## Pulling
#### Authenticate to GHCR
```
echo "${GITHUB_TOKEN}" | helm registry login ghcr.io/platformatic --username ${USERNAME} --password-stdin
```

#### Pull from GHCR
```
helm pull oci://ghcr.io/platformatic/helm-3 --version ${VERSION}
```

## Installing
#### Authenticate to EKS
```
aws eks update-kubeconfig --name ${CLUSTER_NAME} --region ${REGION} --profile ${PROFILE}
```

#### Install with Helm
```
helm upgrade --install --create-namespace platformatic oci://ghcr.io/platformatic/helm-3 --version ${VERSION} -n platformatic -f values.yml 
```
- `${VERSION}` can be found [here](https://github.com/orgs/platformatic/packages/container/package/helm).

## Notes
- There is a bug in Helm v3.13.1. You may need to manually upgrade to the latest version: 
```
curl -L -s https://git.io/get_helm.sh | bash -s -- --version v3.13.2
```

## Links
- [Package Details](https://github.com/orgs/platformatic/packages/container/package/helm)
