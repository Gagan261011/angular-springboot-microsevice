#!/bin/bash

# Health Check Script for Food Ordering Microservices Application
# This script continuously monitors the health of all services

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EUREKA_URL="${EUREKA_URL:-http://localhost:8761}"
CONFIG_URL="${CONFIG_URL:-http://localhost:8888}"
GATEWAY_URL="${GATEWAY_URL:-http://localhost:8080}"
USER_SERVICE_URL="${USER_SERVICE_URL:-http://localhost:8081}"
MENU_SERVICE_URL="${MENU_SERVICE_URL:-http://localhost:8082}"
ORDER_SERVICE_URL="${ORDER_SERVICE_URL:-http://localhost:8083}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:4200}"

# Check interval in seconds
CHECK_INTERVAL="${CHECK_INTERVAL:-30}"

# Monitoring mode
CONTINUOUS="${CONTINUOUS:-false}"

# Function to check service health
check_health() {
    local name=$1
    local url=$2

    local response=$(curl -s --max-time 5 "$url" 2>/dev/null || echo '{"status":"DOWN"}')
    local status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

    if [ "$status" = "UP" ]; then
        echo -e "${GREEN}UP${NC}"
        return 0
    else
        echo -e "${RED}DOWN${NC}"
        return 1
    fi
}

# Function to get service metrics
get_metrics() {
    local name=$1
    local url=$2

    local metrics=$(curl -s --max-time 5 "$url" 2>/dev/null || echo '{}')
    echo "$metrics"
}

# Function to check Eureka registrations
check_eureka() {
    local eureka_response=$(curl -s --max-time 5 "$EUREKA_URL/eureka/apps" -H "Accept: application/json" 2>/dev/null || echo '{}')
    echo "$eureka_response"
}

# Function to display health dashboard
display_dashboard() {
    clear
    echo "=========================================="
    echo "  Food Ordering App - Health Dashboard"
    echo "=========================================="
    echo "  Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "=========================================="
    echo ""

    # Check core infrastructure services
    echo "Core Infrastructure:"
    echo "--------------------"
    echo -n "  Eureka Server:     "
    check_health "Eureka" "$EUREKA_URL/actuator/health"

    echo -n "  Config Server:     "
    check_health "Config" "$CONFIG_URL/actuator/health"

    echo -n "  API Gateway:       "
    check_health "Gateway" "$GATEWAY_URL/actuator/health"
    echo ""

    # Check business services
    echo "Business Services:"
    echo "------------------"
    echo -n "  User Service:      "
    check_health "User" "$USER_SERVICE_URL/actuator/health"

    echo -n "  Menu Service:      "
    check_health "Menu" "$MENU_SERVICE_URL/actuator/health"

    echo -n "  Order Service:     "
    check_health "Order" "$ORDER_SERVICE_URL/actuator/health"
    echo ""

    # Check frontend
    echo "Frontend:"
    echo "---------"
    echo -n "  Angular App:       "
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$FRONTEND_URL" 2>/dev/null || echo "000")
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}UP${NC}"
    else
        echo -e "${RED}DOWN${NC}"
    fi
    echo ""

    # Check Eureka registrations
    echo "Eureka Registrations:"
    echo "---------------------"
    eureka_data=$(check_eureka)

    services=("API-GATEWAY" "USER-SERVICE" "MENU-SERVICE" "ORDER-SERVICE" "CONFIG-SERVER")
    for service in "${services[@]}"; do
        echo -n "  $service: "
        if echo "$eureka_data" | grep -q "\"app\":\"$service\""; then
            # Get instance count
            count=$(echo "$eureka_data" | grep -o "\"app\":\"$service\"" | wc -l)
            echo -e "${GREEN}Registered${NC} (${count} instance(s))"
        else
            echo -e "${RED}Not Registered${NC}"
        fi
    done
    echo ""

    # Check Docker containers if Docker is available
    if command -v docker &> /dev/null; then
        echo "Docker Containers:"
        echo "------------------"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "eureka|config|gateway|user-service|menu-service|order-service|frontend" || echo "  No containers found"
        echo ""
    fi

    # Get memory and CPU metrics from actuator
    echo "Service Metrics:"
    echo "----------------"
    for service in "Gateway:$GATEWAY_URL" "User:$USER_SERVICE_URL" "Menu:$MENU_SERVICE_URL" "Order:$ORDER_SERVICE_URL"; do
        IFS=':' read -r name url <<< "$service"
        echo -n "  $name Service: "

        metrics=$(curl -s --max-time 5 "$url/actuator/metrics/jvm.memory.used" 2>/dev/null || echo '{}')
        memory_used=$(echo "$metrics" | grep -o '"value":[0-9.]*' | cut -d':' -f2 | head -1)

        if [ -n "$memory_used" ] && [ "$memory_used" != "" ]; then
            memory_mb=$(echo "scale=2; $memory_used / 1048576" | bc 2>/dev/null || echo "N/A")
            echo "Memory: ${memory_mb}MB"
        else
            echo "Metrics unavailable"
        fi
    done
    echo ""

    # Show API response times
    echo "API Response Times:"
    echo "-------------------"
    for endpoint in "/api/users" "/api/menu" "/api/orders"; do
        echo -n "  GET $endpoint: "
        response_time=$(curl -o /dev/null -s -w "%{time_total}" --max-time 5 "$GATEWAY_URL$endpoint" 2>/dev/null || echo "N/A")
        if [ "$response_time" != "N/A" ]; then
            echo "${response_time}s"
        else
            echo "N/A"
        fi
    done
    echo ""

    echo "=========================================="
    if [ "$CONTINUOUS" = "true" ]; then
        echo "Refreshing in ${CHECK_INTERVAL}s... (Press Ctrl+C to stop)"
    fi
    echo ""
}

# Function to perform a quick health check
quick_check() {
    local all_healthy=true

    services=(
        "Eureka:$EUREKA_URL/actuator/health"
        "Config:$CONFIG_URL/actuator/health"
        "Gateway:$GATEWAY_URL/actuator/health"
        "User:$USER_SERVICE_URL/actuator/health"
        "Menu:$MENU_SERVICE_URL/actuator/health"
        "Order:$ORDER_SERVICE_URL/actuator/health"
    )

    for service_info in "${services[@]}"; do
        IFS=':' read -r name url <<< "$service_info"
        response=$(curl -s --max-time 5 "$url" 2>/dev/null || echo '{"status":"DOWN"}')
        status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

        if [ "$status" != "UP" ]; then
            all_healthy=false
            echo -e "${RED}✗${NC} $name Service is DOWN"
        fi
    done

    if $all_healthy; then
        echo -e "${GREEN}✓${NC} All services are healthy"
        return 0
    else
        return 1
    fi
}

# Function to send alert (can be extended to send email, Slack, etc.)
send_alert() {
    local service=$1
    local status=$2

    echo "[ALERT] $(date): $service is $status" >> health-alerts.log
    # Add your alert mechanism here (email, Slack, PagerDuty, etc.)
}

# Function to monitor and alert
monitor_and_alert() {
    local prev_status=()

    services=(
        "Eureka:$EUREKA_URL/actuator/health"
        "Config:$CONFIG_URL/actuator/health"
        "Gateway:$GATEWAY_URL/actuator/health"
        "User:$USER_SERVICE_URL/actuator/health"
        "Menu:$MENU_SERVICE_URL/actuator/health"
        "Order:$ORDER_SERVICE_URL/actuator/health"
    )

    while true; do
        for i in "${!services[@]}"; do
            service_info="${services[$i]}"
            IFS=':' read -r name url <<< "$service_info"

            response=$(curl -s --max-time 5 "$url" 2>/dev/null || echo '{"status":"DOWN"}')
            status=$(echo "$response" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)

            # Check if status changed
            if [ "${prev_status[$i]}" != "" ] && [ "${prev_status[$i]}" != "$status" ]; then
                if [ "$status" != "UP" ]; then
                    send_alert "$name" "DOWN"
                    echo -e "$(date) - ${RED}ALERT${NC}: $name service changed from ${prev_status[$i]} to $status"
                else
                    send_alert "$name" "RECOVERED"
                    echo -e "$(date) - ${GREEN}RECOVERED${NC}: $name service is back UP"
                fi
            fi

            prev_status[$i]="$status"
        done

        display_dashboard
        sleep $CHECK_INTERVAL
    done
}

# Main execution
case "${1:-dashboard}" in
    dashboard)
        display_dashboard
        ;;
    continuous)
        CONTINUOUS=true
        while true; do
            display_dashboard
            sleep $CHECK_INTERVAL
        done
        ;;
    monitor)
        echo "Starting monitoring mode with alerting..."
        monitor_and_alert
        ;;
    quick)
        quick_check
        exit $?
        ;;
    *)
        echo "Usage: $0 {dashboard|continuous|monitor|quick}"
        echo ""
        echo "  dashboard   - Show health dashboard once"
        echo "  continuous  - Continuously refresh health dashboard"
        echo "  monitor     - Monitor services and alert on status changes"
        echo "  quick       - Quick health check (returns 0 if all healthy)"
        echo ""
        echo "Environment variables:"
        echo "  EUREKA_URL, CONFIG_URL, GATEWAY_URL, etc. - Service URLs"
        echo "  CHECK_INTERVAL - Refresh interval in seconds (default: 30)"
        exit 1
        ;;
esac
