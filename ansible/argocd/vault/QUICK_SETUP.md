# Quick Setup: Restore Argo CD Repository Password

**Note**: The token was removed from the defaults file during the secrets audit. You'll need to provide it via one of the methods below.

## Option 1: Create Ansible Vault File (Recommended)

```bash
# Optional: Set your preferred editor (if not already set)
export EDITOR=nano  # or vim, code, etc.

# Create the vault file
ansible-vault create ansible/argocd/vault/main.yaml

# When prompted, enter a vault password (remember this!)
# Your editor will open - add the following content (replace YOUR_TOKEN_HERE with your actual token):
---
# Argo CD Repository Credentials
argocd_repo_password: "YOUR_TOKEN_HERE"

# Kubernetes Secrets for Sealed Secrets
# These will be used to create SealedSecrets for applications
grafana_admin_password: "your-secure-grafana-password"
minio_root_user: "minioadmin"
minio_root_password: "your-secure-minio-password"
```

Then run the playbook with:

```bash
ansible-playbook ansible/argocd-setup.yaml \
  -e @ansible/argocd/vault/main.yaml \
  --ask-vault-pass \
  -e cluster_name=your-cluster
```

## Option 2: Use Environment Variable (Quick Test)

```bash
ansible-playbook ansible/argocd-setup.yaml \
  -e argocd_repo_password="YOUR_TOKEN_HERE" \
  -e cluster_name=your-cluster
```

## Option 3: Temporarily Add to Defaults (NOT RECOMMENDED)

If you need it temporarily for testing, you can uncomment and add it back to `ansible/argocd/defaults/main-argocd.yaml`:

```yaml
argocd_repo_password: "YOUR_TOKEN_HERE"
```

**⚠️ WARNING**: Remember to remove it again before committing to Git!

## Creating SealedSecrets from Vault

Once you have the vault file set up with all secrets, you can automatically create SealedSecrets:

```bash
# Make sure Sealed Secrets controller is installed first
ansible-playbook ansible/sealed-secrets-setup.yaml -e cluster_name=your-cluster

# Create SealedSecrets from vault
ansible-playbook ansible/create-sealed-secrets.yaml \
  -e @ansible/argocd/vault/main.yaml \
  --ask-vault-pass
```

This will:

1. Read secrets from Ansible Vault
2. Create Kubernetes Secret manifests (dry-run)
3. Encrypt them with kubeseal
4. Save to `kubernetes/secrets/` directory

## Recovering Your Token

If you need to recover the token:

1. Check your GitHub account settings → Developer settings → Personal access tokens
2. Or check your password manager if you stored it there
3. Or check the conversation history where it was originally stored

## Recommended: Use Ansible Vault

**Please use Ansible Vault** (Option 1) for security. This ensures the token is encrypted and not stored in plaintext in your repository.
