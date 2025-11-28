# Kubernetes Configurations

This directory contains Kubernetes manifests and Argo CD Application definitions for cluster bootstrapping and management.

## Directory Structure

```
kubernetes/
└── argocd/
    └── bootstrap/
        ├── app-of-apps.yaml    # Root App of Apps application
        ├── kustomization.yaml  # Kustomize configuration
        ├── traefik.yaml        # Traefik ingress controller
        ├── longhorn.yaml       # Longhorn distributed storage
        ├── minio.yaml          # MinIO object storage
        └── grafana.yaml        # Grafana monitoring
```

## App of Apps Pattern

The `bootstrap-apps` Application uses the [App of Apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/) to manage multiple applications declaratively. This allows Argo CD to bootstrap the cluster with core services automatically.

### Deployment Order (Sync Waves)

Applications are deployed in the following order using sync waves:

1. **Wave 0**: Traefik (ingress controller - must be first)
2. **Wave 1**: Longhorn (storage - needed by other services)
3. **Wave 2**: MinIO (object storage)
4. **Wave 3**: Grafana (monitoring)

## Applications

### Traefik

- **Purpose**: Ingress controller and reverse proxy
- **Namespace**: `traefik-system`
- **Chart**: `traefik/traefik` (version 27.0.0)
- **Features**:
  - LoadBalancer service type (uses MetalLB)
  - Dashboard enabled at `traefik.local`
  - TLS support with Let's Encrypt
  - Prometheus metrics enabled

### Longhorn

- **Purpose**: Distributed block storage for Kubernetes
- **Namespace**: `longhorn-system`
- **Chart**: `longhorn/longhorn` (version 1.6.1)
- **Features**:
  - Default storage class enabled
  - 3 replicas by default
  - Web UI at `longhorn.local`
  - High availability storage

### MinIO

- **Purpose**: S3-compatible object storage
- **Namespace**: `minio`
- **Chart**: `minio/minio` (version 5.0.0)
- **Features**:
  - Distributed mode with 4 replicas
  - Pre-configured buckets: `argocd`, `terraform-state`
  - Web UI at `minio.local`
  - Uses Longhorn for persistence

### Grafana

- **Purpose**: Monitoring and visualization
- **Namespace**: `monitoring`
- **Chart**: `grafana/grafana` (version 7.3.7)
- **Features**:
  - Pre-configured Prometheus datasource
  - Kubernetes dashboard included
  - Web UI at `grafana.local`
  - Uses Longhorn for persistence

## Configuration

### Customizing Applications

Edit the individual application YAML files in `kubernetes/argocd/bootstrap/` to customize:

- Helm chart versions
- Resource requests/limits
- Ingress hostnames
- Storage configurations
- Replica counts

### Adding New Applications

1. Create a new Application manifest in `kubernetes/argocd/bootstrap/`
2. Add it to `kustomization.yaml`
3. Set appropriate sync wave annotation if ordering matters
4. Commit and push to the repository
5. Argo CD will automatically sync the new application

### Disabling Bootstrap

To disable automatic bootstrap deployment, set in `ansible/argocd/defaults/main-argocd.yaml`:

```yaml
argocd_bootstrap_enabled: false
```

## Ingress Configuration

All applications are configured with Traefik ingress. Ensure:

- Traefik is deployed first (sync wave 0)
- DNS entries point to the Traefik LoadBalancer IP
- cert-manager is installed if using TLS certificates

## Storage

- **Longhorn**: Provides distributed block storage
- **MinIO**: Uses Longhorn PVCs for persistence
- **Grafana**: Uses Longhorn PVCs for persistence

Ensure Longhorn is healthy before deploying services that depend on storage.

## Troubleshooting

### Applications Not Syncing

1. Check Argo CD repository connection:

   ```bash
   kubectl get secret clustercreator-repo -n argocd
   ```

2. Verify repository access:

   ```bash
   argocd repo get https://github.com/HughLardner/ClusterCreator
   ```

3. Check application status:
   ```bash
   kubectl get applications -n argocd
   argocd app get bootstrap-apps
   ```

### Helm Repository Issues

Helm repository secrets are automatically created by the Ansible playbook. Verify they exist:

```bash
kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=repository
```

### Sync Wave Issues

If applications are deploying in the wrong order, check sync wave annotations:

```bash
kubectl get applications -n argocd -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.argocd\.argoproj\.io/sync-wave}{"\n"}{end}'
```

## Secret Management

This project uses **Destination Cluster Secret Management** as recommended by Argo CD:

- **Kubernetes Secrets**: Created on the destination cluster using Sealed Secrets
- **Ansible Secrets**: Managed via Ansible Vault
- **No Hardcoded Secrets**: All secrets removed from Git-tracked files

### Secret Management Strategy

1. **Sealed Secrets** encrypt secrets that can be safely stored in Git
2. The operator decrypts them on the cluster
3. Argo CD never sees the plaintext secrets
4. Secrets are version-controlled in encrypted form

For detailed information, see:
- `secrets/README.md` - SealedSecrets creation and management
- `ansible/argocd/vault/README.md` - Ansible Vault usage

## References

- [Argo CD Declarative Setup](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/)
- [Argo CD Cluster Bootstrapping](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Argo CD Ingress Configuration](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/)
- [Argo CD Secret Management](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/)
- [Sealed Secrets Documentation](https://github.com/bitnami-labs/sealed-secrets)
