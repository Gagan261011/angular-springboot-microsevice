#!/bin/bash

# Sanity Test Script for Food Ordering Microservices Application
# This script performs comprehensive sanity checks on all services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results
PASSED=0
FAILED=0
WARNINGS=0

# Configuration
EUREKA_URL="${EUREKA_URL:-http://localhost:8761}"
CONFIG_URL="${CONFIG_URL:-http://localhost:8888}"
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8080}"
USER_SERVICE_URL="${USER_SERVICE_URL:-http://localhost:8081}"
MENU_SERVICE_URL="${MENU_SERVICE_URL:-http://localhost:8082}"
ORDER_SERVICE_URL="${ORDER_SERVICE_URL:-http://localhost:8083}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:4200}"

# Maximum wait time for services (in seconds)
MAX_WAIT_TIME=120
CHECK_INTERVAL=5

echo "=========================================="
echo "   Food Ordering App - Sanity Tests"
echo "=========================================="
echo ""

# Function to check if a service is responding
check_service() {
    local name=$1
    local url=$2
    local expected_status=${3:-200}

    echo -n "Checking $name at $url... "

    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")

    if [ "$response" = "$expected_status" ] || [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ PASSED${NC} (HTTP $response)"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC} (HTTP $response, expected $expected_status)"
        ((FAILED++))
        return 1
    fi
}

# Function to wait for a service to be ready
wait_for_service() {
    local name=$1
    local url=$2
    local elapsed=0

    echo -n "Waiting for $name to be ready... "

    while [ $elapsed -lt $MAX_WAIT_TIME ]; do
        if curl -s --max-time 5 "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}Ready${NC} (took ${elapsed}s)"
            return 0
        fi
        sleep $CHECK_INTERVAL
        elapsed=$((elapsed + CHECK_INTERVAL))
    done

    echo -e "${RED}Timeout${NC} (waited ${MAX_WAIT_TIME}s)"
    ((WARNINGS++))
    return 1
}

# Function to check Eureka service registration
check_eureka_registrations() {
    echo ""
    echo "Checking Eureka Service Registrations..."
    echo "----------------------------------------"

    local eureka_response=$(curl -s "$EUREKA_URL/eureka/apps" -H "Accept: application/json" 2>/dev/null || echo "{}")

    # Expected services
    local services=("API-GATEWAY" "USER-SERVICE" "MENU-SERVICE" "ORDER-SERVICE" "CONFIG-SERVER")

    for service in "${services[@]}"; do
        echo -n "  - $service: "
        if echo "$eureka_response" | grep -q "\"app\":\"$service\""; then
            echo -e "${GREEN}Registered${NC}"
            ((PASSED++))
        else
            echo -e "${RED}Not Registered${NC}"
            ((FAILED++))
        fi
    done
}

# Function to check Docker containers
check_docker_containers() {
    echo ""
    echo "Checking Docker Containers..."
    echo "-----------------------------"

    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker not found - skipping container checks${NC}"
        ((WARNINGS++))
        return
    fi

    local containers=("eureka-server" "config-server" "api-gateway" "user-service" "menu-service" "order-service" "frontend")

    for container in "${containers[@]}"; do
        echo -n "  - $container: "
        local status=$(docker ps --filter "name=$container" --format "{{.Status}}" 2>/dev/null | head -1)

        if [ -n "$status" ]; then
            if echo "$status" | grep -q "Up"; then
                echo -e "${GREEN}Running${NC} ($status)"
                ((PASSED++))
            else
                echo -e "${RED}Not Running${NC} ($status)"
                ((FAILED++))
            fi
        else
            echo -e "${RED}Not Found${NC}"
            ((FAILED++))
        fi
    done
}

# Function to check service health endpoints
check_health_endpoints() {
    echo ""
    echo "Checking Service Health Endpoints..."
    echo "------------------------------------"

    local services=(
        "Eureka Server:$EUREKA_URL/actuator/health"
        "Config Server:$CONFIG_URL/actuator/health"
        "API Gateway:$GATEWAY_URL/actuator/health"
        "User Service:$USER_SERVICE_URL/actuator/health"
        "Menu Service:$MENU_SERVICE_URL/actuator/health"
        "Order Service:$ORDER_SERVICE_URL/actuator/health"
    )

    for service_info in "${services[@]}"; do
        IFS=':' read -r name url <<< "$service_info"
        echo -n "  - $name: "

        health_response=$(curl -s --max-time 5 "$url" 2>/dev/null || echo "{}")
        health_status=$(echo "$health_response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

        if [ "$health_status" = "UP" ]; then
            echo -e "${GREEN}UP${NC}"
            ((PASSED++))
        else
            echo -e "${RED}DOWN${NC} (status: $health_status)"
            ((FAILED++))
        fi
    done
}

# Function to check basic API connectivity
check_api_connectivity() {
    echo ""
    echo "Checking API Gateway Connectivity..."
    echo "------------------------------------"

    # Check if API Gateway is accessible
    check_service "API Gateway" "$GATEWAY_URL/actuator/health" 200

    # Check if services are accessible through gateway
    echo -n "  - Menu API through Gateway: "
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$GATEWAY_URL/api/menu" 2>/dev/null || echo "000")
    if [ "$response" = "200" ] || [ "$response" = "404" ]; then
        echo -e "${GREEN}Accessible${NC} (HTTP $response)"
        ((PASSED++))
    else
        echo -e "${RED}Not Accessible${NC} (HTTP $response)"
        ((FAILED++))
    fi
}

# Function to check frontend
check_frontend() {
    echo ""
    echo "Checking Frontend..."
    echo "--------------------"

    check_service "Frontend" "$FRONTEND_URL" 200

    # Check if frontend can reach gateway
    echo -n "  - Frontend assets: "
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$FRONTEND_URL/index.html" 2>/dev/null || echo "000")
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}Loaded${NC}"
        ((PASSED++))
    else
        echo -e "${RED}Not Loaded${NC} (HTTP $response)"
        ((FAILED++))
    fi
}

# Function to check database connectivity (if applicable)
check_databases() {
    echo ""
    echo "Checking Database Connectivity..."
    echo "---------------------------------"
    echo -e "${YELLOW}Note: This is a basic check. Services use in-memory databases by default.${NC}"

    # Check if services can access their data stores
    echo -n "  - User Service data access: "
    response=$(curl -s --max-time 10 "$GATEWAY_URL/api/users" 2>/dev/null || echo "")
    if [ -n "$response" ]; then
        echo -e "${GREEN}OK${NC}"
        ((PASSED++))
    else
        echo -e "${RED}Failed${NC}"
        ((FAILED++))
    fi

    echo -n "  - Menu Service data access: "
    response=$(curl -s --max-time 10 "$GATEWAY_URL/api/menu" 2>/dev/null || echo "")
    if [ -n "$response" ]; then
        echo -e "${GREEN}OK${NC}"
        ((PASSED++))
    else
        echo -e "${RED}Failed${NC}"
        ((FAILED++))
    fi

    echo -n "  - Order Service data access: "
    response=$(curl -s --max-time 10 "$GATEWAY_URL/api/orders" 2>/dev/null || echo "")
    if [ -n "$response" ]; then
        echo -e "${GREEN}OK${NC}"
        ((PASSED++))
    else
        echo -e "${RED}Failed${NC}"
        ((FAILED++))
    fi
}

# Main execution
echo "Starting sanity tests..."
echo ""

# Phase 1: Wait for critical services
echo "Phase 1: Waiting for Core Services"
echo "==================================="
wait_for_service "Eureka Server" "$EUREKA_URL"
wait_for_service "Config Server" "$CONFIG_URL/actuator/health"
wait_for_service "API Gateway" "$GATEWAY_URL/actuator/health"

# Give services time to register with Eureka
echo ""
echo "Waiting 30 seconds for services to register with Eureka..."
sleep 30

# Phase 2: Check service status
echo ""
echo "Phase 2: Service Status Checks"
echo "==============================="
check_docker_containers
check_eureka_registrations
check_health_endpoints

# Phase 3: Check connectivity
echo ""
echo "Phase 3: Connectivity Checks"
echo "============================"
check_api_connectivity
check_frontend

# Phase 4: Check data access
echo ""
echo "Phase 4: Data Access Checks"
echo "==========================="
check_databases

# Final report
echo ""
echo "=========================================="
echo "           Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed:${NC}   $PASSED"
echo -e "${RED}Failed:${NC}   $FAILED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All sanity tests passed!${NC}"
    echo "The application is ready for deployment."
    exit 0
else
    echo -e "${RED}✗ Some sanity tests failed!${NC}"
    echo "Please review the failures above before deploying."
    exit 1
fi
