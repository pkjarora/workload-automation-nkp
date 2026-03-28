#!/bin/bash

set -euo pipefail

############################################
# Logging Setup
############################################
LOG_FILE="nkp_cluster_creation_$(date +%Y%b%d_%H%M%S | tr '[:upper:]' '[:lower:]').log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "===== NKP Automation Started at $(date) ====="

############################################
# Validate Required Variables
############################################
: "${NAMESPACE:?NAMESPACE is required}"
: "${CLUSTER_NAME:?CLUSTER_NAME is required}"

############################################
# 1️⃣ Create Workspace
############################################
echo "Creating Workspace ${NAMESPACE} for cluster: ${CLUSTER_NAME}"

if ! envsubst < ./objects/01-workspaces-creation.yaml | kubectl apply -f -; then
  echo "ERROR: Workspace creation failed"
  exit 1
fi

echo "Workspace creation completed successfully."


############################################
# 2️⃣ Create Workload Cluster
############################################

echo "Creating NKP workload cluster: ${CLUSTER_NAME}"

if ! nkp create cluster nutanix \
  --cluster-name "$CLUSTER_NAME" \
  --endpoint "$NUTANIX_PC_FQDN_ENDPOINT_WITH_PORT" \
  --control-plane-endpoint-ip "$CONTROL_PLANE_IP" \
  --control-plane-vm-image "$IMAGE_NAME" \
  --control-plane-prism-element-cluster "$PRISM_ELEMENT_CLUSTER_NAME" \
  --control-plane-subnets "$SUBNET_NAME" \
  --control-plane-pc-project "$PROJECT_NAME" \
  --control-plane-replicas "$CONTROL_PLANE_REPLICAS" \
  --control-plane-vcpus "$CONTROL_PLANE_VCPUS" \
  --control-plane-cores-per-vcpu "$CONTROL_PLANE_CORES_PER_VCPU" \
  --control-plane-memory "$CONTROL_PLANE_MEMORY_GIB" \
  --control-plane-disk-size "$CONTROL_PLANE_STORAGE_GIB" \
  --worker-vm-image "$IMAGE_NAME" \
  --worker-prism-element-cluster "$PRISM_ELEMENT_CLUSTER_NAME" \
  --worker-subnets "$SUBNET_NAME" \
  --worker-pc-project "$PROJECT_NAME" \
  --worker-replicas "$WORKER_REPLICAS" \
  --worker-vcpus "$WORKER_VCPUS" \
  --worker-cores-per-vcpu "$WORKER_CORES_PER_VCPU" \
  --worker-memory "$WORKER_MEMORY_GIB" \
  --worker-disk-size "$WORKER_STORAGE_GIB" \
  --ssh-public-key-file "$SSH_KEY_FILE" \
  --csi-storage-container "$NUTANIX_STORAGE_CONTAINER_NAME" \
  --csi-file-system "$CSI_FILESYSTEM" \
  --csi-hypervisor-attached-volumes="$CSI_HYPERVISOR_ATTACHED" \
  --kubernetes-service-load-balancer-ip-range "$LB_IP_RANGE" \
  --insecure \
  --airgapped \
  --registry-mirror-url "$REGISTRY_URL" \
  --registry-mirror-cacert "$REGISTRY_CA" \
  --registry-mirror-username="$REGISTRY_USERNAME" \
  --registry-mirror-password="$REGISTRY_PASSWORD" \
  --namespace="$NAMESPACE" \
  --verbose 4
then
  echo "ERROR: Cluster creation failed"
  exit 1
fi

echo "Cluster creation command completed."

############################################
# 3️⃣ Fetch kubeconfig
############################################

echo "Fetching kubeconfig..."

nkp get kubeconfig -c "$CLUSTER_NAME" -n "$NAMESPACE" > "${CLUSTER_NAME}.conf"
#export KUBECONFIG="${CLUSTER_NAME}.conf"

############################################
# 4 Wait for API Server
############################################

echo "Waiting for API server to become reachable..."

API_TIMEOUT=600
API_ELAPSED=0
API_INTERVAL=15

while true; do
    if kubectl get nodes --kubeconfig=${CLUSTER_NAME}.conf &>/dev/null; then
        echo "API server is reachable."
        break
    fi

    if [[ "$API_ELAPSED" -ge "$API_TIMEOUT" ]]; then
        echo "ERROR: API server not reachable after timeout"
        exit 1
    fi

    echo "API not reachable yet... (${API_ELAPSED}s)"
    sleep "$API_INTERVAL"
    API_ELAPSED=$((API_ELAPSED + API_INTERVAL))
done

############################################
# 5 Wait for Nodes Ready
############################################

echo "Checking node readiness..."

NODE_TIMEOUT=900
ELAPSED=0
INTERVAL=20

while true; do
    TOTAL_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
    NOT_READY=$(kubectl get nodes --no-headers 2>/dev/null | awk '$2 != "Ready"' | wc -l)

    if [[ "$TOTAL_NODES" -gt 0 && "$NOT_READY" -eq 0 ]]; then
        echo "All ${TOTAL_NODES} nodes are Ready."
        break
    fi

    if [[ "$ELAPSED" -ge "$NODE_TIMEOUT" ]]; then
        echo "ERROR: Timeout waiting for nodes to become Ready."
        kubectl get nodes
        exit 1
    fi

    echo "Waiting for nodes... (${ELAPSED}s)"
    sleep "$INTERVAL"
    ELAPSED=$((ELAPSED + INTERVAL))
done


############################################
# 6 Create VirtualGroup
############################################
echo "Creating Virtual Group ${USER} for cluster: ${CLUSTER_NAME}"

if ! envsubst < ./objects/06-virtualgroup-creation.yaml | kubectl apply -f -; then
  echo "ERROR: VirtualGroup creation failed"
  exit 1
fi

echo "VirtualGroup creation completed successfully."

kubectl get virtualgroups.kommander.mesosphere.io

############################################
# 7 Fetch Workspace UUID
############################################
echo "Fetching Workspace UUID..."

WS_UID=$(kubectl get workspace "$NAMESPACE" \
  -o jsonpath='{.spec.clusterLabels.workspaces\.kommander\.mesosphere\.io/workspace-ref}')

if [[ -z "$WS_UID" ]]; then
  echo "ERROR: Could not fetch Workspace UUID"
  exit 1
fi

echo "Workspace UUID: $WS_UID"

############################################
# 8 Create WorkspaceRole
############################################
echo "Creating WorkspaceRole for ${NAMESPACE}"

if ! envsubst < ./objects/08-workspaceroles-creation.yaml | kubectl apply -f -; then
  echo "ERROR: WorkspaceRole creation failed"
  exit 1
fi

echo "WorkspaceRole creation completed successfully."

############################################
# 9 Create VirtualGroupKommanderWorkspaceRoleBinding
############################################
echo "Creating VirtualGroupKommanderWorkspaceRoleBinding for ${NAMESPACE}"

if ! envsubst < ./objects/09-virtualgroupkommanderworkspacerolebinding.yaml | kubectl apply -f -; then
  echo "ERROR: VirtualGroupKommanderWorkspaceRoleBinding creation failed"
  exit 1
fi

echo "VirtualGroupKommanderWorkspaceRoleBinding creation completed successfully."

############################################
# 10 create VirtualGroupWorkspaceRoleBinding
############################################    
echo "Creating VirtualGroupWorkspaceRoleBinding for ${NAMESPACE}"

if ! envsubst < ./objects/10-virtualworkspacerolebinding.yaml | kubectl apply -f -; then
  echo "ERROR: VirtualGroupWorkspaceRoleBinding creation failed"
  exit 1
fi

echo "VirtualGroupWorkspaceRoleBinding creation completed successfully."


############################################
# Done
############################################
echo "===== NKP Automation Completed Successfully at $(date) ====="
