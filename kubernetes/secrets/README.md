# Kubernetes Secrets Management

This directory contains SealedSecret manifests for managing secrets securely in Git.

## Prerequisites

1. **Install kubeseal CLI**:
   ```bash
   # macOS
   brew install kubeseal
   
   # Linux
   wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
   tar -xvzf kubeseal-0.24.0-linux-amd64.tar.gz kubeseal
   sudo install -m 755 kubeseal /usr/local/bin/kubeseal
   ```

2. **Deploy Sealed Secrets Controller** (before Argo CD bootstrap):
   ```bash
   kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
   ```

3. **Retrieve the public key**:
   ```bash
   kubeseal --fetch-cert > sealed-secrets-public-key.pem
   ```

## Creating Sealed Secrets

### Option 1: Automated via Ansible (Recommended)

The easiest way is to use the Ansible playbook that reads from Ansible Vault:

```bash
# 1. Ensure Sealed Secrets controller is installed
ansible-playbook ansible/sealed-secrets-setup.yaml -e cluster_name=your-cluster

# 2. Create SealedSecrets from Ansible Vault
ansible-playbook ansible/create-sealed-secrets.yaml \
  -e @ansible/argocd/vault/main.yaml \
  --ask-vault-pass
```

This requires your vault file (`ansible/argocd/vault/main.yaml`) to contain:
```yaml
grafana_admin_password: "your-secure-password"
minio_root_user: "minioadmin"
minio_root_password: "your-secure-password"
```

### Option 2: Manual Creation

#### Grafana Admin Password

```bash
# Create the secret locally
kubectl create secret generic grafana-admin-credentials \
  --from-literal=admin-password='your-secure-password-here' \
  --namespace=monitoring \
  --dry-run=client -o yaml > /tmp/grafana-secret.yaml

# Seal it (requires access to cluster with Sealed Secrets controller)
kubeseal < /tmp/grafana-secret.yaml > kubernetes/secrets/grafana-sealed-secret.yaml

# Clean up
rm /tmp/grafana-secret.yaml
```

#### MinIO Root Credentials

```bash
# Create the secret locally
kubectl create secret generic minio-root-credentials \
  --from-literal=root-user='minioadmin' \
  --from-literal=root-password='your-secure-password-here' \
  --namespace=minio \
  --dry-run=client -o yaml > /tmp/minio-secret.yaml

# Seal it
kubeseal < /tmp/minio-secret.yaml > kubernetes/secrets/minio-sealed-secret.yaml

# Clean up
rm /tmp/minio-secret.yaml
```

## Secret Structure

Each SealedSecret should:
1. Be created in the target namespace
2. Match the secret name referenced in the application manifests
3. Contain the exact keys expected by the Helm charts

## Application References

- **Grafana**: References `grafana-admin-credentials` secret with key `admin-password`
- **MinIO**: References `minio-root-credentials` secret with keys `root-user` and `root-password`

## Security Notes

- SealedSecrets are encrypted and safe to commit to Git
- The private key is stored in the cluster (Sealed Secrets controller)
- Never commit plaintext secrets
- Rotate secrets regularly by creating new SealedSecrets

## Deployment Order

**Critical: Install Sealed Secrets Before Argo CD**

Sealed Secrets controller MUST be deployed before Argo CD because:
1. Argo CD will sync bootstrap applications (Grafana, MinIO) that reference Kubernetes Secrets
2. Those Kubernetes Secrets are created by Sealed Secrets controller from SealedSecret resources
3. If Sealed Secrets controller isn't running, the secrets won't exist and applications will fail

### Recommended Deployment Order

```bash
# 1. Install Sealed Secrets controller
ansible-playbook ansible/sealed-secrets-setup.yaml -e cluster_name=your-cluster

# 2. Create and commit SealedSecret manifests (see above)
#    - kubernetes/secrets/grafana-sealed-secret.yaml
#    - kubernetes/secrets/minio-sealed-secret.yaml

# 3. Install Argo CD
ansible-playbook ansible/argocd-setup.yaml -e cluster_name=your-cluster

# 4. Argo CD will sync:
#    - SealedSecret manifests → Sealed Secrets controller decrypts them
#    - Bootstrap applications → Reference the decrypted secrets
```

### What Happens If You Install Argo CD First?

If Argo CD is installed before Sealed Secrets:
- ✅ Argo CD will sync SealedSecret manifests (they're just YAML)
- ❌ Sealed Secrets controller won't be running to decrypt them
- ❌ Bootstrap applications will fail because secrets don't exist
- ✅ Once you install Sealed Secrets controller, it will decrypt the SealedSecrets
- ✅ Applications will then work

**So it's not fatal, but applications will be in a failed state until Sealed Secrets is installed.**

