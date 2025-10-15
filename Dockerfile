# Multi-stage build for Java application
FROM maven:3.9.5-eclipse-temurin-17 AS build

# Set working directory
WORKDIR /app

# Copy pom.xml and download dependencies (cached layer)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

# Add metadata
LABEL maintainer="mrsharm"
LABEL description="Java Application with Log4j - Kubernetes Ready"
LABEL version="1.0"

# Create app directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy JAR from build stage
COPY --from=build /app/target/javaapp-1.0-SNAPSHOT.jar /app/app.jar

# Copy log4j configuration
COPY --from=build /app/target/classes/log4j2.xml /app/log4j2.xml

# Create logs directory and set permissions
RUN mkdir -p /app/logs && chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose port (if needed for future web features)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD pgrep -f java || exit 1

# Run the application
ENTRYPOINT ["java", "-Dlog4j.configurationFile=/app/log4j2.xml", "-jar", "/app/app.jar"]
