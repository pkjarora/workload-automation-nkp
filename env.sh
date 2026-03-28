#Nutanix-env
export NUTANIX_PC_FQDN_ENDPOINT_WITH_PORT="https://10.135.20.2:9440" # Nutanix Prism Central endpoint URL with port
export IMAGE_NAME="nkp-rocky-9.6-release-cis-1.34.1-20251206060914.qcow2" # Name of the VM image to use for cluster nodes
export PRISM_ELEMENT_CLUSTER_NAME="INBLRPTPSEC01" # Name of the Nutanix Prism Element cluster
export SUBNET_NAME="Karbon-VMs" # Name of the subnet to use for cluster nodes
export PROJECT_NAME="default" # Name of the Nutanix project
export NUTANIX_USER="admin" # Nutanix PrismCentral username (left blank for security)
export NUTANIX_PASSWORD="Nutan1x@BLR123" # Nutanix PrismCentral password (left blank for security)
export NUTANIX_STORAGE_CONTAINER_NAME="Eagle01-Storage-Container" # Name of the Nutanix storage container
export CSI_HYPERVISOR_ATTACHED="true" # Whether to use hypervisor-attached volumes for CSI

#NKP-ENV
export CLUSTER_NAME="nkpcl-$(date +%d%b%Y-%H%M%S| tr '[:upper:]' '[:lower:]')" # Name of the Kubernetes cluster
export CONTROL_PLANE_IP="10.135.22.17" # IP address for the Kubernetes control plane
export LB_IP_RANGE="10.135.22.18-10.135.22.18" # IP range for load balancer services
export CONTROL_PLANE_REPLICAS="3" # Number of control plane replicas
export CONTROL_PLANE_VCPUS="2" # Number of vCPUs for control plane nodes
export CONTROL_PLANE_CORES_PER_VCPU="2" # Number of cores per vCPU for control plane nodes
export CONTROL_PLANE_MEMORY_GIB="16" # Memory in GiB for control plane nodes
export CONTROL_PLANE_STORAGE_GIB="200"
export WORKER_REPLICAS="3" # Number of worker node replicas
export WORKER_VCPUS="4" # Number of vCPUs for worker nodes
export WORKER_CORES_PER_VCPU="2" # Number of cores per vCPU for worker nodes
export WORKER_MEMORY_GIB="16" # Memory in GiB for worker nodes
export WORKER_STORAGE_GIB="200"
export CSI_FILESYSTEM="xfs" # Filesystem type for CSI volumes
export NAMESPACE="ws-$(date +%d%b%Y | tr '[:upper:]' '[:lower:]')-v2"
export WORKSPACE="ws-$(date +%d%b%Y | tr '[:upper:]' '[:lower:]')-v2"

#env
export SSH_KEY_FILE="/Users/pankaj.arora/.ssh/id_rsa.pub" # Path to the SSH public key file

#Reg-env
export REGISTRY_URL="http://nkpregistry.nutanix.local/nkp2.17" # URL for the private container registry
export REGISTRY_USERNAME="admin" # Username for authenticating with the private registry (left blank for security)
export REGISTRY_PASSWORD="Nutan1x@BLR123" # Password for authenticating with the private registry (left blank for security)
export REGISTRY_CA="/Users/pankaj.arora/Documents/BLR_LAB_NKP_INSTALLATION/nutanix-PDC-CA.crt" # Path to the CA certificate for the private registry

#User for RBAC
export USER_EMAIL="test3@nutanix.local"
export USER_NAME="test3"
