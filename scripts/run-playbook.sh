#!/bin/bash

# Script to run individual Ansible playbooks with the correct environment
# Usage: ./scripts/run-playbook.sh <playbook_name> [additional ansible args]
# Example: ./scripts/run-playbook.sh cilium-setup.yaml
# Example: ./scripts/run-playbook.sh cilium-setup.yaml --tags cilium_config

usage() {
  echo "Usage: $0 <playbook_name> [additional ansible args]"
  echo ""
  echo "Runs a single Ansible playbook with all the required environment variables"
  echo "that are normally set by 'ccr bootstrap'"
  echo ""
  echo "Examples:"
  echo "  $0 cilium-setup.yaml"
  echo "  $0 etcd-encryption.yaml"
  echo "  $0 controlplane-setup.yaml --tags kubeadm_init"
  echo "  $0 move-kubeconfig-local.yaml --tags rename_kubeconfig_context"
  echo ""
  echo "Available playbooks from bootstrap:"
  echo "  - generate-hosts-txt.yaml"
  echo "  - trust-hosts.yaml"
  echo "  - prepare-nodes.yaml"
  echo "  - etcd-nodes-setup.yaml"
  echo "  - kubevip-setup.yaml"
  echo "  - controlplane-setup.yaml"
  echo "  - move-kubeconfig-local.yaml"
  echo "  - join-controlplane-nodes.yaml"
  echo "  - join-worker-nodes.yaml"
  echo "  - move-kubeconfig-remote.yaml"
  echo "  - conditionally-taint-controlplane.yaml"
  echo "  - etcd-encryption.yaml"
  echo "  - cilium-setup.yaml"
  echo "  - kubelet-csr-approver.yaml"
  echo "  - local-storageclasses-setup.yaml"
  echo "  - metrics-server-setup.yaml"
  echo "  - metallb-setup.yaml"
  echo "  - label-and-taint-nodes.yaml"
  echo "  - ending-output.yaml"
}

# Check if playbook name is provided
if [ $# -lt 1 ]; then
  usage
  exit 1
fi

PLAYBOOK_NAME="$1"
shift  # Remove first argument, rest are additional ansible args

# Source the environment file
REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${REPO_PATH}/scripts/k8s.env"

# Check if CLUSTER_NAME is set
if [ -z "$CLUSTER_NAME" ]; then
  echo "Error: CLUSTER_NAME is not set. Please set it in your environment or k8s.env file."
  exit 1
fi

# Check if playbook exists
PLAYBOOK_PATH="${REPO_PATH}/ansible/${PLAYBOOK_NAME}"
if [ ! -f "$PLAYBOOK_PATH" ]; then
  echo "Error: Playbook not found: $PLAYBOOK_PATH"
  exit 1
fi

# Check if inventory file exists
INVENTORY_FILE="${REPO_PATH}/ansible/tmp/${CLUSTER_NAME}/ansible-hosts.txt"
if [ ! -f "$INVENTORY_FILE" ]; then
  echo "Error: Inventory file not found: $INVENTORY_FILE"
  echo "Make sure you've run 'ccr tofu apply' first to generate the inventory."
  exit 1
fi

# Set up ansible options
ANSIBLE_OPTS="-i ${INVENTORY_FILE} -u ${VM_USERNAME} --private-key ${HOME}/.ssh/${NON_PASSWORD_PROTECTED_SSH_KEY}"

# Add vault password file if set
if [ -n "${ANSIBLE_VAULT_PASSWORD_FILE:-}" ] && [ -f "${ANSIBLE_VAULT_PASSWORD_FILE}" ]; then
  ANSIBLE_OPTS="$ANSIBLE_OPTS --vault-password-file ${ANSIBLE_VAULT_PASSWORD_FILE}"
fi

# Set up default extra vars (same as in run_playbooks function)
DEFAULT_EXTRA_VARS="\
  -e cluster_name=${CLUSTER_NAME} \
  -e ssh_key_file=${HOME}/.ssh/${NON_PASSWORD_PROTECTED_SSH_KEY} \
  -e ssh_hosts_file=${HOME}/.ssh/known_hosts \
  -e kubernetes_long_version=${KUBERNETES_LONG_VERSION} \
  -e kubernetes_medium_version=${KUBERNETES_MEDIUM_VERSION} \
  -e kubernetes_short_version=${KUBERNETES_SHORT_VERSION} \
  -e cni_plugins_version=${CNI_PLUGINS_VERSION} \
  -e etcd_version=${ETCD_VERSION} \
  -e cilium_version=${CILIUM_VERSION} \
  -e metallb_version=${METALLB_VERSION} \
  -e local_path_provisioner_version=${LOCAL_PATH_PROVISIONER_VERSION} \
  -e metrics_server_version=${METRICS_SERVER_VERSION} \
  -e kubelet_serving_cert_approver_version=${KUBELET_SERVING_CERT_APPROVER_VERSION} \
  -e argocd_version=${ARGOCD_VERSION}"

# Install kubernetes.core collection if needed
ansible-galaxy collection install kubernetes.core > /dev/null 2>&1

# Change to ansible directory
cd "${REPO_PATH}/ansible" || exit 1

# Check if playbook requires vault password and prompt if not set
VAULT_OPTS=""
if [[ "$PLAYBOOK_NAME" == *"argocd"* ]] || [[ "$PLAYBOOK_NAME" == *"sealed-secrets"* ]] || [[ "$PLAYBOOK_NAME" == *"create-sealed-secrets"* ]]; then
  if [ -z "${ANSIBLE_VAULT_PASSWORD_FILE:-}" ] || [ ! -f "${ANSIBLE_VAULT_PASSWORD_FILE}" ]; then
    VAULT_OPTS="--ask-vault-pass"
  fi
fi

# Run the playbook
echo "Running playbook: ${PLAYBOOK_NAME}"
echo "Additional args: $@"
echo ""

ansible-playbook $ANSIBLE_OPTS $VAULT_OPTS $DEFAULT_EXTRA_VARS "$@" "$PLAYBOOK_NAME"

