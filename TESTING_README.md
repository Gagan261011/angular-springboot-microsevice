# Testing Guide - Food Ordering Microservices Application

## Overview

This document describes the comprehensive testing suite for the Food Ordering application. The testing suite includes sanity tests, API tests, health checks, and pre-deployment validation to ensure the application is ready for production deployment on Azure VM.

## Test Scripts

### 1. Quick Start Script (`quick-start.sh`)

**Purpose:** Interactive menu for deploying and testing the application

**Usage:**
```bash
./quick-start.sh
```

**Features:**
- Pre-deployment environment check
- Deploy application with Docker Compose
- Run sanity tests
- Run API tests
- Health monitoring dashboard
- View service logs
- Stop and clean up application

**When to use:** Best for development and first-time deployment

---

### 2. Pre-Deployment Check (`pre-deployment-check.sh`)

**Purpose:** Validates environment and configuration before deployment

**Usage:**
```bash
./pre-deployment-check.sh
```

**Checks:**
- ✓ Docker and Docker Compose installation
- ✓ Required ports availability (4200, 8080, 8081, 8082, 8083, 8761, 8888)
- ✓ Disk space (minimum 5GB, recommended 10GB+)
- ✓ Memory (minimum 2GB, recommended 4GB+)
- ✓ docker-compose.yml validation
- ✓ All Dockerfiles present
- ✓ Maven pom.xml files present
- ✓ Frontend package.json present
- ✓ Configuration files present
- ✓ Network connectivity
- ✓ Security checks (sensitive files, .gitignore)
- ✓ Dependency resolution

**Exit codes:**
- `0` - All checks passed or warnings only
- `1` - Critical failures detected

**When to use:** Before deploying to Azure VM for the first time

---

### 3. Sanity Test (`sanity-test.sh`)

**Purpose:** Comprehensive sanity checks on running application

**Usage:**
```bash
./sanity-test.sh
```

**Test Phases:**

**Phase 1: Core Services**
- Waits for Eureka Server to be ready
- Waits for Config Server to be ready
- Waits for API Gateway to be ready
- Allows 30 seconds for service registration

**Phase 2: Service Status**
- Checks Docker container status
- Verifies Eureka service registrations
- Tests health endpoints for all services

**Phase 3: Connectivity**
- Tests API Gateway connectivity
- Verifies frontend accessibility
- Checks service routing through gateway

**Phase 4: Data Access**
- Tests User Service data access
- Tests Menu Service data access
- Tests Order Service data access

**Expected Results:**
- All services showing status "UP"
- All services registered with Eureka
- All health endpoints returning 200 OK
- Frontend accessible at port 4200
- API Gateway routing working

**When to use:** After deploying the application to verify basic functionality

---

### 4. API Test (`api-test.sh`)

**Purpose:** Comprehensive API endpoint testing with detailed reporting

**Usage:**
```bash
# Standard mode
./api-test.sh

# Verbose mode (shows all responses)
VERBOSE=true ./api-test.sh

# Custom gateway URL
GATEWAY_URL=http://your-server:8080 ./api-test.sh
```

**Test Categories:**

**User Service Tests (6 tests)**
- GET /api/users - Retrieve all users
- POST /api/users - Create new user
- GET /api/users/{id} - Get user by ID
- PUT /api/users/{id} - Update user
- GET /api/users/{id} - Verify update
- GET /api/users/99999 - Test error handling (404)

**Menu Service Tests (9 tests)**
- GET /api/menu - Retrieve all menu items
- POST /api/menu - Create menu item
- GET /api/menu/{id} - Get menu item by ID
- PUT /api/menu/{id} - Update menu item
- GET /api/menu/{id} - Verify update
- DELETE /api/menu/{id} - Delete menu item
- GET /api/menu/{id} - Verify deletion (404)
- GET /api/menu/99999 - Test error handling (404)
- GET /api/menu?category=Pizza - Filter by category

**Order Service Tests (8 tests)**
- GET /api/orders - Retrieve all orders
- POST /api/orders - Create new order
- GET /api/orders/{id} - Get order by ID
- GET /api/orders/user/{userId} - Get orders by user
- PUT /api/orders/{id} - Update order status
- PUT /api/orders/{id} - Cancel order
- GET /api/orders/99999 - Test error handling (404)
- GET /api/orders/user/99999 - Get orders for non-existent user

**Integration Tests (3 tests)**
- Complete order flow (User → Menu → Order)
- Invalid request handling
- Unauthorized access handling

**Performance Tests (1 test)**
- Average response time (10 requests)
- Target: < 1 second per request

**Output:**
- Detailed test results for each endpoint
- Test report file: `api-test-report-YYYYMMDD-HHMMSS.txt`
- Summary with pass/fail counts and pass rate

**When to use:** After sanity tests pass, to verify all API functionality

---

### 5. Health Check (`health-check.sh`)

**Purpose:** Monitor application health and service status

**Usage:**

```bash
# Show health dashboard once
./health-check.sh dashboard

# Continuous monitoring (refreshes every 30 seconds)
./health-check.sh continuous

# Quick health check (script exit code indicates health)
./health-check.sh quick

# Monitor with alerting (logs status changes)
./health-check.sh monitor
```

**Dashboard Information:**
- Core infrastructure status (Eureka, Config, Gateway)
- Business services status (User, Menu, Order)
- Frontend status
- Eureka registrations with instance counts
- Docker container status (if Docker is available)
- Service metrics (memory usage)
- API response times

**Custom Configuration:**
```bash
# Custom service URLs
EUREKA_URL=http://custom-host:8761 ./health-check.sh dashboard

# Custom check interval (in seconds)
CHECK_INTERVAL=60 ./health-check.sh continuous
```

**Alerting:**
When running in monitor mode, status changes are logged to `health-alerts.log`

**When to use:**
- After deployment for continuous monitoring
- During load testing
- In production for health monitoring

---

### 6. Legacy API Test (`test-api.sh`)

**Purpose:** Simple API endpoint verification (legacy script)

**Usage:**
```bash
./test-api.sh
```

**Tests:**
- GET /api/menu/items - Retrieve menu items
- POST /api/orders - Create order
- GET /api/users/1 - Get user by ID

**When to use:** Quick smoke test (use `api-test.sh` for comprehensive testing)

---

## Testing Workflow

### For First-Time Deployment

```bash
# Step 1: Validate environment
./pre-deployment-check.sh

# Step 2: Deploy application
docker compose up -d --build

# Step 3: Wait for initialization (2-3 minutes)
sleep 120

# Step 4: Run sanity tests
./sanity-test.sh

# Step 5: Run API tests
./api-test.sh

# Step 6: Monitor health
./health-check.sh dashboard
```

### For Ongoing Monitoring

```bash
# Continuous health monitoring
./health-check.sh continuous

# Or use the interactive menu
./quick-start.sh
```

### For CI/CD Pipeline

```bash
#!/bin/bash
set -e

# Pre-deployment checks
./pre-deployment-check.sh || exit 1

# Deploy
docker compose up -d --build

# Wait for services
sleep 120

# Run tests
./sanity-test.sh || exit 1
./api-test.sh || exit 1

# Quick health check
./health-check.sh quick || exit 1

echo "Deployment successful and verified!"
```

## Test Reports

### Sanity Test Output

Location: Console output only

Contains:
- Service availability status
- Docker container status
- Eureka registrations
- Health endpoint responses
- API connectivity results
- Database access results
- Final summary with pass/fail counts

### API Test Output

Location:
- Console output
- File: `api-test-report-YYYYMMDD-HHMMSS.txt`

Contains:
- Detailed results for each test
- HTTP method and endpoint
- Expected vs actual status codes
- Response bodies (when verbose or on failure)
- Integration test results
- Performance metrics
- Final summary with pass rate

### Pre-Deployment Check Output

Location:
- Console output
- File: `pre-deployment-check-YYYYMMDD-HHMMSS.log`
- Build log: `pre-deployment-check-YYYYMMDD-HHMMSS.log.build` (if applicable)

Contains:
- Environment validation results
- File system checks
- Docker image build results
- Configuration validation
- Network connectivity tests
- Security checks
- Dependency resolution tests
- Deployment readiness assessment

### Health Check Output

Location: Console output only (continuous monitoring)

Location: `health-alerts.log` (when running in monitor mode)

Contains:
- Real-time service status
- Eureka registrations
- Container status
- Service metrics
- API response times
- Status change alerts (monitor mode)

## Troubleshooting Test Failures

### Sanity Tests Failing

**Symptom:** Services not responding or showing as DOWN

**Solutions:**
1. Check if containers are running: `docker compose ps`
2. View service logs: `docker compose logs [service-name]`
3. Wait longer for initialization (may take up to 3 minutes)
4. Restart services in order:
   ```bash
   docker compose restart eureka-server
   sleep 30
   docker compose restart config-server api-gateway user-service menu-service order-service
   ```

### API Tests Failing

**Symptom:** HTTP errors or timeouts

**Solutions:**
1. Run sanity tests first to ensure services are healthy
2. Check Eureka dashboard: http://localhost:8761
3. Verify services are registered with Eureka
4. Check API Gateway logs: `docker compose logs api-gateway`
5. Test direct service access (if accessible)

### Services Not Registering with Eureka

**Symptom:** Services show as not registered in Eureka

**Solutions:**
1. Verify Eureka is running: `curl http://localhost:8761/actuator/health`
2. Check service environment variables in docker-compose.yml
3. Allow more time for registration (up to 60 seconds)
4. Check service logs for connection errors

### Performance Tests Failing

**Symptom:** Response times over 1 second

**Solutions:**
1. Check system resources: `docker stats`
2. Verify VM has adequate CPU and memory
3. Check for network latency issues
4. Review service logs for errors or slow queries

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Deploy and Test

on:
  push:
    branches: [ main ]

jobs:
  deploy-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Pre-deployment check
        run: ./pre-deployment-check.sh

      - name: Deploy application
        run: docker compose up -d --build

      - name: Wait for services
        run: sleep 120

      - name: Run sanity tests
        run: ./sanity-test.sh

      - name: Run API tests
        run: ./api-test.sh

      - name: Upload test reports
        uses: actions/upload-artifact@v2
        if: always()
        with:
          name: test-reports
          path: |
            api-test-report-*.txt
            pre-deployment-check-*.log
```

## Best Practices

1. **Always run pre-deployment check** before deploying to a new environment
2. **Run sanity tests before API tests** to ensure basic functionality
3. **Monitor health continuously** in production environments
4. **Keep test reports** for debugging and compliance
5. **Review warnings** even if tests pass - they may indicate future issues
6. **Run tests after updates** to ensure compatibility
7. **Use verbose mode** when debugging test failures
8. **Set up alerting** for production monitoring

## Support and Documentation

- Main README: [README.md](README.md)
- Deployment Guide: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- Architecture: See README.md
- API Documentation: See DEPLOYMENT_GUIDE.md

## Test Coverage

Current test coverage:

- ✓ User Service: 6 endpoint tests
- ✓ Menu Service: 9 endpoint tests
- ✓ Order Service: 8 endpoint tests
- ✓ Integration: 3 flow tests
- ✓ Performance: 1 load test
- ✓ Health: 6 service checks
- ✓ Infrastructure: 14 environment checks

**Total: 47+ automated tests**
