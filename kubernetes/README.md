# Kubernetes Configurations

This directory contains Kubernetes manifests and Argo CD Application definitions for cluster management.

## Directory Structure

```
kubernetes/
├── argocd/
│   └── services/
│       └── app-of-apps.yaml    # Root App of Apps for services
├── services/                   # Cluster infrastructure services
│   ├── traefik/
│   │   ├── application.yaml
│   │   └── values.yaml
│   ├── longhorn/
│   │   ├── application.yaml
│   │   └── values.yaml
│   ├── minio/
│   │   ├── application.yaml
│   │   └── values.yaml
│   ├── grafana/
│   │   ├── application.yaml
│   │   └── values.yaml
│   ├── kustomization.yaml
│   └── README.md
├── apps/                       # End-user applications
│   └── README.md
└── secrets/                    # Sealed Secrets
    ├── grafana-sealed-secret.yaml
    ├── minio-sealed-secret.yaml
    └── README.md
```

## Services vs Apps

### Services (`services/`)

**Services** are infrastructure components that manage or support the cluster:
- Ingress controllers (Traefik)
- Storage systems (Longhorn)
- Object storage (MinIO)
- Monitoring (Grafana)
- etc.

### Apps (`apps/`)

**Apps** are end-user applications deployed on the cluster:
- Web applications
- APIs
- Databases for applications
- etc.

## App of Apps Pattern

The `services` Application uses the [App of Apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/) to manage multiple services declaratively. This allows Argo CD to bootstrap the cluster with core services automatically.

### Deployment Order (Sync Waves)

Services are deployed in the following order using sync waves:

1. **Wave 0**: Traefik (ingress controller - must be first)
2. **Wave 1**: Longhorn (storage - needed by other services)
3. **Wave 2**: MinIO (object storage)
4. **Wave 3**: Grafana (monitoring)

## Service Configuration

Each service has its own directory with:
- `application.yaml` - Argo CD Application manifest
- `values.yaml` - Helm chart values

### Customizing Services

Edit the `values.yaml` file for each service to customize its configuration. Changes are automatically synced by Argo CD.

Example: To change Traefik replicas, edit `services/traefik/values.yaml`:

```yaml
deployment:
  replicas: 3  # Changed from 2
```

### Adding a New Service

1. Create a new directory: `kubernetes/services/your-service/`
2. Create `values.yaml` with Helm chart values
3. Create `application.yaml` with Argo CD Application manifest
4. Add the service to `services/kustomization.yaml`
5. Commit and push - Argo CD will automatically deploy it

## Current Services

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

## Ingress Configuration

All services are configured with Traefik ingress. Ensure:

- Traefik is deployed first (sync wave 0)
- DNS entries point to the Traefik LoadBalancer IP
- cert-manager is installed if using TLS certificates

## Storage

- **Longhorn**: Provides distributed block storage
- **MinIO**: Uses Longhorn PVCs for persistence
- **Grafana**: Uses Longhorn PVCs for persistence

Ensure Longhorn is healthy before deploying services that depend on storage.

## Troubleshooting

### Services Not Syncing

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
   argocd app get services
   ```

### Sync Wave Issues

If services are deploying in the wrong order, check sync wave annotations:

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
