# Azure Web App Deployment Checklist for cpu-app

This checklist guides you through deploying the remediated JavaBusinessApp to the Azure Web App `cpu-app`.

---

## Pre-Deployment Checklist

- [x] **Log4j Version Verified:** Version 2.20.0 confirmed (CVE-2021-44228 remediated)
- [x] **Build Successful:** `mvn clean verify` completed without errors
- [x] **Application Tested:** Application runs successfully with Log4j 2.20.0
- [x] **SBOM Generated:** Available at `evidence/sbom-cyclonedx.json`
- [x] **Dependency Tree:** Available at `evidence/dependency-tree.txt`
- [x] **Documentation Created:** Validation report and Dynatrace guide completed
- [x] **No Mitigation Flags:** Confirmed `-Dlog4j2.formatMsgNoLookups=true` removed
- [x] **Security Scan:** No code changes requiring CodeQL analysis

---

## Deployment Steps

### Step 1: Build Container Image

```bash
# Navigate to repository
cd /path/to/JavaBusinessApp

# Build Docker image
docker build -t cpu-app:2.20.0 .

# Verify the build
docker images | grep cpu-app
```

**Expected Output:**
```
cpu-app    2.20.0    <image-id>    <timestamp>    <size>
```

### Step 2: Tag for Azure Container Registry

```bash
# Replace <your-acr-name> with your Azure Container Registry name
ACR_NAME="<your-acr-name>"
ACR_LOGIN_SERVER="${ACR_NAME}.azurecr.io"

# Tag the image
docker tag cpu-app:2.20.0 ${ACR_LOGIN_SERVER}/cpu-app:2.20.0
docker tag cpu-app:2.20.0 ${ACR_LOGIN_SERVER}/cpu-app:latest
```

### Step 3: Login to Azure Container Registry

```bash
# Login to Azure
az login

# Login to ACR
az acr login --name ${ACR_NAME}
```

**Expected Output:**
```
Login Succeeded
```

### Step 4: Push Image to ACR

```bash
# Push tagged images
docker push ${ACR_LOGIN_SERVER}/cpu-app:2.20.0
docker push ${ACR_LOGIN_SERVER}/cpu-app:latest
```

**Expected Output:**
```
The push refers to repository [<acr>.azurecr.io/cpu-app]
...
2.20.0: digest: sha256:... size: ...
```

### Step 5: Update Azure Web App

#### Option A: Using Azure Portal

1. Navigate to the Azure Portal: https://portal.azure.com
2. Go to **Resource Groups** > `mrsharm-operations-agent-3p-rg`
3. Select **cpu-app** (Web App)
4. Navigate to **Deployment Center**
5. Update the **Image tag** to `2.20.0`
6. Click **Save**
7. Navigate to **Overview** and click **Restart**

#### Option B: Using Azure CLI

```bash
# Set variables
RESOURCE_GROUP="mrsharm-operations-agent-3p-rg"
WEB_APP_NAME="cpu-app"
IMAGE_TAG="${ACR_LOGIN_SERVER}/cpu-app:2.20.0"

# Update the Web App container
az webapp config container set \
  --name ${WEB_APP_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --docker-custom-image-name ${IMAGE_TAG}

# Restart the Web App
az webapp restart \
  --name ${WEB_APP_NAME} \
  --resource-group ${RESOURCE_GROUP}
```

**Expected Output:**
```
{
  "id": "/subscriptions/.../sites/cpu-app",
  "name": "cpu-app",
  "state": "Running",
  ...
}
```

### Step 6: Verify Deployment

#### 6.1 Check Application Logs

```bash
# Stream logs from Azure Web App
az webapp log tail \
  --name ${WEB_APP_NAME} \
  --resource-group ${RESOURCE_GROUP}
```

**Look for:**
- `Application started` message
- No Log4j-related errors
- Successful initialization of components

#### 6.2 Verify in Azure Portal

1. Navigate to **cpu-app** > **Log stream**
2. Verify successful startup messages
3. Check for any errors or warnings

#### 6.3 Check Application Insights (if configured)

1. Navigate to **cpu-app** > **Application Insights**
2. Review **Live Metrics** for:
   - Application is running
   - No exceptions related to Log4j
   - Normal request/response patterns

---

## Post-Deployment Verification

### Immediate Checks (0-15 minutes)

- [ ] **Application Status:** Web App shows "Running" status
- [ ] **HTTP Endpoint:** Application responds to HTTP requests (if applicable)
- [ ] **Startup Logs:** No errors in application logs
- [ ] **Container Status:** Container is running (check Container settings)
- [ ] **Health Check:** Application passes health check (if configured)

### Short-term Checks (15-60 minutes)

- [ ] **Dynatrace Detection:** Run Query 3 from `DYNATRACE_VERIFICATION_GUIDE.md`
  - Expected: Log4j version 2.20.0 detected
- [ ] **Application Metrics:** Normal CPU, memory, and request rates
- [ ] **Error Rate:** No increase in error rate
- [ ] **Log Analysis:** Run Query 1 and Query 4 from Dynatrace guide

### Long-term Monitoring (24 hours)

- [ ] **Exploitation Attempts:** Run Query 2 from Dynatrace guide
  - Expected: 0 JNDI/LDAP attack patterns
- [ ] **Network Activity:** Run Query 6 from Dynatrace guide
  - Expected: No unexpected LDAP/RMI connections
- [ ] **Application Stability:** No crashes or restarts
- [ ] **Performance:** Response times within normal range

---

## Rollback Plan

If deployment fails or issues are detected:

### Step 1: Identify Previous Working Image

```bash
# List images in ACR
az acr repository show-tags \
  --name ${ACR_NAME} \
  --repository cpu-app \
  --orderby time_desc
```

### Step 2: Rollback to Previous Version

```bash
# Replace <previous-tag> with the last known good version
PREVIOUS_TAG="<previous-tag>"

az webapp config container set \
  --name ${WEB_APP_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --docker-custom-image-name ${ACR_LOGIN_SERVER}/cpu-app:${PREVIOUS_TAG}

az webapp restart \
  --name ${WEB_APP_NAME} \
  --resource-group ${RESOURCE_GROUP}
```

### Step 3: Investigate Issue

1. Review application logs
2. Check Dynatrace for errors
3. Review deployment logs in Azure Portal
4. Document the issue for troubleshooting

---

## Dynatrace Alert Configuration

After successful deployment, configure alerts as described in `DYNATRACE_VERIFICATION_GUIDE.md`:

### Alert 1: JNDI Lookup Detection
- [ ] Created in Dynatrace
- [ ] Tested with sample data
- [ ] Notification channels configured

### Alert 2: Vulnerable Log4j Version Detection
- [ ] Created in Dynatrace
- [ ] Threshold set to version < 2.17.1
- [ ] Notification channels configured

### Alert 3: Unexpected LDAP Connections
- [ ] Created in Dynatrace
- [ ] Network monitoring configured
- [ ] Notification channels configured

---

## Documentation Updates

After successful deployment:

- [ ] Update `README.md` with deployment date
- [ ] Document deployment in change management system
- [ ] Update compliance documentation with SBOM
- [ ] Archive deployment logs for audit trail

---

## Compliance and Reporting

### For Security Team

1. **Provide SBOM:**
   - Location: `evidence/sbom-cyclonedx.json`
   - Format: CycloneDX 1.4
   - Contains: Full dependency tree with hashes

2. **Provide Validation Report:**
   - Location: `LOG4J_REMEDIATION_VALIDATION.md`
   - Status: ✅ Remediation Complete
   - Log4j Version: 2.20.0

3. **Provide Dynatrace Evidence:**
   - Run all queries from `DYNATRACE_VERIFICATION_GUIDE.md`
   - Export results to CSV/JSON
   - Attach to incident closure report

### For Compliance Audit

1. **CVE Remediation Evidence:**
   - CVE: CVE-2021-44228
   - Status: Remediated
   - Date: 2025-10-22
   - Evidence: SBOM, dependency tree, validation report

2. **Deployment Evidence:**
   - Deployment date and time
   - Image tag: 2.20.0
   - Deployed by: [Your name/team]
   - Approved by: [Approver name]

3. **Monitoring Evidence:**
   - Dynatrace queries executed
   - Results: No exploitation attempts
   - Alerts configured: Yes

---

## Troubleshooting

### Issue: Container fails to start

**Symptoms:**
- Web App status shows "Starting" for extended period
- Logs show container crash or restart loop

**Resolution:**
1. Check container logs: `az webapp log tail`
2. Verify the image is correct: `az acr repository show-tags`
3. Check application settings for missing environment variables
4. Review Dockerfile for any issues
5. Test locally: `docker run -p 8080:8080 cpu-app:2.20.0`

### Issue: Application not responding

**Symptoms:**
- Web App status shows "Running"
- HTTP requests timeout or return 503

**Resolution:**
1. Check application logs for startup errors
2. Verify port configuration (default: 8080)
3. Check health check configuration
4. Review Application Insights for exceptions
5. Restart the Web App

### Issue: Dynatrace not detecting Log4j version

**Symptoms:**
- Query 3 returns no results
- Process Group shows "Unknown" for Log4j version

**Resolution:**
1. Wait 15-30 minutes for Dynatrace to scan the process
2. Verify OneAgent is installed and running
3. Check OneAgent version (update if needed)
4. Manually verify JAR file in container: `docker exec -it <container> sh -c "cd /app && unzip -l app.jar | grep log4j"`
5. Restart OneAgent on the host

### Issue: False positive JNDI detection

**Symptoms:**
- Query 2 returns results
- Results are legitimate log messages containing "jndi" or "ldap"

**Resolution:**
1. Review the full log context
2. Verify the source (expected application code vs. external input)
3. If legitimate, add exception to the alert rule
4. Document the false positive for future reference

---

## Success Criteria

Deployment is considered successful when:

✅ All Pre-Deployment Checklist items completed  
✅ All Deployment Steps completed without errors  
✅ All Immediate Checks (0-15 min) passed  
✅ All Short-term Checks (15-60 min) passed  
✅ Dynatrace queries confirm Log4j 2.20.0  
✅ No exploitation attempts detected  
✅ Application operating normally for 24 hours  
✅ All alerts configured and tested  
✅ Documentation updated  
✅ Compliance evidence provided  

---

## Contact Information

### For Deployment Issues
- **Azure Support:** https://portal.azure.com -> Support + troubleshooting
- **Resource Group:** mrsharm-operations-agent-3p-rg
- **Subscription ID:** be8d491e-109c-4ee1-aaee-dc7615af0a42

### For Security Issues
- **Original Issue:** mrsharm/JavaBusinessApp#1
- **SRE Agent:** [Azure Portal Agent Link](https://portal.azure.com/?feature.customPortal=false&feature.canmodifystamps=true&feature.fastmanifest=false&nocdn=force&websitesextension_loglevel=verbose&Microsoft_Azure_PaasServerless=beta&microsoft_azure_paasserverless_assettypeoptions=%7B%22SreAgentCustomMenu%22%3A%7B%22options%22%3A%22%22%7D%7D#view/Microsoft_Azure_PaasServerless/AgentFrameBlade.ReactView/id/%2Fsubscriptions%2F%2FresourceGroups%2F%2Fproviders%2FMicrosoft.App%2Fagents%2F/sreLink/%2Fviews%2Factivities%2Fthreads%2F8e8299c5-4443-4fea-96c6-431677b8db8d)

### For Dynatrace Issues
- **Dynatrace Documentation:** https://docs.dynatrace.com
- **Dynatrace Support:** [Your Dynatrace support channel]

---

**Checklist Version:** 1.0  
**Last Updated:** 2025-10-22  
**Related Documents:**
- `LOG4J_REMEDIATION_VALIDATION.md`
- `DYNATRACE_VERIFICATION_GUIDE.md`
- `evidence/sbom-cyclonedx.json`
