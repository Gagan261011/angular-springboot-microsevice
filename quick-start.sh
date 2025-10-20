#!/bin/bash

# Quick Start Script - Food Ordering Application
# This script provides a simple way to deploy and test the application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "=========================================="
echo "  Food Ordering App - Quick Start"
echo "=========================================="
echo -e "${NC}"
echo ""

# Function to show menu
show_menu() {
    echo "Please select an option:"
    echo ""
    echo "  1. Pre-deployment check (verify environment)"
    echo "  2. Deploy application (docker compose up)"
    echo "  3. Run sanity tests"
    echo "  4. Run API tests"
    echo "  5. Run all tests (sanity + API)"
    echo "  6. Health check dashboard"
    echo "  7. Continuous health monitoring"
    echo "  8. View application logs"
    echo "  9. Stop application"
    echo " 10. Clean up (remove all containers and images)"
    echo "  0. Exit"
    echo ""
    echo -n "Enter your choice [0-10]: "
}

# Function to wait for user
wait_for_user() {
    echo ""
    echo -n "Press Enter to continue..."
    read
}

# Function to deploy application
deploy_app() {
    echo -e "${BLUE}Deploying application...${NC}"
    echo ""

    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        echo "Please install Docker first. See DEPLOYMENT_GUIDE.md for instructions."
        return 1
    fi

    # Check if already running
    if docker compose ps | grep -q "Up"; then
        echo -e "${YELLOW}Application is already running${NC}"
        echo -n "Do you want to restart? (y/N): "
        read restart
        if [ "$restart" != "y" ] && [ "$restart" != "Y" ]; then
            return 0
        fi
        docker compose down
    fi

    echo "Building and starting all services..."
    docker compose up -d --build

    echo ""
    echo -e "${GREEN}✓ Application deployment started${NC}"
    echo ""
    echo "Services are initializing. This may take 2-3 minutes."
    echo ""
    echo -e "${CYAN}Service URLs:${NC}"
    echo "  - Frontend:       http://localhost:4200"
    echo "  - API Gateway:    http://localhost:8080"
    echo "  - Eureka:         http://localhost:8761"
    echo ""
    echo "Waiting 90 seconds for services to initialize..."

    # Show progress
    for i in {1..90}; do
        echo -n "."
        sleep 1
        if [ $((i % 30)) -eq 0 ]; then
            echo " ${i}s"
        fi
    done
    echo ""

    echo -e "${GREEN}✓ Services should be ready now${NC}"
    echo ""
    echo "You can now run tests (option 3, 4, or 5) to verify the deployment."
}

# Function to run pre-deployment check
pre_deployment_check() {
    echo -e "${BLUE}Running pre-deployment check...${NC}"
    echo ""

    if [ ! -f "./pre-deployment-check.sh" ]; then
        echo -e "${RED}Error: pre-deployment-check.sh not found${NC}"
        return 1
    fi

    chmod +x pre-deployment-check.sh
    ./pre-deployment-check.sh

    return $?
}

# Function to run sanity tests
run_sanity_tests() {
    echo -e "${BLUE}Running sanity tests...${NC}"
    echo ""

    if [ ! -f "./sanity-test.sh" ]; then
        echo -e "${RED}Error: sanity-test.sh not found${NC}"
        return 1
    fi

    chmod +x sanity-test.sh
    ./sanity-test.sh

    return $?
}

# Function to run API tests
run_api_tests() {
    echo -e "${BLUE}Running API tests...${NC}"
    echo ""

    if [ ! -f "./api-test.sh" ]; then
        echo -e "${RED}Error: api-test.sh not found${NC}"
        return 1
    fi

    chmod +x api-test.sh
    ./api-test.sh

    return $?
}

# Function to show health dashboard
show_health_dashboard() {
    echo -e "${BLUE}Showing health dashboard...${NC}"
    echo ""

    if [ ! -f "./health-check.sh" ]; then
        echo -e "${RED}Error: health-check.sh not found${NC}"
        return 1
    fi

    chmod +x health-check.sh
    ./health-check.sh dashboard
}

# Function to continuous monitoring
continuous_monitoring() {
    echo -e "${BLUE}Starting continuous monitoring...${NC}"
    echo ""
    echo "Press Ctrl+C to stop monitoring"
    echo ""
    sleep 2

    if [ ! -f "./health-check.sh" ]; then
        echo -e "${RED}Error: health-check.sh not found${NC}"
        return 1
    fi

    chmod +x health-check.sh
    ./health-check.sh continuous
}

# Function to view logs
view_logs() {
    echo -e "${BLUE}Select service to view logs:${NC}"
    echo ""
    echo "  1. All services"
    echo "  2. Eureka Server"
    echo "  3. Config Server"
    echo "  4. API Gateway"
    echo "  5. User Service"
    echo "  6. Menu Service"
    echo "  7. Order Service"
    echo "  8. Frontend"
    echo "  0. Back to main menu"
    echo ""
    echo -n "Enter your choice [0-8]: "
    read log_choice

    case $log_choice in
        1) docker compose logs -f ;;
        2) docker compose logs -f eureka-server ;;
        3) docker compose logs -f config-server ;;
        4) docker compose logs -f api-gateway ;;
        5) docker compose logs -f user-service ;;
        6) docker compose logs -f menu-service ;;
        7) docker compose logs -f order-service ;;
        8) docker compose logs -f frontend ;;
        0) return ;;
        *) echo -e "${RED}Invalid choice${NC}" ;;
    esac
}

# Function to stop application
stop_app() {
    echo -e "${BLUE}Stopping application...${NC}"
    echo ""

    if ! docker compose ps | grep -q "Up"; then
        echo -e "${YELLOW}Application is not running${NC}"
        return 0
    fi

    docker compose stop

    echo ""
    echo -e "${GREEN}✓ Application stopped${NC}"
}

# Function to clean up
cleanup() {
    echo -e "${YELLOW}WARNING: This will remove all containers, volumes, and images${NC}"
    echo -n "Are you sure? (y/N): "
    read confirm

    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Cleanup cancelled"
        return 0
    fi

    echo -e "${BLUE}Cleaning up...${NC}"
    echo ""

    docker compose down -v --rmi all

    echo ""
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

# Main loop
while true; do
    show_menu
    read choice

    echo ""

    case $choice in
        1)
            pre_deployment_check
            wait_for_user
            ;;
        2)
            deploy_app
            wait_for_user
            ;;
        3)
            run_sanity_tests
            wait_for_user
            ;;
        4)
            run_api_tests
            wait_for_user
            ;;
        5)
            run_sanity_tests
            if [ $? -eq 0 ]; then
                echo ""
                echo "Sanity tests passed, now running API tests..."
                echo ""
                sleep 2
                run_api_tests
            fi
            wait_for_user
            ;;
        6)
            show_health_dashboard
            wait_for_user
            ;;
        7)
            continuous_monitoring
            ;;
        8)
            view_logs
            ;;
        9)
            stop_app
            wait_for_user
            ;;
        10)
            cleanup
            wait_for_user
            ;;
        0)
            echo -e "${GREEN}Thank you for using Food Ordering App!${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please select 0-10.${NC}"
            wait_for_user
            ;;
    esac

    clear
done
