#!/bin/bash

# Script to add local DNS entries to Pi-hole
# Adds entries for all services that go through Traefik ingress

set -e

PIHOLE_NAMESPACE="pihole"
TRAEFIK_IP="192.168.10.20"

# Get Pi-hole pod name
PIHOLE_POD=$(kubectl get pod -n ${PIHOLE_NAMESPACE} -l app=pihole -o jsonpath='{.items[0].metadata.name}')

if [ -z "${PIHOLE_POD}" ]; then
    echo "Error: Pi-hole pod not found in namespace ${PIHOLE_NAMESPACE}"
    exit 1
fi

echo "Found Pi-hole pod: ${PIHOLE_POD}"
echo "Adding DNS entries pointing to Traefik IP: ${TRAEFIK_IP}"
echo ""

# DNS entries to add
declare -a DNS_ENTRIES=(
    "pihole.local:192.168.10.20"
    "traefik.local:192.168.10.20"
    "grafana.local:192.168.10.20"
    "minio.local:192.168.10.20"
    "longhorn.local:192.168.10.20"
)

# Function to add DNS entry
add_dns_entry() {
    local domain=$1
    local ip=$2
    
    echo "Adding: ${domain} -> ${ip}"
    
    # Check if entry already exists
    local exists=$(kubectl exec -n ${PIHOLE_NAMESPACE} ${PIHOLE_POD} -- \
        sqlite3 /etc/pihole/gravity.db \
        "SELECT COUNT(*) FROM domainlist WHERE domain = '${domain}' AND type = 0;" 2>/dev/null || echo "0")
    
    if [ "${exists}" != "0" ]; then
        echo "  Entry already exists, updating..."
        # Update existing entry
        kubectl exec -n ${PIHOLE_NAMESPACE} ${PIHOLE_POD} -- \
            sqlite3 /etc/pihole/gravity.db \
            "UPDATE domainlist SET ip = '${ip}' WHERE domain = '${domain}' AND type = 0;" 2>/dev/null
    else
        echo "  Creating new entry..."
        # Insert new entry (type = 0 for local DNS records)
        kubectl exec -n ${PIHOLE_NAMESPACE} ${PIHOLE_POD} -- \
            sqlite3 /etc/pihole/gravity.db \
            "INSERT INTO domainlist (domain, ip, type) VALUES ('${domain}', '${ip}', 0);" 2>/dev/null
    fi
}

# Add all DNS entries
for entry in "${DNS_ENTRIES[@]}"; do
    domain=$(echo ${entry} | cut -d: -f1)
    ip=$(echo ${entry} | cut -d: -f2)
    add_dns_entry "${domain}" "${ip}"
done

echo ""
echo "DNS entries added successfully!"
echo ""

# Restart Pi-hole DNS to apply changes
echo "Restarting Pi-hole DNS service to apply changes..."
kubectl exec -n ${PIHOLE_NAMESPACE} ${PIHOLE_POD} -- \
    pihole restartdns >/dev/null 2>&1 || \
    kubectl exec -n ${PIHOLE_NAMESPACE} ${PIHOLE_POD} -- \
    killall -SIGHUP pihole-FTL 2>/dev/null || true

echo "DNS service restarted"
echo ""

# Verify entries
echo "Verifying DNS entries:"
kubectl exec -n ${PIHOLE_NAMESPACE} ${PIHOLE_POD} -- \
    sqlite3 /etc/pihole/gravity.db \
    "SELECT domain, ip FROM domainlist WHERE type = 0 ORDER BY domain;" 2>/dev/null

echo ""
echo "Testing DNS resolution:"
for entry in "${DNS_ENTRIES[@]}"; do
    domain=$(echo ${entry} | cut -d: -f1)
    echo -n "  ${domain}: "
    result=$(dig @192.168.10.150 ${domain} +short 2>/dev/null | head -1)
    if [ -n "${result}" ]; then
        echo "✓ ${result}"
    else
        echo "✗ Not resolved"
    fi
done

echo ""
echo "Done! DNS entries should now be active."
echo "Note: It may take a few seconds for DNS changes to propagate."

