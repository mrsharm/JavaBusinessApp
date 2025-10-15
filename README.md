# Java Application with Log4j

A simple Java application demonstrating Log4j 2 logging implementation.

## Project Structure

```
JavaApp/
├── pom.xml                           # Maven configuration
├── src/
│   └── main/
│       ├── java/
│       │   └── com/example/javaapp/
│       │       └── App.java          # Main application
│       └── resources/
│           └── log4j2.xml            # Log4j configuration
└── README.md
```

## Features

- Simple Java application with business logic
- Log4j 2 integration with multiple log levels (TRACE, DEBUG, INFO, WARN, ERROR)
- Multiple appenders:
  - Console output
  - File logging
  - Rolling file logging with date/size-based rotation
- Structured logging with timestamps and thread information

## Prerequisites

- Java 11 or higher
- Maven 3.6 or higher

## Building the Application

```bash
mvn clean compile
```

## Running the Application

### Option 1: Using Maven
```bash
mvn exec:java
```

### Option 2: Using Maven Package and Java
```bash
mvn clean package
java -jar target/javaapp-1.0-SNAPSHOT.jar
```

### Option 3: Direct execution with classpath
```bash
mvn clean compile
mvn exec:java -Dexec.mainClass="com.example.javaapp.App"
```

## Log Output

The application generates logs in multiple locations:

1. **Console**: Real-time output to the terminal
2. **logs/application.log**: Persistent log file
3. **logs/app-rolling.log**: Rolling log file (rotates by date/size)

## Log Levels

The application demonstrates different log levels:
- **TRACE**: Most detailed information
- **DEBUG**: Debugging information
- **INFO**: General informational messages
- **WARN**: Warning messages
- **ERROR**: Error messages

## Customizing Logging

Edit `src/main/resources/log4j2.xml` to customize:
- Log levels
- Output patterns
- File locations
- Rolling policies

## Example Output

```
2025-10-15 10:30:45.123 [main] INFO  com.example.javaapp.App - Application started
2025-10-15 10:30:45.125 [main] DEBUG com.example.javaapp.App - Initializing application components...
2025-10-15 10:30:45.127 [main] DEBUG com.example.javaapp.App - Processing business logic with framework: Java and library: Log4j
2025-10-15 10:30:45.128 [main] INFO  com.example.javaapp.App - Business logic completed: Successfully integrated Java with Log4j!
2025-10-15 10:30:45.129 [main] DEBUG com.example.javaapp.App - Calculating sum of 10 and 5
2025-10-15 10:30:45.130 [main] INFO  com.example.javaapp.App - Calculation result: 15
2025-10-15 10:30:45.131 [main] WARN  com.example.javaapp.App - This is a warning message - just for demonstration
2025-10-15 10:30:45.132 [main] DEBUG com.example.javaapp.App - Result is positive, everything looks good!
2025-10-15 10:30:45.133 [main] INFO  com.example.javaapp.App - Application completed successfully
```
