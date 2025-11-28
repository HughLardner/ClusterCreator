# Migration from Ansible Templates to Helm Values Files

## What Changed

We've restructured the Kubernetes configurations to use a cleaner GitOps approach:

### Before (Ansible Templates)
- Ansible templates generated manifests
- Configuration in Ansible variable files
- Required running Ansible to update configurations

### After (Helm Values Files)
- Helm values files directly in Git
- Argo CD references values files directly
- Edit YAML files directly, no Ansible needed

## New Structure

```
kubernetes/
├── services/          # Cluster infrastructure services
│   ├── traefik/
│   │   ├── application.yaml  # Argo CD Application
│   │   └── values.yaml      # Helm values
│   ├── longhorn/
│   ├── minio/
│   └── grafana/
└── apps/              # End-user applications (future)
```

## Migration Steps

1. **Old files to remove** (after verifying new structure works):
   - `kubernetes/argocd/bootstrap/*.yaml` (old manifests)
   - These can be removed once the new `services/` structure is confirmed working

2. **Update Argo CD**:
   - The Ansible playbook now creates the `services` Application instead of `bootstrap-apps`
   - This points to `kubernetes/argocd/services/app-of-apps.yaml`
   - Which in turn manages all services in `kubernetes/services/`

## Benefits

1. **Simpler**: Edit YAML files directly, no Ansible needed
2. **GitOps**: All configuration in Git, version controlled
3. **Clear separation**: Services (infrastructure) vs Apps (end-user)
4. **Standard**: Uses standard Helm values files
5. **Easier to maintain**: No template generation step

## Next Steps

1. Test the new structure by deploying to a cluster
2. Verify Argo CD can read the values files correctly
3. Remove old `kubernetes/argocd/bootstrap/` directory
4. Start adding end-user applications to `kubernetes/apps/`

