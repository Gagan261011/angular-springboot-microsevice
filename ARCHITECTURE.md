# Architecture

This document provides a detailed overview of the architecture of the Food Ordering App.

## Microservices

The application is composed of the following microservices:

*   **Eureka Server:** A service discovery server that allows the microservices to find each other. All the other microservices register with the Eureka server on startup.
*   **Config Server:** A centralized configuration server that provides configuration to all the microservices. The microservices fetch their configuration from the config server on startup.
*   **API Gateway:** A single entry point for all frontend requests. The API gateway routes requests to the appropriate microservice. It also provides a layer of security and can be used for things like rate limiting and authentication.
*   **User Service:** A microservice that handles user-related operations. It has its own in-memory H2 database to store user data.
*   **Menu Service:** A microservice that handles the food menu. It has its own in-memory H2 database to store menu data.
*   **Order Service:** A microservice that handles food orders. It has its own in-memory H2 database to store order data. It communicates with the menu service to get the price of the menu items.
*   **Frontend:** An Angular application that provides the user interface. It communicates with the backend through the API gateway.

## Data Flow

1.  The user interacts with the frontend application in their browser.
2.  The frontend application sends requests to the API gateway.
3.  The API gateway routes the requests to the appropriate microservice.
4.  The microservices communicate with each other as needed. For example, the order service communicates with the menu service to get the price of the menu items.
5.  The microservices store their data in their own in-memory H2 databases.

## Netflix OSS Components

The application uses the following Netflix OSS components, via Spring Cloud Netflix:

*   **Eureka Server:** For service discovery.
*   **Spring Cloud Gateway:** As an API gateway.
*   **Spring Cloud Config:** For centralized configuration.
*   **Feign:** As a declarative REST client for inter-service communication.
*   **Resilience4j:** As a circuit breaker to prevent cascading failures. (This has not been implemented yet, but it is a planned feature).
