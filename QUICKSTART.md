# Quick Start Guide - Deploy to Azure

## Prerequisites Check

Before deploying, ensure you have:
- ✅ Azure CLI installed
- ✅ kubectl installed
- ✅ Azure subscription with permissions

## Installation (Windows)

```powershell
# Install Azure CLI
winget install Microsoft.AzureCLI

# Install kubectl
az aks install-cli

# Verify installations
az --version
kubectl version --client
```

## Deploy to Azure in 3 Steps

### Step 1: Login to Azure
```powershell
az login
```

### Step 2: Run Deployment Script
```powershell
# Navigate to project directory
cd c:\Users\musharm\source\repos\JavaApp

# Run deployment
.\deploy-to-azure.ps1
```

### Step 3: Monitor Deployment
```powershell
# Watch pods starting
kubectl get pods -n javaapp --watch

# View logs
kubectl logs -l app=javaapp -n javaapp --tail=50 -f
```

## What Gets Created

The script creates:
1. **Resource Group** - `javaapp-rg`
2. **Azure Container Registry** - For storing Docker images
3. **AKS Cluster** - 3 nodes with autoscaling
4. **Kubernetes Resources**:
   - Namespace: `javaapp`
   - Deployment: 3 replicas
   - Service: LoadBalancer
   - HPA: Auto-scaling 2-10 pods
   - ConfigMap: Application config

## Expected Timeline

- Resource Group Creation: ~10 seconds
- ACR Creation: ~30 seconds
- Docker Build & Push: ~2-3 minutes
- AKS Cluster Creation: ~5-10 minutes
- Application Deployment: ~1-2 minutes

**Total: ~10-15 minutes**

## Access Your Application

After deployment completes:

```powershell
# Get external IP
kubectl get service javaapp-service -n javaapp

# View application logs
kubectl logs -l app=javaapp -n javaapp --tail=100
```

## Verify Deployment

```powershell
# Check all resources
kubectl get all -n javaapp

# Check pod status
kubectl get pods -n javaapp

# Check autoscaler
kubectl get hpa -n javaapp

# Describe deployment
kubectl describe deployment javaapp -n javaapp
```

## Troubleshooting

### Issue: Pods not starting
```powershell
# Check pod details
kubectl describe pod <pod-name> -n javaapp

# Check events
kubectl get events -n javaapp --sort-by='.lastTimestamp'
```

### Issue: Can't access service
```powershell
# Verify service
kubectl get service javaapp-service -n javaapp

# Check endpoints
kubectl get endpoints javaapp-service -n javaapp
```

### Issue: Image pull errors
```powershell
# Verify ACR integration
az aks check-acr `
    --name javaapp-aks `
    --resource-group javaapp-rg `
    --acr <acr-name>.azurecr.io
```

## Clean Up Resources

When done with the demo:

```powershell
# Delete everything
az group delete --name javaapp-rg --yes --no-wait
```

This removes:
- AKS cluster
- Container registry
- All images
- All Kubernetes resources
- Load balancer
- Network resources

## Cost Estimate

Typical costs for running this demo:
- **AKS**: ~$150/month (3 Standard_D2s_v3 nodes)
- **ACR**: ~$5/month (Basic tier)
- **Load Balancer**: ~$20/month
- **Data Transfer**: Variable

**💡 Tip**: Delete resources when not in use to save costs!

## Next Steps

Once deployed:
1. ✅ Test autoscaling: `kubectl scale deployment javaapp --replicas=5 -n javaapp`
2. ✅ View metrics: `kubectl top pods -n javaapp`
3. ✅ Update application: Build new image and update deployment
4. ✅ Set up monitoring: Enable Azure Monitor for containers
5. ✅ Configure CI/CD: Use `azure-pipelines.yaml`

## Need Help?

- 📖 Full documentation: [DEPLOYMENT.md](DEPLOYMENT.md)
- 🔧 Manual steps: See DEPLOYMENT.md for detailed walkthrough
- 🐛 Issues: Check Kubernetes events and pod logs
- 💬 Azure support: `az support -h`
