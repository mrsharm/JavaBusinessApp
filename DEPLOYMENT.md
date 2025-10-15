# Kubernetes Deployment Guide for Azure

This guide explains how to deploy the Java Application to Azure Kubernetes Service (AKS).

## 📋 Prerequisites

### Required Tools
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (version 2.40+)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (Kubernetes CLI)
- [Docker](https://docs.docker.com/get-docker/) (for local testing)
- Azure Subscription with permissions to create resources

### Install on Windows (PowerShell)
```powershell
# Install Azure CLI
winget install Microsoft.AzureCLI

# Install kubectl
az aks install-cli

# Verify installations
az --version
kubectl version --client
```

## 🚀 Quick Start - Automated Deployment

### Option 1: PowerShell Script (Windows)
```powershell
# Make script executable and run
.\deploy-to-azure.ps1

# With custom parameters
.\deploy-to-azure.ps1 `
    -ResourceGroup "my-javaapp-rg" `
    -Location "eastus" `
    -AcrName "myjavaappacr" `
    -AksClusterName "my-aks-cluster"
```

### Option 2: Bash Script (Linux/Mac/WSL)
```bash
# Make script executable
chmod +x deploy-to-azure.sh

# Run deployment
./deploy-to-azure.sh
```

The automated script will:
1. ✅ Create Azure Resource Group
2. ✅ Create Azure Container Registry (ACR)
3. ✅ Build and push Docker image to ACR
4. ✅ Create AKS cluster with autoscaling
5. ✅ Attach ACR to AKS
6. ✅ Deploy application to Kubernetes
7. ✅ Configure auto-scaling (HPA)
8. ✅ Expose service via LoadBalancer

## 🔧 Manual Deployment (Step-by-Step)

### Step 1: Login to Azure
```bash
az login
az account set --subscription "Your-Subscription-Name"
```

### Step 2: Create Resource Group
```bash
RESOURCE_GROUP="javaapp-rg"
LOCATION="eastus"

az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION
```

### Step 3: Create Azure Container Registry
```bash
ACR_NAME="javaappacr${RANDOM}"

az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Basic
```

### Step 4: Build and Push Docker Image
```bash
# Build locally and push
az acr build \
    --registry $ACR_NAME \
    --image javaapp:v1.0 \
    --image javaapp:latest \
    --file Dockerfile \
    .
```

### Step 5: Create AKS Cluster
```bash
AKS_CLUSTER_NAME="javaapp-aks"

az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --node-count 3 \
    --enable-managed-identity \
    --generate-ssh-keys \
    --attach-acr $ACR_NAME \
    --network-plugin azure \
    --enable-cluster-autoscaler \
    --min-count 2 \
    --max-count 5
```

### Step 6: Get AKS Credentials
```bash
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --overwrite-existing
```

### Step 7: Update Deployment Files
```bash
# Replace ACR name in deployment.yaml
sed -i "s/\${ACR_NAME}/$ACR_NAME/g" k8s/deployment.yaml
```

For PowerShell:
```powershell
(Get-Content k8s\deployment.yaml) -replace '\$\{ACR_NAME\}', $ACR_NAME | Set-Content k8s\deployment.yaml
```

### Step 8: Deploy to Kubernetes
```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
```

### Step 9: Verify Deployment
```bash
# Check pods
kubectl get pods -n javaapp

# Check service
kubectl get service -n javaapp

# Check logs
kubectl logs -f <pod-name> -n javaapp
```

## 🐳 Local Docker Testing

### Build Docker Image Locally
```bash
docker build -t javaapp:local .
```

### Run Container Locally
```bash
docker run --rm -it javaapp:local
```

### Test with Docker Compose (Optional)
Create `docker-compose.yaml`:
```yaml
version: '3.8'
services:
  javaapp:
    build: .
    container_name: javaapp
    ports:
      - "8080:8080"
    environment:
      - JAVA_OPTS=-Xms256m -Xmx512m
```

Run:
```bash
docker-compose up
```

## 📊 Monitoring and Management

### View Pod Status
```bash
kubectl get pods -n javaapp --watch
```

### View Pod Logs
```bash
# All pods
kubectl logs -l app=javaapp -n javaapp --tail=100 -f

# Specific pod
kubectl logs <pod-name> -n javaapp -f
```

### Describe Pod (for troubleshooting)
```bash
kubectl describe pod <pod-name> -n javaapp
```

### Scale Manually
```bash
kubectl scale deployment javaapp --replicas=5 -n javaapp
```

### View Horizontal Pod Autoscaler
```bash
kubectl get hpa -n javaapp
kubectl describe hpa javaapp-hpa -n javaapp
```

### Access Pod Shell
```bash
kubectl exec -it <pod-name> -n javaapp -- /bin/sh
```

### View Service Details
```bash
kubectl get service javaapp-service -n javaapp
kubectl describe service javaapp-service -n javaapp
```

## 🔄 Update and Rollback

### Update Application
```bash
# Build new version
az acr build --registry $ACR_NAME --image javaapp:v2.0 .

# Update deployment
kubectl set image deployment/javaapp \
    javaapp=$ACR_NAME.azurecr.io/javaapp:v2.0 \
    -n javaapp

# Check rollout status
kubectl rollout status deployment/javaapp -n javaapp
```

### Rollback
```bash
# View rollout history
kubectl rollout history deployment/javaapp -n javaapp

# Rollback to previous version
kubectl rollout undo deployment/javaapp -n javaapp

# Rollback to specific revision
kubectl rollout undo deployment/javaapp --to-revision=2 -n javaapp
```

## 🔒 Security Best Practices

### 1. Use Azure Key Vault for Secrets
```bash
# Create Key Vault
az keyvault create \
    --name "javaapp-kv" \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION

# Enable CSI Secret Store Driver
az aks enable-addons \
    --addons azure-keyvault-secrets-provider \
    --name $AKS_CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP
```

### 2. Enable Azure Policy for AKS
```bash
az aks enable-addons \
    --addons azure-policy \
    --name $AKS_CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP
```

### 3. Network Policies
```bash
# Enable network policy during cluster creation
az aks create \
    --network-plugin azure \
    --network-policy azure \
    # ... other parameters
```

## 💰 Cost Management

### View Current Costs
```bash
az consumption usage list \
    --resource-group $RESOURCE_GROUP \
    --start-date 2025-10-01 \
    --end-date 2025-10-15
```

### Stop AKS Cluster (to save costs)
```bash
az aks stop \
    --name $AKS_CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP
```

### Start AKS Cluster
```bash
az aks start \
    --name $AKS_CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP
```

## 🧹 Cleanup

### Delete Application Only
```bash
kubectl delete namespace javaapp
```

### Delete Entire Infrastructure
```bash
az group delete \
    --name $RESOURCE_GROUP \
    --yes \
    --no-wait
```

## 🔍 Troubleshooting

### Pod Not Starting
```bash
# Check pod events
kubectl describe pod <pod-name> -n javaapp

# Check logs
kubectl logs <pod-name> -n javaapp

# Check previous crashed container logs
kubectl logs <pod-name> -n javaapp --previous
```

### Image Pull Errors
```bash
# Verify ACR integration
az aks check-acr \
    --name $AKS_CLUSTER_NAME \
    --resource-group $RESOURCE_GROUP \
    --acr $ACR_NAME.azurecr.io
```

### Service Not Accessible
```bash
# Check service
kubectl get service javaapp-service -n javaapp

# Check endpoints
kubectl get endpoints javaapp-service -n javaapp

# Verify LoadBalancer provisioning
kubectl describe service javaapp-service -n javaapp
```

## 📚 Additional Resources

- [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────┐
│           Azure Subscription                 │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │      Resource Group: javaapp-rg        │ │
│  │                                        │ │
│  │  ┌──────────────────────────────────┐ │ │
│  │  │  Azure Container Registry (ACR)  │ │ │
│  │  │  - javaapp:latest                │ │ │
│  │  │  - javaapp:v1.0                  │ │ │
│  │  └──────────────────────────────────┘ │ │
│  │                                        │ │
│  │  ┌──────────────────────────────────┐ │ │
│  │  │  Azure Kubernetes Service (AKS)  │ │ │
│  │  │                                  │ │ │
│  │  │  ┌────────────────────────────┐  │ │ │
│  │  │  │  Namespace: javaapp        │  │ │ │
│  │  │  │                            │  │ │ │
│  │  │  │  • Deployment (3 replicas) │  │ │ │
│  │  │  │  • Service (LoadBalancer)  │  │ │ │
│  │  │  │  • HPA (2-10 pods)         │  │ │ │
│  │  │  │  • ConfigMap               │  │ │ │
│  │  │  └────────────────────────────┘  │ │ │
│  │  └──────────────────────────────────┘ │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## 🎓 Next Steps

1. ✅ Set up Azure DevOps pipeline (see `azure-pipelines.yaml`)
2. ✅ Configure monitoring with Azure Monitor
3. ✅ Set up Application Insights
4. ✅ Implement Azure Key Vault integration
5. ✅ Configure ingress controller (NGINX/Application Gateway)
6. ✅ Set up cert-manager for SSL/TLS
7. ✅ Implement GitOps with Flux or ArgoCD
