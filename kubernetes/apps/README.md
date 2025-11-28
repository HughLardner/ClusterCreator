# Applications

This directory contains **end-user applications** - applications that are directly used by end users, not cluster infrastructure.

## Services vs Apps

- **Services** (`../services/`): Infrastructure components that support the cluster
- **Apps** (this directory): End-user applications deployed on the cluster

## App Structure

Each application has its own directory with:

```
app-name/
├── application.yaml  # Argo CD Application manifest
└── values.yaml       # Helm chart values (if using Helm)
```

Or for plain Kubernetes manifests:

```
app-name/
├── application.yaml  # Argo CD Application manifest
└── manifests/        # Kubernetes manifests
    ├── deployment.yaml
    ├── service.yaml
    └── ...
```

## Adding a New Application

1. Create a new directory: `kubernetes/apps/your-app/`
2. Create `application.yaml` with Argo CD Application manifest
3. Add Helm values or Kubernetes manifests as needed
4. Add the app to `kustomization.yaml` (if using Kustomize)
5. Commit and push - Argo CD will automatically deploy it

