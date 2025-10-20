FROM openjdk:17-jdk-slim

WORKDIR /app

COPY target/menu-service-0.0.1-SNAPSHOT.jar /app/menu-service.jar

EXPOSE 8082

ENTRYPOINT ["java", "-jar", "menu-service.jar"]
