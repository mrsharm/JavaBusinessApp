# Java Application - Azure Kubernetes Service (AKS) Ready

A cloud-native Java application with Log4j 2 logging, containerized with Docker and optimized for Azure Kubernetes Service (AKS) deployment with Azure-native integrations.

## ✅ SECURITY STATUS

**This application uses a secure version of Log4j.**

- **Version**: Log4j 2.20.0
- **Status**: ✅ No known vulnerabilities
- **CVE-2021-44228**: Remediated (was in 2.14.1, fixed in 2.17.1+)
- **Last Validated**: 2025-10-22

See `QUICK_REFERENCE.md` for remediation details and `LOG4J_REMEDIATION_VALIDATION.md` for full validation report.

## 🚀 Quick Deploy to Azure

```powershell
.\deploy-to-azure.ps1
```

Automatically deploys to Azure with:
- ✅ Azure Container Registry (ACR)
- ✅ Azure Kubernetes Service (AKS)
- ✅ Azure Monitor & Application Insights
- ✅ Azure Policy compliance
- ✅ Workload Identity integration
- ✅ Auto-scaling & high availability

## 📁 Project Structure

```
JavaApp/
├── pom.xml                    # Maven build configuration
├── Dockerfile                 # Multi-stage container build
├── deploy-to-azure.ps1       # Automated AKS deployment
├── deploy-to-azure.sh        # Bash deployment script
├── azure-pipelines.yaml      # Azure DevOps CI/CD
├── src/main/java/            # Java application code
├── aks/                      # AKS-optimized manifests
│   ├── namespace.yaml        # Namespace with Azure labels
│   ├── serviceaccount.yaml   # Workload Identity integration
│   ├── configmap.yaml        # App configuration
│   ├── deployment.yaml       # AKS deployment
│   ├── service.yaml          # Azure Load Balancer
│   ├── hpa.yaml             # Auto-scaler
│   ├── pdb.yaml             # Pod Disruption Budget
│   └── networkpolicy.yaml   # Network security
└── DEPLOYMENT.md            # Detailed guide
```

## ✨ Azure-Native Features

### AKS Integration
- 🔐 **Workload Identity** - Azure AD pod identity
- 📊 **Azure Monitor** - Container Insights & Log Analytics
- 🛡️ **Azure Policy** - Compliance enforcement
- 🌐 **Azure Load Balancer** - With DNS labels & health probes
- 🔒 **Network Policies** - Azure CNI security
- 📈 **Azure Metrics** - HPA with Azure Monitor integration
- 🎯 **Service Mesh Ready** - Linkerd annotations

### Security Features
- Non-root containers
- Pod Security Standards
- Network isolation
- Resource limits enforced
- Health checks configured
- Pod disruption budgets

## 📋 Prerequisites

```powershell
# Install Azure CLI
winget install Microsoft.AzureCLI

# Install kubectl
az aks install-cli

# Login to Azure
az login
```

## 🏃 Quick Start

### 1. Deploy to AKS
```powershell
.\deploy-to-azure.ps1
```

### 2. Monitor Deployment
```powershell
kubectl get pods -n javaapp --watch
kubectl logs -l app=javaapp -n javaapp -f
```

### 3. Access Application
```powershell
kubectl get service javaapp-service -n javaapp
```

## ☸️ AKS Resources

**Created automatically:**
- Namespace with Workload Identity
- Service Account with Azure federation
- ConfigMap for application config
- Deployment (3 replicas, pod anti-affinity)
- Azure Load Balancer service with DNS
- Horizontal Pod Autoscaler (2-10 pods)
- Pod Disruption Budget
- Network Policy

**Resource Limits:**
```yaml
Requests: 250m CPU, 256Mi Memory
Limits:   500m CPU, 512Mi Memory
Replicas: 3 (scales 2-10 based on load)
```

## 🔒 Azure Security

**Enabled by default:**
- Azure Monitor for Containers
- Azure Policy for compliance
- Workload Identity (OIDC)
- Network Policies (Azure CNI)
- Pod Security Standards
- Azure Defender (recommended)

## 📊 Monitoring

### Azure Portal
```powershell
# Open AKS dashboard
az aks browse --resource-group javaapp-rg --name javaapp-aks
```

### Azure Monitor
```powershell
# Query container logs
az monitor log-analytics query \
    --workspace <id> \
    --analytics-query "ContainerLog | where Image contains 'javaapp'"
```

### kubectl
```powershell
kubectl get all -n javaapp
kubectl top pods -n javaapp
kubectl logs -l app=javaapp -n javaapp
```

## 🛠️ Management

### Scale Application
```powershell
kubectl scale deployment javaapp --replicas=5 -n javaapp
```

### Update Application
```powershell
az acr build --registry <acr> --image javaapp:v2.0 .
kubectl set image deployment/javaapp javaapp=<acr>.azurecr.io/javaapp:v2.0 -n javaapp
```

### View Metrics
```powershell
az monitor metrics list --resource <aks-resource-id>
kubectl top nodes
kubectl top pods -n javaapp
```

## 💰 Cost Management

**Monthly costs (~$180-200):**
- AKS Nodes: ~$150
- Load Balancer: ~$20
- Azure Monitor: ~$10
- ACR: ~$5

**Save costs:**
```powershell
# Stop cluster
az aks stop --resource-group javaapp-rg --name javaapp-aks

# Delete resources
az group delete --name javaapp-rg --yes --no-wait
```

## 🔄 CI/CD

Includes Azure DevOps pipeline with:
- Maven build & test
- Security scanning (OWASP)
- Container build & push
- Automated AKS deployment
- Dev/Prod environments

See `azure-pipelines.yaml` for details.

## 📚 Documentation

- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Log4j remediation quick summary ⭐ START HERE
- **[LOG4J_REMEDIATION_VALIDATION.md](LOG4J_REMEDIATION_VALIDATION.md)** - Complete validation report
- **[DYNATRACE_VERIFICATION_GUIDE.md](DYNATRACE_VERIFICATION_GUIDE.md)** - Dynatrace monitoring queries
- **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Azure Web App deployment guide
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - AKS deployment guide
- **[QUICKSTART.md](QUICKSTART.md)** - Quick start
- **[aks/](aks/)** - Kubernetes manifest files
- **[evidence/](evidence/)** - SBOM and dependency evidence

## 🆘 Troubleshooting

```powershell
# Pod issues
kubectl describe pod <pod> -n javaapp
kubectl logs <pod> -n javaapp --previous

# AKS health
az aks show --resource-group javaapp-rg --name javaapp-aks

# ACR integration
az aks check-acr --name javaapp-aks --resource-group javaapp-rg --acr <acr>.azurecr.io
```

## 🔗 Resources

- [Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure Monitor for Containers](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/)
- [Azure Workload Identity](https://azure.github.io/azure-workload-identity/)
- [AKS Best Practices](https://docs.microsoft.com/en-us/azure/aks/best-practices)

---

**Optimized for Azure Kubernetes Service** | Deploy in minutes! 🚀
