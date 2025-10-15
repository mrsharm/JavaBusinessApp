#!/bin/bash

# Deploy Java Application to Azure Kubernetes Service (AKS)
# This script sets up the entire infrastructure and deploys the application

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables (modify these)
RESOURCE_GROUP="javaapp-rg"
LOCATION="eastus"
ACR_NAME="javaappacr${RANDOM}"
AKS_CLUSTER_NAME="javaapp-aks"
AKS_NODE_COUNT=3
AKS_NODE_SIZE="Standard_D2s_v3"

echo -e "${GREEN}=== Java Application Azure Deployment Script ===${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first."
    exit 1
fi

print_status "Checking Azure CLI login status..."
if ! az account show &> /dev/null; then
    print_warning "Not logged in to Azure. Logging in..."
    az login
fi

# Step 1: Create Resource Group
print_status "Creating Resource Group: $RESOURCE_GROUP"
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION \
    --output table

# Step 2: Create Azure Container Registry (ACR)
print_status "Creating Azure Container Registry: $ACR_NAME"
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Basic \
    --location $LOCATION \
    --output table

# Step 3: Build and push Docker image to ACR
print_status "Building Docker image and pushing to ACR..."
az acr build \
    --registry $ACR_NAME \
    --image javaapp:latest \
    --image javaapp:v1.0 \
    --file Dockerfile \
    . \
    --output table

# Step 4: Create AKS Cluster
print_status "Creating AKS Cluster: $AKS_CLUSTER_NAME (this may take 5-10 minutes)..."
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --node-count $AKS_NODE_COUNT \
    --node-vm-size $AKS_NODE_SIZE \
    --enable-managed-identity \
    --generate-ssh-keys \
    --attach-acr $ACR_NAME \
    --network-plugin azure \
    --enable-cluster-autoscaler \
    --min-count 2 \
    --max-count 5 \
    --location $LOCATION \
    --output table

# Step 5: Get AKS credentials
print_status "Getting AKS credentials..."
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --overwrite-existing

# Step 6: Enable AKS Add-ons
print_status "Enabling AKS monitoring and policy add-ons..."
WORKSPACE_ID=$(az monitor log-analytics workspace create \
    --resource-group $RESOURCE_GROUP \
    --workspace-name javaapp-workspace \
    --location $LOCATION \
    --query id -o tsv)

az aks enable-addons \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --addons monitoring,azure-policy \
    --workspace-resource-id $WORKSPACE_ID

# Step 7: Enable Workload Identity
print_status "Enabling Workload Identity..."
az aks update \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --enable-workload-identity \
    --enable-oidc-issuer

# Step 8: Get cluster info for manifest updates
print_status "Getting cluster information..."
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RANDOM_SUFFIX=$RANDOM

# Step 9: Update deployment YAML with ACR name and Azure details
print_status "Updating AKS deployment files..."
sed -i "s/\${ACR_NAME}/$ACR_NAME/g" aks/deployment.yaml
sed -i "s/\${RANDOM_SUFFIX}/$RANDOM_SUFFIX/g" aks/service.yaml
sed -i "s/\${SUBSCRIPTION_ID}/$SUBSCRIPTION_ID/g" aks/hpa.yaml
sed -i "s/\${RESOURCE_GROUP}/$RESOURCE_GROUP/g" aks/hpa.yaml
sed -i "s/\${AKS_CLUSTER}/$AKS_CLUSTER_NAME/g" aks/hpa.yaml

# Step 10: Deploy to AKS
print_status "Deploying application to Azure Kubernetes Service..."
kubectl apply -f aks/namespace.yaml
kubectl apply -f aks/serviceaccount.yaml
kubectl apply -f aks/configmap.yaml
kubectl apply -f aks/networkpolicy.yaml
kubectl apply -f aks/deployment.yaml
kubectl apply -f aks/service.yaml
kubectl apply -f aks/hpa.yaml
kubectl apply -f aks/pdb.yaml

# Step 11: Wait for deployment
print_status "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod \
    -l app=javaapp \
    -n javaapp \
    --timeout=300s

# Step 12: Get service external IP
print_status "Getting service external IP (this may take a few minutes)..."
echo "Waiting for LoadBalancer to assign external IP..."
kubectl get service javaapp-service -n javaapp --watch &
WATCH_PID=$!
sleep 60
kill $WATCH_PID 2>/dev/null || true

EXTERNAL_IP=$(kubectl get service javaapp-service -n javaapp -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
DNS_FQDN="javaapp-${RANDOM_SUFFIX}.${LOCATION}.cloudapp.azure.com"

# Step 13: Display deployment information
echo ""
echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo "Resource Group: $RESOURCE_GROUP"
echo "ACR Name: $ACR_NAME"
echo "AKS Cluster: $AKS_CLUSTER_NAME"
echo "Namespace: javaapp"
echo ""
echo -e "${GREEN}Useful Commands:${NC}"
echo "  View pods:     kubectl get pods -n javaapp"
echo "  View logs:     kubectl logs -f <pod-name> -n javaapp"
echo "  View service:  kubectl get service -n javaapp"
echo "  Scale app:     kubectl scale deployment javaapp --replicas=5 -n javaapp"
echo ""
if [ -n "$EXTERNAL_IP" ]; then
    echo -e "${GREEN}External IP:${NC} $EXTERNAL_IP"
    echo -e "${GREEN}DNS Name:${NC} $DNS_FQDN"
    echo -e "${GREEN}Application URL:${NC} http://$EXTERNAL_IP"
    echo -e "${GREEN}Application URL (DNS):${NC} http://$DNS_FQDN"
else
    echo -e "${YELLOW}External IP is still being assigned. Run:${NC}"
    echo "  kubectl get service javaapp-service -n javaapp"
fi
echo ""
echo -e "${GREEN}AKS Features Enabled:${NC}"
echo "  ✓ Azure Monitor for Containers"
echo "  ✓ Azure Policy"
echo "  ✓ Workload Identity"
echo "  ✓ OIDC Issuer"
echo "  ✓ Network Policies"
echo "  ✓ Pod Disruption Budget"
echo ""
echo -e "${GREEN}View in Azure Portal:${NC}"
echo "  https://portal.azure.com/#@/resource/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$AKS_CLUSTER_NAME"
echo ""
echo -e "${GREEN}To clean up resources:${NC}"
echo "  az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo ""
echo -e "${CYAN}To monitor your deployment:${NC}"
echo "  kubectl get pods -n javaapp --watch"
echo "  kubectl top pods -n javaapp"
echo "  az aks browse --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME"
echo ""
