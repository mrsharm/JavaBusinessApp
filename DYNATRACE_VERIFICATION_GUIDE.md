# Dynatrace Verification Guide for cpu-app

This guide provides step-by-step instructions for verifying the Log4j remediation and monitoring for exploitation attempts using Dynatrace.

---

## Prerequisites

- Access to Dynatrace tenant
- Access to the `cpu-app` application monitoring data
- Knowledge of the Process Group ID for cpu-app (see "Finding Your Process Group" below)

---

## Finding Your Process Group

1. Log in to your Dynatrace tenant
2. Navigate to **Infrastructure > Processes and containers**
3. Search for "cpu-app" or filter by:
   - Azure Resource Group: `mrsharm-operations-agent-3p-rg`
   - Azure Subscription: `be8d491e-109c-4ee1-aaee-dc7615af0a42`
4. Click on the matching process
5. Copy the **Process Group ID** from the URL or entity details panel
   - Format: `PROCESS_GROUP-XXXXXXXXXXXX`
6. Replace `YOUR_PROCESS_GROUP_ID` in the queries below with this value

---

## Query 1: Recent Activity Check (Last 2 Hours)

**Purpose:** Verify that cpu-app is logging normally and check for any suspicious activity.

**Query:**
```dql
fetch logs, from: now()-2h
| filter contains(content, "cpu-app") or contains(message, "cpu-app")
| sort timestamp desc
| limit 10
| fieldsAdd logLine = if(isNotNull(content), then: content, else: message)
| fieldsKeep timestamp, logLine
```

**Expected Result:**
- Normal application logs (if any)
- No JNDI/LDAP attack patterns
- No error messages related to Log4j lookups

**How to Run:**
1. Navigate to **Observe and explore > Logs**
2. Switch to DQL (Dynatrace Query Language) mode
3. Paste the query above
4. Click "Run query"
5. Review the results

---

## Query 2: JNDI/LDAP Attack Pattern Detection (Last 24 Hours)

**Purpose:** Detect any Log4Shell exploitation attempts.

**Query:**
```dql
fetch logs, from: now()-24h
| filter matchesPhrase(content, "jndi:") 
    or matchesPhrase(content, "ldap://") 
    or matchesPhrase(content, "${jndi")
    or matchesPhrase(content, "Lookup")
| filter dt.process_group_instance == "YOUR_PROCESS_GROUP_ID"
| sort timestamp desc
| limit 50
| fieldsKeep timestamp, content, log.source, loglevel, dt.entity.process_group
```

**⚠️ Replace `YOUR_PROCESS_GROUP_ID` with the actual Process Group ID**

**Expected Result:**
- **IDEAL:** 0 results
- **WARNING:** Any results containing suspicious patterns like:
  - `${jndi:ldap://...}`
  - `${jndi:rmi://...}`
  - `${jndi:dns://...}`
  - Base64-encoded payloads

**Action if Suspicious Patterns Found:**
1. Document the timestamp and log content
2. Check the source IP address and user agent
3. Review related HTTP requests around the same time
4. Escalate to security team immediately
5. Consider isolating the affected instance

---

## Query 3: Log4j Version Verification

**Purpose:** Confirm that Dynatrace detects the correct Log4j version in the running process.

**Query:**
```dql
fetch dt.entity.process_group_instance
| filter contains(softwareTechnologies, "JAVA")
| filter contains(entity.name, "cpu-app")
| fieldsAdd processGroupName = entity.name
| expand softwareTechnologies
| filter softwareTechnologies.technology == "LOG4J"
| fieldsKeep processGroupName, softwareTechnologies.version, softwareTechnologies.technology
```

**Expected Result:**
- Log4j version: **2.20.0** or higher
- Technology: LOG4J

**Note:** It may take a few minutes after deployment for Dynatrace to detect the new version.

---

## Query 4: Error and Warning Analysis

**Purpose:** Identify any Log4j-related errors or warnings.

**Query:**
```dql
fetch logs, from: now()-24h
| filter dt.process_group_instance == "YOUR_PROCESS_GROUP_ID"
| filter loglevel == "ERROR" or loglevel == "WARN"
| filter contains(content, "log4j") 
    or contains(content, "lookup") 
    or contains(content, "jndi")
    or contains(content, "Log4j")
| sort timestamp desc
| limit 100
| fieldsKeep timestamp, loglevel, content, log.source
```

**⚠️ Replace `YOUR_PROCESS_GROUP_ID` with the actual Process Group ID**

**Expected Result:**
- No errors related to Log4j initialization
- No warnings about vulnerable versions
- No JNDI-related errors

**Action if Errors Found:**
Review the error messages carefully. Common legitimate errors:
- Configuration file issues (non-security related)
- Appender initialization issues

Investigate immediately if you see:
- "Vulnerable version detected"
- JNDI initialization failures
- Security-related warnings

---

## Query 5: HTTP Request Pattern Analysis

**Purpose:** Detect HTTP requests with potential Log4Shell payloads in headers or parameters.

**Query:**
```dql
fetch dt.entity.service_method
| filter dt.entity.service == "YOUR_SERVICE_ID"
| expand requests
| filter contains(requests.headers, "${jndi") 
    or contains(requests.headers, "ldap://")
    or contains(requests.queryParameters, "${jndi")
| fieldsKeep timestamp, requests.url, requests.headers, requests.queryParameters, requests.sourceIp
| sort timestamp desc
| limit 50
```

**Note:** Replace `YOUR_SERVICE_ID` with the actual Service ID for cpu-app.

**Expected Result:**
- **IDEAL:** 0 results
- **CRITICAL:** Any results indicate attempted exploitation

---

## Query 6: Network Connection Monitoring

**Purpose:** Detect unexpected outbound LDAP or RMI connections (potential indicators of successful exploitation).

**Query:**
```dql
fetch dt.entity.process_group_instance
| filter entity.name contains "cpu-app"
| expand networkTraffic
| filter networkTraffic.port in (389, 636, 1099) 
    or networkTraffic.protocol in ("LDAP", "RMI")
| filter networkTraffic.direction == "OUTBOUND"
| fieldsKeep timestamp, networkTraffic.destinationIp, networkTraffic.port, networkTraffic.protocol
| sort timestamp desc
```

**Expected Result:**
- No unexpected outbound LDAP (389, 636) connections
- No unexpected outbound RMI (1099) connections

**⚠️ Alert:** Any unexpected outbound connections to LDAP/RMI servers could indicate:
- Successful exploitation
- Data exfiltration attempt
- Command and control communication

---

## Query 7: Application Startup Verification

**Purpose:** Verify successful application startup after remediation deployment.

**Query:**
```dql
fetch logs, from: now()-1h
| filter dt.process_group_instance == "YOUR_PROCESS_GROUP_ID"
| filter contains(content, "Application started") 
    or contains(content, "started successfully")
    or contains(content, "Server startup")
| sort timestamp desc
| limit 10
| fieldsKeep timestamp, content, loglevel
```

**⚠️ Replace `YOUR_PROCESS_GROUP_ID` with the actual Process Group ID**

**Expected Result:**
- Successful application startup message
- Timestamp should be after the deployment
- No errors in startup sequence

---

## Automated Alert Configuration

### Alert 1: JNDI Lookup Detection

**Alert Name:** Log4Shell Exploitation Attempt - cpu-app  
**Severity:** Critical  
**Metric:** Custom log event  
**Condition:**
```dql
fetch logs, from: now()-5m
| filter dt.process_group_instance == "YOUR_PROCESS_GROUP_ID"
| filter matchesPhrase(content, "${jndi") or matchesPhrase(content, "ldap://")
| summarize count()
```
**Threshold:** > 0 events  
**Notification:** Immediate (email, SMS, PagerDuty)

### Alert 2: Vulnerable Log4j Version Detected

**Alert Name:** Vulnerable Log4j Version - cpu-app  
**Severity:** Critical  
**Metric:** Software component version  
**Condition:** Log4j version < 2.17.1 detected in cpu-app process group  
**Notification:** Immediate

### Alert 3: Unexpected LDAP Connections

**Alert Name:** Suspicious Outbound LDAP Connection - cpu-app  
**Severity:** High  
**Metric:** Network traffic  
**Condition:** Outbound connection to port 389, 636, or 1099  
**Notification:** Within 5 minutes

---

## Validation Checklist

Use this checklist after deploying the remediated application:

- [ ] Query 1 (Recent Activity): Executed successfully, no suspicious activity
- [ ] Query 2 (JNDI Pattern Detection): 0 results or all false positives documented
- [ ] Query 3 (Log4j Version): Version 2.20.0 confirmed in Dynatrace
- [ ] Query 4 (Error Analysis): No Log4j-related errors or warnings
- [ ] Query 5 (HTTP Request Patterns): No exploitation attempts detected
- [ ] Query 6 (Network Connections): No unexpected LDAP/RMI connections
- [ ] Query 7 (Application Startup): Successful startup confirmed
- [ ] Alerts: All recommended alerts configured and tested
- [ ] Documentation: All findings documented in remediation report

---

## Troubleshooting

### Issue: No logs appearing for cpu-app

**Possible Causes:**
1. Logging not properly configured in Dynatrace
2. Process group filter too restrictive
3. Application not logging to stdout/stderr

**Resolution:**
1. Verify OneAgent is installed and running on the Azure Web App
2. Check that log monitoring is enabled in Dynatrace settings
3. Widen the filter to include the entire resource group:
   ```dql
   fetch logs, from: now()-2h
   | filter contains(dt.entity.azure_web_app, "cpu-app")
   | sort timestamp desc
   | limit 50
   ```

### Issue: Process Group not found

**Possible Causes:**
1. Application not yet deployed
2. Dynatrace not monitoring the Azure Web App
3. Process group name different than expected

**Resolution:**
1. Navigate to **Infrastructure > Processes and containers**
2. Remove all filters
3. Search for the Azure subscription ID or resource group name
4. Locate the correct process group manually

### Issue: Log4j version not detected in Dynatrace

**Possible Causes:**
1. Dynatrace hasn't scanned the process yet (can take 5-15 minutes)
2. OneAgent version too old to detect Log4j
3. Application not fully started

**Resolution:**
1. Wait 15 minutes after deployment and re-run the query
2. Update OneAgent to the latest version
3. Restart the process and wait for full startup
4. Check **Technologies** page manually for the process group

---

## Advanced Analysis

### Deep Dive: Full Request Analysis

For a comprehensive security audit:

```dql
fetch dt.entity.service
| filter contains(entity.name, "cpu-app")
| expand requests[from: now()-7d]
| filter requests.statusCode >= 400
| fieldsAdd 
    url = requests.url,
    headers = requests.headers,
    params = requests.queryParameters,
    userAgent = requests.userAgent,
    sourceIp = requests.sourceIp,
    statusCode = requests.statusCode
| filter contains(headers, "$") or contains(params, "$") or contains(userAgent, "$")
| sort requests.timestamp desc
| limit 100
```

This query searches the last 7 days for failed requests with suspicious characters.

---

## Compliance and Reporting

### Monthly Security Report

Run all queries above and compile results into a monthly security report:

1. **Date Range:** Last 30 days
2. **Metrics to Include:**
   - Total exploitation attempts detected (should be 0)
   - Log4j version stability (should remain 2.20.0+)
   - Error rate for Log4j-related issues
   - Application uptime and restart frequency
3. **Attachments:**
   - Query result screenshots
   - SBOM from evidence folder
   - Any incident reports (if applicable)

### Export Query Results

To export query results for compliance:

1. Run the query in Dynatrace
2. Click the **Export** button (top-right)
3. Choose format: CSV, JSON, or Excel
4. Save to secure location
5. Include in compliance documentation

---

## References

- **Dynatrace DQL Documentation:** https://docs.dynatrace.com/docs/platform/grail/dynatrace-query-language
- **Log Monitoring:** https://docs.dynatrace.com/docs/observe-and-explore/logs
- **Process Monitoring:** https://docs.dynatrace.com/docs/platform-modules/infrastructure-monitoring/hosts/monitoring
- **Alerting:** https://docs.dynatrace.com/docs/observe-and-explore/notifications-and-alerting

---

**Document Version:** 1.0  
**Last Updated:** 2025-10-22  
**Owner:** SRE Team  
**Related:** LOG4J_REMEDIATION_VALIDATION.md
