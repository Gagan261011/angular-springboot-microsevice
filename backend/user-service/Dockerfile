# Stage 1: Build the application
FROM maven:3.8.5-openjdk-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

# Stage 2: Create the final image
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=builder /app/target/user-service-0.0.1-SNAPSHOT.jar /app/user-service.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "user-service.jar"]
