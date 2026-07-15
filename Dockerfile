# Stage 1: Build the JAR package
FROM maven:3.8.8-eclipse-temurin-8 AS builder

WORKDIR /usr/src/app

# Copy pom.xml and resolve dependencies to cache layers
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy application source code
COPY src ./src

# Compile and package the application
RUN mvn clean package -DskipTests

# Stage 2: Minimal Runtime JRE
FROM eclipse-temurin:8-jre

ENV NODE_ENV=production
WORKDIR /usr/src/app

# Copy the built jar from stage 1
COPY --from=builder /usr/src/app/target/*.jar app.jar

# Create a non-root group and user for security hardening
RUN /usr/sbin/groupadd -r spring && /usr/sbin/useradd -r -g spring spring
USER spring:spring

# Expose default application port
EXPOSE 9191

# Set default env variables
ENV PORT=9191
ENV APP_VERSION=1.0

# Health check hitting the endpoint via wget (Alpine/Slim standard)
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:${PORT}/health | grep -q "UP" || exit 1

# Start the JRE runner
ENTRYPOINT ["java", "-jar", "app.jar"]
