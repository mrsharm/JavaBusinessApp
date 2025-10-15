# 🎉 Azure Kubernetes Service (AKS) Deployment Ready!

Your Java application is now fully optimized for Azure Kubernetes Service with native Azure integrations!

## ✅ What's Configured for AKS

### 📦 Azure-Optimized Manifests (`aks/` folder)

1. **namespace.yaml** - Azure Workload Identity enabled
2. **serviceaccount.yaml** - Azure AD federated identity
3. **configmap.yaml** - Application configuration
4. **deployment.yaml** - AKS-optimized with:
   - Azure Workload Identity annotations
   - Pod anti-affinity for high availability
   - Security context hardening
   - Linux node selector
   - Prometheus annotations

5. **service.yaml** - Azure Load Balancer with:
   - Azure DNS labels for custom domains
   - Health probe configuration
   - Session affinity
   - External traffic policy for source IP preservation

6. **hpa.yaml** - Horizontal Pod Autoscaler with:
   - Azure Monitor metrics integration
   - CPU and memory-based scaling
   - Scale-up/down policies

7. **networkpolicy.yaml** - Azure Network Policy for security
8. **pdb.yaml** - Pod Disruption Budget for reliability

### 🔐 Azure-Native Integrations

#### Workload Identity (OIDC)
```yaml
Labels:
  azure.workload.identity/use: "true"

Annotations:
  azure.workload.identity/client-id: "${AZURE_CLIENT_ID}"
  azure.workload.identity/tenant-id: "${AZURE_TENANT_ID}"
```

#### Azure Load Balancer
```yaml
Annotations:
  service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: "/health"
  service.beta.kubernetes.io/azure-dns-label-name: "javaapp-${RANDOM}"
```

#### Azure Monitor Integration
```yaml
Annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
```

### 🚀 Deployment Scripts Enhanced

Both `deploy-to-azure.ps1` and `deploy-to-azure.sh` now:
- ✅ Enable Azure Monitor for Containers
- ✅ Enable Azure Policy add-on
- ✅ Configure Workload Identity
- ✅ Enable OIDC Issuer
- ✅ Create Log Analytics workspace
- ✅ Set up DNS labels
- ✅ Deploy all AKS resources
- ✅ Provide Azure Portal links

## 🏗️ AKS Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                      Azure Subscription                         │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │         Resource Group: javaapp-rg                        │  │
│  │                                                           │  │
│  │  ┌─────────────────────────────────────────────────────┐ │  │
│  │  │  Azure Container Registry (ACR)                     │ │  │
│  │  │  • Private registry for container images           │ │  │
│  │  │  • Integrated with AKS (no passwords)              │ │  │
│  │  └─────────────────────────────────────────────────────┘ │  │
│  │                                                           │  │
│  │  ┌─────────────────────────────────────────────────────┐ │  │
│  │  │  Log Analytics Workspace                            │ │  │
│  │  │  • Container Insights                               │ │  │
│  │  │  • Query logs with KQL                              │ │  │
│  │  └─────────────────────────────────────────────────────┘ │  │
│  │                                                           │  │
│  │  ┌─────────────────────────────────────────────────────┐ │  │
│  │  │  Azure Kubernetes Service (AKS)                     │ │  │
│  │  │  ┌───────────────────────────────────────────────┐  │ │  │
│  │  │  │  System Node Pool (3 nodes)                   │  │ │  │
│  │  │  │  • Standard_D2s_v3                            │  │ │  │
│  │  │  │  • Auto-scale: 2-5 nodes                      │  │ │  │
│  │  │  │  • Azure CNI networking                       │  │ │  │
│  │  │  └───────────────────────────────────────────────┘  │ │  │
│  │  │                                                      │ │  │
│  │  │  ┌───────────────────────────────────────────────┐  │ │  │
│  │  │  │  Namespace: javaapp                           │  │ │  │
│  │  │  │  • Workload Identity enabled                  │  │ │  │
│  │  │  │  • Network policies active                    │  │ │  │
│  │  │  │                                               │  │ │  │
│  │  │  │  ┌─────────────────────────────────────────┐  │  │ │  │
│  │  │  │  │  Service Account                        │  │  │ │  │
│  │  │  │  │  • Federated with Azure AD             │  │  │ │  │
│  │  │  │  │  • OIDC token exchange                 │  │  │ │  │
│  │  │  │  └─────────────────────────────────────────┘  │  │ │  │
│  │  │  │                                               │  │ │  │
│  │  │  │  ┌─────────────────────────────────────────┐  │  │ │  │
│  │  │  │  │  Deployment (javaapp)                   │  │  │ │  │
│  │  │  │  │  • 3 replicas (HA)                     │  │  │ │  │
│  │  │  │  │  • Pod anti-affinity                   │  │  │ │  │
│  │  │  │  │  • Rolling updates                      │  │  │ │  │
│  │  │  │  │  • Health checks                        │  │  │ │  │
│  │  │  │  │  • Resource limits                      │  │  │ │  │
│  │  │  │  └─────────────────────────────────────────┘  │  │ │  │
│  │  │  │                                               │  │ │  │
│  │  │  │  ┌─────────────────────────────────────────┐  │  │ │  │
│  │  │  │  │  HPA (Auto-Scaler)                     │  │  │ │  │
│  │  │  │  │  • Min: 2 pods                         │  │  │ │  │
│  │  │  │  │  • Max: 10 pods                        │  │  │ │  │
│  │  │  │  │  • Azure Monitor metrics               │  │  │ │  │
│  │  │  │  └─────────────────────────────────────────┘  │  │ │  │
│  │  │  │                                               │  │ │  │
│  │  │  │  ┌─────────────────────────────────────────┐  │  │ │  │
│  │  │  │  │  Network Policy                        │  │  │ │  │
│  │  │  │  │  • Ingress rules                       │  │  │ │  │
│  │  │  │  │  • Egress rules                        │  │  │ │  │
│  │  │  │  │  • Azure CNI enforcement               │  │  │ │  │
│  │  │  │  └─────────────────────────────────────────┘  │  │ │  │
│  │  │  │                                               │  │ │  │
│  │  │  │  ┌─────────────────────────────────────────┐  │  │ │  │
│  │  │  │  │  Pod Disruption Budget                 │  │  │ │  │
│  │  │  │  │  • Min available: 1                    │  │  │ │  │
│  │  │  │  │  • Safe cluster operations             │  │  │ │  │
│  │  │  │  └─────────────────────────────────────────┘  │  │ │  │
│  │  │  └───────────────────────────────────────────────┘  │ │  │
│  │  │                                                      │ │  │
│  │  │  ┌───────────────────────────────────────────────┐  │ │  │
│  │  │  │  Azure Load Balancer (Public IP)              │  │ │  │
│  │  │  │  • DNS: javaapp-*.eastus.cloudapp.azure.com  │  │ │  │
│  │  │  │  • Health probes configured                   │  │ │  │
│  │  │  │  • Session affinity                           │  │ │  │
│  │  │  └───────────────────────────────────────────────┘  │ │  │
│  │  └─────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │   Internet     │
                    │   Users        │
                    └────────────────┘
```

## 🚀 Deploy Now!

### One-Command Deployment
```powershell
.\deploy-to-azure.ps1
```

This automatically:
1. Creates Resource Group
2. Creates Azure Container Registry
3. Builds & pushes Docker image
4. Creates AKS cluster with:
   - Azure Monitor enabled
   - Azure Policy enabled
   - Workload Identity configured
   - Network policies enabled
5. Deploys all 8 AKS manifests
6. Configures auto-scaling
7. Sets up DNS and Load Balancer

**Deployment time: ~10-15 minutes**

## 📊 Azure Features Summary

### Enabled Automatically
| Feature | Status | Purpose |
|---------|--------|---------|
| Azure Monitor | ✅ | Container Insights & metrics |
| Azure Policy | ✅ | Compliance enforcement |
| Workload Identity | ✅ | Azure AD integration |
| OIDC Issuer | ✅ | Token federation |
| Network Policies | ✅ | Network security |
| Auto-scaling | ✅ | Cluster & pod scaling |
| Log Analytics | ✅ | Centralized logging |
| DNS Labels | ✅ | Custom domains |
| Health Probes | ✅ | Load balancer health |
| Pod Disruption Budget | ✅ | High availability |

### Configuration Details

#### Container Insights
```
Workspace: javaapp-workspace
Region: East US
Retention: 30 days (configurable)
```

#### Workload Identity
```
OIDC Issuer: Enabled
Token Exchange: Configured
Service Account: Federated with Azure AD
```

#### Network Security
```
Network Plugin: Azure CNI
Network Policy: Azure
Ingress: Port 8080 only
Egress: DNS (53) and HTTPS (443)
```

## 🛠️ Management Commands

### AKS-Specific Commands
```powershell
# Open Kubernetes dashboard in browser
az aks browse --resource-group javaapp-rg --name javaapp-aks

# View cluster in Azure Portal
https://portal.azure.com/#@/resource/subscriptions/{subscription}/resourceGroups/javaapp-rg/providers/Microsoft.ContainerService/managedClusters/javaapp-aks

# View Container Insights
az monitor log-analytics workspace show --resource-group javaapp-rg --workspace-name javaapp-workspace

# Query logs with KQL
az monitor log-analytics query --workspace <id> --analytics-query "ContainerLog | where Image contains 'javaapp' | take 100"

# View metrics
az monitor metrics list --resource <aks-resource-id> --metric "node_cpu_usage_percentage"

# Scale node pool
az aks nodepool scale --resource-group javaapp-rg --cluster-name javaapp-aks --name nodepool1 --node-count 5

# Stop/Start cluster (cost saving)
az aks stop --resource-group javaapp-rg --name javaapp-aks
az aks start --resource-group javaapp-rg --name javaapp-aks
```

### Application Management
```powershell
# View all AKS resources
kubectl get all -n javaapp

# View with Azure labels
kubectl get pods -n javaapp --show-labels

# View logs (integrated with Azure Monitor)
kubectl logs -l app=javaapp -n javaapp --tail=100 -f

# View metrics
kubectl top pods -n javaapp
kubectl top nodes

# Describe resources
kubectl describe deployment javaapp -n javaapp
kubectl describe hpa javaapp-hpa -n javaapp
kubectl describe networkpolicy javaapp-network-policy -n javaapp
```

## 💰 Cost Breakdown

### Monthly Costs (24/7 operation)
- **AKS Nodes** (3x Standard_D2s_v3): $144/month
- **Azure Load Balancer**: $18/month
- **Log Analytics Workspace**: $8/month
- **Azure Container Registry (Basic)**: $5/month
- **Data Transfer**: $5-10/month
- **Total**: ~$180-190/month

### Cost Optimization
```powershell
# Use smaller VMs for dev/test
--node-vm-size Standard_B2s  # $15/node/month

# Stop cluster overnight (saves ~60%)
az aks stop --resource-group javaapp-rg --name javaapp-aks

# Use spot instances (saves ~70-90%)
az aks nodepool add --resource-group javaapp-rg --cluster-name javaapp-aks \
    --name spotpool --priority Spot --eviction-policy Delete --spot-max-price -1

# Delete when done
az group delete --name javaapp-rg --yes --no-wait
```

## 🔒 Security Highlights

### Pod Security
- ✅ Non-root user (UID 1000)
- ✅ No privilege escalation
- ✅ Capabilities dropped
- ✅ Read-only root filesystem (where possible)
- ✅ Resource limits enforced

### Network Security
- ✅ Network policies enabled
- ✅ Ingress limited to port 8080
- ✅ Egress limited to DNS and HTTPS
- ✅ Azure CNI with network isolation

### Azure Integration
- ✅ Workload Identity (no static credentials)
- ✅ Azure Policy compliance
- ✅ Azure Defender ready
- ✅ Private ACR integration

## 📈 Scaling Configuration

### Horizontal Pod Autoscaler
```yaml
Min Replicas: 2
Max Replicas: 10
Target CPU: 70%
Target Memory: 80%
Scale Up: +100% every 30s (max 2 pods)
Scale Down: -50% every 60s (5min stabilization)
```

### Cluster Autoscaler
```yaml
Min Nodes: 2
Max Nodes: 5
Scale based on: Pod resource requests
```

## 🆘 Troubleshooting

### Pod Issues
```powershell
# Check pod status
kubectl get pods -n javaapp

# Describe pod
kubectl describe pod <pod-name> -n javaapp

# View logs
kubectl logs <pod-name> -n javaapp
kubectl logs <pod-name> -n javaapp --previous

# Events
kubectl get events -n javaapp --sort-by='.lastTimestamp'
```

### AKS Issues
```powershell
# Cluster health
az aks show --resource-group javaapp-rg --name javaapp-aks --query "powerState"

# Node status
kubectl get nodes
kubectl describe node <node-name>

# ACR integration
az aks check-acr --name javaapp-aks --resource-group javaapp-rg --acr <acr>.azurecr.io
```

### Network Issues
```powershell
# Test network policy
kubectl run -it --rm debug --image=busybox --restart=Never -n javaapp -- wget -O- http://javaapp-service:8080

# View network policy
kubectl describe networkpolicy javaapp-network-policy -n javaapp
```

## 🎯 Next Steps

1. ✅ **Monitor Application**
   - View in Azure Portal
   - Set up alerts
   - Configure dashboards

2. ✅ **Secure with Azure Defender**
   ```powershell
   az security pricing create --name KubernetesService --tier Standard
   ```

3. ✅ **Add Azure Key Vault Integration**
   ```powershell
   az aks enable-addons --addons azure-keyvault-secrets-provider \
       --name javaapp-aks --resource-group javaapp-rg
   ```

4. ✅ **Configure Custom Domain**
   - Map DNS to Load Balancer IP
   - Add ingress controller
   - Configure SSL/TLS

5. ✅ **Set Up GitOps**
   ```powershell
   az k8s-configuration flux create
   ```

## 📚 Resources

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Detailed deployment guide
- **[QUICKSTART.md](QUICKSTART.md)** - Quick start guide
- **[aks/](aks/)** - All AKS manifest files
- **[Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)**
- **[Azure Monitor for Containers](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/)**

---

**Your application is now fully optimized for Azure Kubernetes Service!** 🎉

Run `.\deploy-to-azure.ps1` to deploy in minutes with full Azure integration!
