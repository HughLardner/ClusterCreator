#!/bin/bash

# Script to generate bcrypt hash for Argo CD admin password
# Usage: ./generate-argocd-password-hash.sh [password]

if [ -z "$1" ]; then
    echo "Usage: $0 <password>"
    echo "Example: $0 mySecurePassword123"
    exit 1
fi

PASSWORD="$1"

# Check if htpasswd is available
if ! command -v htpasswd &> /dev/null; then
    echo "Error: htpasswd is not installed."
    echo ""
    echo "Install it with:"
    echo "  macOS: brew install httpd"
    echo "  Ubuntu/Debian: sudo apt-get install apache2-utils"
    echo "  RHEL/CentOS: sudo yum install httpd-tools"
    exit 1
fi

# Generate bcrypt hash
# htpasswd -nbBC 10 "" <password> generates: username:$2y$10$hash
# We need to remove the username: prefix and change $2y$ to $2a$ for Argo CD
HASH=$(htpasswd -nbBC 10 "" "$PASSWORD" | tr -d ':\n' | sed 's/$2y/$2a/')

echo "Bcrypt hash for Argo CD:"
echo "$HASH"
echo ""
echo "To set this password in Argo CD, run:"
echo "kubectl -n argocd patch secret argocd-secret \\"
echo "  -p '{\"stringData\": {"
echo "    \"admin.password\": \"$HASH\","
echo "    \"admin.passwordMtime\": \"'$(date +%FT%T%Z)'\""
echo "  }}'"
echo ""
echo "Then restart the Argo CD server:"
echo "kubectl rollout restart deployment/argocd-server -n argocd"

