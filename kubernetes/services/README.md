# Cluster Services

This directory contains **cluster services** - infrastructure components that manage or support the cluster itself.

## Services vs Apps

- **Services** (this directory): Infrastructure components that support the cluster
  - Ingress controllers (Traefik)
  - Storage systems (Longhorn)
  - Object storage (MinIO)
  - Monitoring (Grafana)
  - etc.

- **Apps** (`../apps/`): End-user applications deployed on the cluster
  - Web applications
  - APIs
  - Databases for applications
  - etc.

## Service Structure

Each service has its own directory with:

```
service-name/
├── application.yaml  # Argo CD Application manifest
└── values.yaml       # Helm chart values
```

## Adding a New Service

1. Create a new directory: `kubernetes/services/your-service/`
2. Create `values.yaml` with Helm chart values
3. Create `application.yaml` with Argo CD Application manifest
4. Add the service to `kustomization.yaml`
5. Commit and push - Argo CD will automatically deploy it

## Current Services

- **traefik** - Ingress controller and reverse proxy
- **longhorn** - Distributed block storage
- **minio** - S3-compatible object storage
- **grafana** - Monitoring and visualization

## Configuration

Edit the `values.yaml` file for each service to customize its configuration. Changes are automatically synced by Argo CD.

