# Deploy Java Application to Azure Kubernetes Service (AKS)
# PowerShell script for Windows

param(
    [string]$ResourceGroup = "javaapp-rg",
    [string]$Location = "eastus",
    [string]$AcrName = "javaappacr$(Get-Random -Maximum 99999)",
    [string]$AksClusterName = "javaapp-aks",
    [int]$AksNodeCount = 3,
    [string]$AksNodeSize = "Standard_D2s_v3"
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

Write-Host "=== Java Application Azure Deployment Script ===" -ForegroundColor Cyan
Write-Host ""

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "Azure CLI is not installed. Please install it first."
    Write-Host "Download from: https://aka.ms/installazurecliwindows"
    exit 1
}

Write-Status "Checking Azure CLI login status..."
try {
    az account show 2>$null | Out-Null
} catch {
    Write-Warning-Custom "Not logged in to Azure. Logging in..."
    az login
}

# Step 1: Create Resource Group
Write-Status "Creating Resource Group: $ResourceGroup"
az group create `
    --name $ResourceGroup `
    --location $Location `
    --output table

# Step 2: Create Azure Container Registry (ACR)
Write-Status "Creating Azure Container Registry: $AcrName"
az acr create `
    --resource-group $ResourceGroup `
    --name $AcrName `
    --sku Basic `
    --location $Location `
    --output table

# Step 3: Build and push Docker image to ACR
Write-Status "Building Docker image and pushing to ACR..."
az acr build `
    --registry $AcrName `
    --image javaapp:latest `
    --image javaapp:v1.0 `
    --file Dockerfile `
    . `
    --output table

# Step 4: Create AKS Cluster
Write-Status "Creating AKS Cluster: $AksClusterName (this may take 5-10 minutes)..."
az aks create `
    --resource-group $ResourceGroup `
    --name $AksClusterName `
    --node-count $AksNodeCount `
    --node-vm-size $AksNodeSize `
    --enable-managed-identity `
    --generate-ssh-keys `
    --attach-acr $AcrName `
    --network-plugin azure `
    --enable-cluster-autoscaler `
    --min-count 2 `
    --max-count 5 `
    --location $Location `
    --output table

# Step 5: Get AKS credentials
Write-Status "Getting AKS credentials..."
az aks get-credentials `
    --resource-group $ResourceGroup `
    --name $AksClusterName `
    --overwrite-existing

# Step 6: Enable AKS Add-ons
Write-Status "Enabling AKS monitoring and policy add-ons..."
az aks enable-addons `
    --resource-group $ResourceGroup `
    --name $AksClusterName `
    --addons monitoring,azure-policy `
    --workspace-resource-id "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroup/providers/Microsoft.OperationalInsights/workspaces/javaapp-workspace"

# Step 7: Enable Workload Identity
Write-Status "Enabling Workload Identity..."
az aks update `
    --resource-group $ResourceGroup `
    --name $AksClusterName `
    --enable-workload-identity `
    --enable-oidc-issuer

# Step 8: Get cluster info for manifest updates
Write-Status "Getting cluster information..."
$subscriptionId = az account show --query id -o tsv
$randomSuffix = Get-Random -Maximum 99999

# Step 9: Update deployment YAML with ACR name and Azure details
Write-Status "Updating AKS deployment files..."
$deploymentPath = "aks\deployment.yaml"
$servicePath = "aks\service.yaml"
$hpaPath = "aks\hpa.yaml"

$deploymentContent = Get-Content $deploymentPath -Raw
$deploymentContent = $deploymentContent -replace '\$\{ACR_NAME\}', $AcrName
Set-Content -Path $deploymentPath -Value $deploymentContent

$serviceContent = Get-Content $servicePath -Raw
$serviceContent = $serviceContent -replace '\$\{RANDOM_SUFFIX\}', $randomSuffix
Set-Content -Path $servicePath -Value $serviceContent

$hpaContent = Get-Content $hpaPath -Raw
$hpaContent = $hpaContent -replace '\$\{SUBSCRIPTION_ID\}', $subscriptionId
$hpaContent = $hpaContent -replace '\$\{RESOURCE_GROUP\}', $ResourceGroup
$hpaContent = $hpaContent -replace '\$\{AKS_CLUSTER\}', $AksClusterName
Set-Content -Path $hpaPath -Value $hpaContent

# Step 10: Deploy to AKS
Write-Status "Deploying application to Azure Kubernetes Service..."
kubectl apply -f aks/namespace.yaml
kubectl apply -f aks/serviceaccount.yaml
kubectl apply -f aks/configmap.yaml
kubectl apply -f aks/networkpolicy.yaml
kubectl apply -f aks/deployment.yaml
kubectl apply -f aks/service.yaml
kubectl apply -f aks/hpa.yaml
kubectl apply -f aks/pdb.yaml

# Step 11: Wait for deployment
Write-Status "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod `
    -l app=javaapp `
    -n javaapp `
    --timeout=300s

# Step 12: Get service external IP
Write-Status "Getting service external IP (this may take a few minutes)..."
Write-Host "Waiting for LoadBalancer to assign external IP..."
Start-Sleep -Seconds 60

$externalIp = kubectl get service javaapp-service -n javaapp -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
$dnsFqdn = "javaapp-$randomSuffix.$Location.cloudapp.azure.com"

# Step 13: Display deployment information
Write-Host ""
Write-Host "=== Deployment Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Resource Group: $ResourceGroup"
Write-Host "ACR Name: $AcrName"
Write-Host "AKS Cluster: $AksClusterName"
Write-Host "Namespace: javaapp"
Write-Host ""
Write-Host "Useful Commands:" -ForegroundColor Green
Write-Host "  View pods:     kubectl get pods -n javaapp"
Write-Host "  View logs:     kubectl logs -f <pod-name> -n javaapp"
Write-Host "  View service:  kubectl get service -n javaapp"
Write-Host "  Scale app:     kubectl scale deployment javaapp --replicas=5 -n javaapp"
Write-Host ""

if ($externalIp) {
    Write-Host "External IP: $externalIp" -ForegroundColor Green
    Write-Host "DNS Name: $dnsFqdn" -ForegroundColor Green
    Write-Host "Application URL: http://$externalIp" -ForegroundColor Green
    Write-Host "Application URL (DNS): http://$dnsFqdn" -ForegroundColor Green
} else {
    Write-Host "External IP is still being assigned. Run:" -ForegroundColor Yellow
    Write-Host "  kubectl get service javaapp-service -n javaapp"
}

Write-Host ""
Write-Host "AKS Features Enabled:" -ForegroundColor Cyan
Write-Host "  ✓ Azure Monitor for Containers"
Write-Host "  ✓ Azure Policy"
Write-Host "  ✓ Workload Identity"
Write-Host "  ✓ OIDC Issuer"
Write-Host "  ✓ Network Policies"
Write-Host "  ✓ Pod Disruption Budget"
Write-Host ""
Write-Host "View in Azure Portal:" -ForegroundColor Green
Write-Host "  https://portal.azure.com/#@/resource/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.ContainerService/managedClusters/$AksClusterName"
Write-Host ""
Write-Host "To clean up resources:" -ForegroundColor Green
Write-Host "  az group delete --name $ResourceGroup --yes --no-wait"
Write-Host ""
Write-Host "To monitor your deployment:" -ForegroundColor Cyan
Write-Host "  kubectl get pods -n javaapp --watch"
Write-Host "  kubectl top pods -n javaapp"
Write-Host "  az aks browse --resource-group $ResourceGroup --name $AksClusterName"
Write-Host "  az monitor metrics list --resource /subscriptions/$subscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.ContainerService/managedClusters/$AksClusterName"
Write-Host ""
