# Ansible Vault for Argo CD Secrets

This directory contains Ansible Vault-encrypted secrets for Argo CD configuration.

## Creating the Vault File

```bash
# Create a new vault file
ansible-vault create ansible/argocd/vault/main.yaml
```

Add the following content:

```yaml
---
# Argo CD Repository Credentials
argocd_repo_password: "your-github-pat-token-here"

# Kubernetes Secrets for Sealed Secrets
# These will be used to create SealedSecrets for applications
grafana_admin_password: "your-secure-grafana-password"
minio_root_user: "minioadmin"
minio_root_password: "your-secure-minio-password"
```

## Using the Vault File

The vault file should be automatically included when using the playbook. If not, you can explicitly include it:

```bash
ansible-playbook ansible/argocd-setup.yaml \
  -e @ansible/argocd/vault/main.yaml \
  --ask-vault-pass \
  -e cluster_name=your-cluster
```

## Setting Your Text Editor

Ansible Vault uses your system's default editor. Set it using the `EDITOR` or `VISUAL` environment variable:

```bash
# For the current session
export EDITOR=nano        # or vim, code, etc.
export VISUAL=nano       # VISUAL takes precedence over EDITOR

# For your shell profile (permanent)
# Add to ~/.zshrc (zsh) or ~/.bashrc (bash):
export EDITOR=nano
# or
export VISUAL=nano
```

**Common editors:**

- `nano` - Simple, beginner-friendly
- `vim` - Powerful, modal editor
- `code` - VS Code (if installed)
- `subl` - Sublime Text (if installed)
- `emacs` - Emacs editor

**Example:**

```bash
# Set nano as editor for this session
export EDITOR=nano

# Now create/edit vault files
ansible-vault create ansible/argocd/vault/main.yaml
ansible-vault edit ansible/argocd/vault/main.yaml
```

## Vault Commands

```bash
# Create vault file
ansible-vault create ansible/argocd/vault/main.yaml

# Edit vault file
ansible-vault edit ansible/argocd/vault/main.yaml

# View vault file (read-only)
ansible-vault view ansible/argocd/vault/main.yaml

# Encrypt existing file
ansible-vault encrypt ansible/argocd/vault/main.yaml

# Decrypt file (use with caution)
ansible-vault decrypt ansible/argocd/vault/main.yaml
```

## Vault Password

Store your vault password securely:

- Use a password manager
- Store in a secure location (not in Git)
- Share with team members via secure channels

## Environment Variable

You can also use an environment variable for the vault password:

```bash
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ansible/vault-pass
ansible-playbook ansible/argocd-setup.yaml -e cluster_name=your-cluster
```

## Creating SealedSecrets from Vault

The `create-sealed-secrets.yaml` playbook automates the creation of SealedSecrets from your Ansible Vault:

```bash
# 1. Ensure Sealed Secrets controller is installed
ansible-playbook ansible/sealed-secrets-setup.yaml -e cluster_name=your-cluster

# 2. Create SealedSecrets from vault
# IMPORTANT: You MUST use --ask-vault-pass to decrypt the vault file
ansible-playbook ansible/create-sealed-secrets.yaml \
  --ask-vault-pass
```

**Note**: You don't need `-e @ansible/argocd/vault/main.yaml` because the playbook loads it automatically. Just use `--ask-vault-pass` to provide the password.

This playbook will:

- Read secrets from Ansible Vault
- Create Kubernetes Secret manifests (dry-run)
- Encrypt them with `kubeseal` to create SealedSecrets
- Save encrypted SealedSecrets to `kubernetes/secrets/` directory

**Required vault variables:**

- `grafana_admin_password` - Grafana admin password
- `minio_root_user` - MinIO root username (default: minioadmin)
- `minio_root_password` - MinIO root password

**Prerequisites:**

- `kubeseal` CLI installed (`brew install kubeseal` on macOS)
- Sealed Secrets controller running in the cluster
- Access to the cluster (kubectl configured)
