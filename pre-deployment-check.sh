#!/bin/bash

# Pre-Deployment Validation Script for Food Ordering Application
# This script performs comprehensive checks before deployment to Azure VM

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test results
CRITICAL_FAILURES=0
WARNINGS=0
PASSED_CHECKS=0
TOTAL_CHECKS=0

# Log file
LOG_FILE="pre-deployment-check-$(date +%Y%m%d-%H%M%S).log"

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log_result() {
    local status=$1
    local message=$2

    ((TOTAL_CHECKS++))

    if [ "$status" = "PASS" ]; then
        log "  ${GREEN}✓ PASS${NC}: $message"
        ((PASSED_CHECKS++))
    elif [ "$status" = "FAIL" ]; then
        log "  ${RED}✗ FAIL${NC}: $message"
        ((CRITICAL_FAILURES++))
    elif [ "$status" = "WARN" ]; then
        log "  ${YELLOW}! WARN${NC}: $message"
        ((WARNINGS++))
    fi
}

echo ""
log "=========================================="
log "  Pre-Deployment Validation"
log "  Food Ordering Microservices App"
log "=========================================="
log "Date: $(date)"
log ""

# ==========================================
# Phase 1: Environment Checks
# ==========================================
log "${CYAN}Phase 1: Environment Checks${NC}"
log "=============================="

# Check Docker
log_result() {
    echo -n "Docker installation: "
    if command -v docker &> /dev/null; then
        docker_version=$(docker --version)
        log_result "PASS" "Docker is installed ($docker_version)"
    else
        log_result "FAIL" "Docker is not installed"
    fi
}
log_result

# Check Docker Compose
echo -n "Docker Compose installation: "
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    compose_version=$(docker-compose --version 2>/dev/null || docker compose version 2>/dev/null)
    log_result "PASS" "Docker Compose is installed ($compose_version)"
else
    log_result "FAIL" "Docker Compose is not installed"
fi

# Check required ports
echo "Checking required ports availability:"
REQUIRED_PORTS=(4200 8080 8081 8082 8083 8761 8888)

for port in "${REQUIRED_PORTS[@]}"; do
    if command -v netstat &> /dev/null; then
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            log_result "WARN" "Port $port is already in use"
        else
            log_result "PASS" "Port $port is available"
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln 2>/dev/null | grep -q ":$port "; then
            log_result "WARN" "Port $port is already in use"
        else
            log_result "PASS" "Port $port is available"
        fi
    else
        log_result "WARN" "Cannot check port $port (netstat/ss not available)"
    fi
done

# Check disk space
echo "Checking disk space:"
if command -v df &> /dev/null; then
    available_space=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$available_space" -gt 10 ]; then
        log_result "PASS" "Sufficient disk space available (${available_space}GB)"
    elif [ "$available_space" -gt 5 ]; then
        log_result "WARN" "Low disk space (${available_space}GB available, recommend 10GB+)"
    else
        log_result "FAIL" "Insufficient disk space (${available_space}GB available, need at least 5GB)"
    fi
else
    log_result "WARN" "Cannot check disk space (df not available)"
fi

# Check memory
echo "Checking memory:"
if command -v free &> /dev/null; then
    total_mem=$(free -g | grep Mem | awk '{print $2}')
    if [ "$total_mem" -gt 4 ]; then
        log_result "PASS" "Sufficient memory available (${total_mem}GB)"
    elif [ "$total_mem" -gt 2 ]; then
        log_result "WARN" "Low memory (${total_mem}GB available, recommend 4GB+)"
    else
        log_result "FAIL" "Insufficient memory (${total_mem}GB available, need at least 2GB)"
    fi
else
    log_result "WARN" "Cannot check memory (free not available)"
fi

log ""

# ==========================================
# Phase 2: File System Checks
# ==========================================
log "${CYAN}Phase 2: File System Checks${NC}"
log "============================"

# Check if docker-compose.yml exists
echo -n "docker-compose.yml: "
if [ -f "docker-compose.yml" ]; then
    log_result "PASS" "docker-compose.yml found"

    # Validate docker-compose.yml
    if command -v docker-compose &> /dev/null; then
        if docker-compose config > /dev/null 2>&1; then
            log_result "PASS" "docker-compose.yml is valid"
        else
            log_result "FAIL" "docker-compose.yml has syntax errors"
        fi
    fi
else
    log_result "FAIL" "docker-compose.yml not found"
fi

# Check if Dockerfiles exist
echo "Checking Dockerfiles:"
DOCKERFILES=(
    "backend/eureka-server/Dockerfile"
    "backend/config-server/Dockerfile"
    "backend/api-gateway/Dockerfile"
    "backend/user-service/Dockerfile"
    "backend/menu-service/Dockerfile"
    "backend/order-service/Dockerfile"
    "frontend/food-ordering-app/Dockerfile"
)

for dockerfile in "${DOCKERFILES[@]}"; do
    if [ -f "$dockerfile" ]; then
        log_result "PASS" "$dockerfile exists"
    else
        log_result "FAIL" "$dockerfile not found"
    fi
done

# Check if pom.xml files exist
echo "Checking Maven projects:"
POM_FILES=(
    "backend/eureka-server/pom.xml"
    "backend/config-server/pom.xml"
    "backend/api-gateway/pom.xml"
    "backend/user-service/pom.xml"
    "backend/menu-service/pom.xml"
    "backend/order-service/pom.xml"
)

for pom in "${POM_FILES[@]}"; do
    if [ -f "$pom" ]; then
        log_result "PASS" "$pom exists"
    else
        log_result "FAIL" "$pom not found"
    fi
done

# Check if frontend package.json exists
echo -n "Frontend package.json: "
if [ -f "frontend/food-ordering-app/package.json" ]; then
    log_result "PASS" "package.json found"
else
    log_result "FAIL" "package.json not found"
fi

log ""

# ==========================================
# Phase 3: Docker Image Checks
# ==========================================
log "${CYAN}Phase 3: Docker Image Checks${NC}"
log "============================="

if command -v docker &> /dev/null; then
    echo "Attempting to build Docker images (this may take several minutes)..."

    # Try to build images
    if docker-compose build --no-cache > "$LOG_FILE.build" 2>&1; then
        log_result "PASS" "All Docker images built successfully"

        # Check image sizes
        echo "Docker image sizes:"
        images=$(docker images --format "{{.Repository}}:{{.Tag}} {{.Size}}" | grep -E "eureka-server|config-server|api-gateway|user-service|menu-service|order-service|frontend")
        if [ -n "$images" ]; then
            while IFS= read -r line; do
                log "    $line"
            done <<< "$images"
        fi
    else
        log_result "FAIL" "Failed to build Docker images (see $LOG_FILE.build for details)"
        tail -20 "$LOG_FILE.build" >> "$LOG_FILE"
    fi
else
    log_result "WARN" "Docker not available - skipping image build checks"
fi

log ""

# ==========================================
# Phase 4: Configuration Checks
# ==========================================
log "${CYAN}Phase 4: Configuration Checks${NC}"
log "=============================="

# Check application properties
echo "Checking configuration files:"

CONFIG_FILES=(
    "backend/eureka-server/src/main/resources/application.properties"
    "backend/config-server/src/main/resources/application.properties"
    "backend/api-gateway/src/main/resources/application.properties"
    "backend/user-service/src/main/resources/application.properties"
    "backend/menu-service/src/main/resources/application.properties"
    "backend/order-service/src/main/resources/application.properties"
)

for config in "${CONFIG_FILES[@]}"; do
    if [ -f "$config" ]; then
        log_result "PASS" "$config exists"

        # Check for sensitive data in config files
        if grep -qE "(password|secret|key)=.+" "$config" 2>/dev/null; then
            log_result "WARN" "$config contains hardcoded credentials - consider using environment variables"
        fi
    else
        # Check for yml alternative
        config_yml="${config%.properties}.yml"
        if [ -f "$config_yml" ]; then
            log_result "PASS" "$config_yml exists (using YAML format)"
        else
            log_result "FAIL" "Configuration file not found: $config"
        fi
    fi
done

# Check environment variables in docker-compose
echo "Checking environment configuration:"
if [ -f "docker-compose.yml" ]; then
    if grep -q "EUREKA_CLIENT_SERVICEURL_DEFAULTZONE" docker-compose.yml; then
        log_result "PASS" "Eureka configuration found in docker-compose.yml"
    else
        log_result "WARN" "Eureka configuration not found in docker-compose.yml"
    fi

    if grep -q "SPRING_PROFILES_ACTIVE" docker-compose.yml; then
        log_result "PASS" "Spring profiles configuration found"
    else
        log_result "WARN" "Spring profiles not configured in docker-compose.yml"
    fi
fi

log ""

# ==========================================
# Phase 5: Network Checks
# ==========================================
log "${CYAN}Phase 5: Network Checks${NC}"
log "========================"

# Check internet connectivity
echo -n "Internet connectivity: "
if curl -s --max-time 5 https://repo.maven.apache.org > /dev/null 2>&1; then
    log_result "PASS" "Internet connectivity available"
else
    log_result "WARN" "Limited or no internet connectivity (may affect Maven builds)"
fi

# Check if network is defined in docker-compose
if [ -f "docker-compose.yml" ]; then
    if grep -q "networks:" docker-compose.yml; then
        log_result "PASS" "Docker network configuration found"
    else
        log_result "WARN" "No custom network defined in docker-compose.yml"
    fi
fi

log ""

# ==========================================
# Phase 6: Security Checks
# ==========================================
log "${CYAN}Phase 6: Security Checks${NC}"
log "========================="

# Check for exposed sensitive files
echo "Checking for sensitive files:"
SENSITIVE_FILES=(".env" "secrets.yml" "credentials.json" "*.key" "*.pem")

for pattern in "${SENSITIVE_FILES[@]}"; do
    if find . -name "$pattern" -type f 2>/dev/null | grep -q .; then
        log_result "WARN" "Sensitive files found matching pattern: $pattern"
    fi
done

# Check .gitignore
echo -n ".gitignore configuration: "
if [ -f ".gitignore" ]; then
    if grep -qE "(\.env|secrets|credentials)" .gitignore; then
        log_result "PASS" ".gitignore properly configured for sensitive files"
    else
        log_result "WARN" ".gitignore may not exclude sensitive files"
    fi
else
    log_result "WARN" ".gitignore not found"
fi

log ""

# ==========================================
# Phase 7: Dependency Checks
# ==========================================
log "${CYAN}Phase 7: Dependency Checks${NC}"
log "==========================="

# Check Maven dependencies (if Maven is available)
if command -v mvn &> /dev/null && [ -f "backend/eureka-server/pom.xml" ]; then
    echo "Checking Maven dependencies (sample check on eureka-server):"
    if mvn -f backend/eureka-server/pom.xml dependency:resolve -q > /dev/null 2>&1; then
        log_result "PASS" "Maven dependencies can be resolved"
    else
        log_result "WARN" "Maven dependency resolution issues (may work in Docker)"
    fi
else
    log_result "WARN" "Maven not available - skipping dependency checks"
fi

# Check NPM dependencies (if npm is available)
if command -v npm &> /dev/null && [ -f "frontend/food-ordering-app/package.json" ]; then
    echo "Checking NPM dependencies:"
    if npm list --prefix frontend/food-ordering-app > /dev/null 2>&1; then
        log_result "PASS" "NPM dependencies are available"
    else
        log_result "WARN" "NPM dependencies not installed (will be installed during Docker build)"
    fi
else
    log_result "WARN" "NPM not available - skipping dependency checks"
fi

log ""

# ==========================================
# Final Report
# ==========================================
log ""
log "=========================================="
log "       Pre-Deployment Summary"
log "=========================================="
log ""
log "Total Checks: $TOTAL_CHECKS"
log "Passed:       $PASSED_CHECKS"
log "Warnings:     $WARNINGS"
log "Failures:     $CRITICAL_FAILURES"
log ""

PASS_RATE=$(echo "scale=2; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc 2>/dev/null || echo "N/A")
log "Pass Rate:    ${PASS_RATE}%"
log ""

log "Full log saved to: $LOG_FILE"
log ""

# Deployment readiness assessment
if [ $CRITICAL_FAILURES -eq 0 ]; then
    if [ $WARNINGS -eq 0 ]; then
        log "${GREEN}=========================================="
        log "  ✓ READY FOR DEPLOYMENT"
        log "==========================================${NC}"
        log ""
        log "All pre-deployment checks passed successfully."
        log "You can proceed with deployment to Azure VM."
        exit 0
    else
        log "${YELLOW}=========================================="
        log "  ! READY WITH WARNINGS"
        log "==========================================${NC}"
        log ""
        log "Pre-deployment checks passed with $WARNINGS warning(s)."
        log "Review the warnings above before deploying."
        log ""
        log "You can proceed with deployment, but address warnings if possible."
        exit 0
    fi
else
    log "${RED}=========================================="
    log "  ✗ NOT READY FOR DEPLOYMENT"
    log "==========================================${NC}"
    log ""
    log "Critical failures detected: $CRITICAL_FAILURES"
    log "Please fix the issues above before deploying."
    exit 1
fi
