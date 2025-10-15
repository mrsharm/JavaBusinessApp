package com.example.javaapp;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

/**
 * Simple Java Application with Log4j logging
 */
public class App {
    private static final Logger logger = LogManager.getLogger(App.class);

    public static void main(String[] args) {
        logger.info("Application started");
        
        try {
            logger.debug("Initializing application components...");
            
            // Simulate some business logic
            String message = performBusinessLogic("Java", "Log4j");
            logger.info("Business logic completed: {}", message);
            
            // Simulate some calculations
            int result = calculate(10, 5);
            logger.info("Calculation result: {}", result);
            
            logger.warn("This is a warning message - just for demonstration");
            
            // Simulate conditional error logging
            if (result > 0) {
                logger.debug("Result is positive, everything looks good!");
            }
            
            logger.info("Application completed successfully");
            
        } catch (Exception e) {
            logger.error("An error occurred during application execution", e);
            System.exit(1);
        }
    }

    /**
     * Performs some business logic
     * @param framework The framework name
     * @param library The library name
     * @return A formatted message
     */
    private static String performBusinessLogic(String framework, String library) {
        logger.debug("Processing business logic with framework: {} and library: {}", framework, library);
        
        String result = String.format("Successfully integrated %s with %s!", framework, library);
        logger.trace("Generated result message: {}", result);
        
        return result;
    }

    /**
     * Performs a simple calculation
     * @param a First number
     * @param b Second number
     * @return The sum
     */
    private static int calculate(int a, int b) {
        logger.debug("Calculating sum of {} and {}", a, b);
        int sum = a + b;
        logger.trace("Sum calculated: {}", sum);
        return sum;
    }
}
