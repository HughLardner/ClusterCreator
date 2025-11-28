# Ansible Vault Workflow

## Understanding Vault Files

**Ansible Vault files are encrypted** - they look like this when opened directly:

```
$ANSIBLE_VAULT;1.1;AES256
37323130376461323230373739653037323362346465356134636539373061613861386435376263
3531366332373239613931396161303131313238343438380a333831663662313231376430643133
...
```

This is **normal and expected** - the file is encrypted for security.

## Proper Workflow

### ❌ Don't Do This
```bash
# Opening directly in VS Code shows encrypted content
code ansible/argocd/vault/main.yaml
# You'll see: $ANSIBLE_VAULT;1.1;AES256...
```

### ✅ Do This Instead

#### Option 1: Edit with Vault (Recommended)
```bash
# Set your editor
export EDITOR=code  # or nano, vim, etc.

# Edit the vault file
ansible-vault edit ansible/argocd/vault/main.yaml
# Enter vault password when prompted
# VS Code opens with DECRYPTED content
# Make changes, save, close VS Code
# File is automatically re-encrypted
```

#### Option 2: View Only (Read-Only)
```bash
# View decrypted content without editing
ansible-vault view ansible/argocd/vault/main.yaml
# Enter vault password when prompted
# Shows decrypted content in terminal
```

#### Option 3: Decrypt Temporarily (Advanced)
```bash
# Decrypt to a temporary file
ansible-vault decrypt ansible/argocd/vault/main.yaml --output /tmp/main-decrypted.yaml

# Edit in VS Code
code /tmp/main-decrypted.yaml

# Re-encrypt when done
ansible-vault encrypt ansible/argocd/vault/main.yaml

# Clean up
rm /tmp/main-decrypted.yaml
```

## VS Code Integration

### Using VS Code as Editor

```bash
# Set VS Code as editor
export EDITOR=code

# Or add to ~/.zshrc for permanent
echo 'export EDITOR=code' >> ~/.zshrc
source ~/.zshrc

# Now vault commands use VS Code
ansible-vault edit ansible/argocd/vault/main.yaml
```

### VS Code Extensions (Optional)

There are VS Code extensions that can help with Ansible Vault:
- **Ansible** extension by Red Hat
- **Ansible Vault** extension

These can provide syntax highlighting and better integration, but `ansible-vault edit` works fine without them.

## Common Workflows

### Creating a New Vault File
```bash
export EDITOR=code
ansible-vault create ansible/argocd/vault/main.yaml
# Enter new vault password
# VS Code opens with empty file
# Add your secrets, save, close
# File is automatically encrypted
```

### Editing Existing Vault File
```bash
export EDITOR=code
ansible-vault edit ansible/argocd/vault/main.yaml
# Enter vault password
# VS Code opens with decrypted content
# Make changes, save, close
# File is automatically re-encrypted
```

### Viewing Without Editing
```bash
ansible-vault view ansible/argocd/vault/main.yaml
# Enter vault password
# Shows decrypted content in terminal
```

## Troubleshooting

### "File looks encrypted in VS Code"
- **Solution**: Use `ansible-vault edit` instead of opening directly
- The file IS encrypted - that's correct behavior when opened directly

### "Editor not opening"
- Check `EDITOR` variable: `echo $EDITOR`
- Set it: `export EDITOR=code`
- Verify `code` command works: `code --version`

### "Changes not saving"
- Make sure you save the file in your editor before closing
- The re-encryption happens when the editor process exits
- If using VS Code, save (Cmd+S) then close the window

## Security Reminder

- ✅ Always use `ansible-vault edit` or `ansible-vault view`
- ✅ Never commit decrypted vault files
- ✅ Never share vault passwords in plaintext
- ✅ Use password managers for vault passwords

