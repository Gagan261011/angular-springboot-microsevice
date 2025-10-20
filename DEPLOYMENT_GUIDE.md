# Deployment Guide - Food Ordering Microservices Application

## Table of Contents
1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Azure VM Setup](#azure-vm-setup)
3. [Deployment with Docker Compose](#deployment-with-docker-compose)
4. [Testing and Validation](#testing-and-validation)
5. [Monitoring and Health Checks](#monitoring-and-health-checks)
6. [Troubleshooting](#troubleshooting)

## Pre-Deployment Checklist

Before deploying to your Azure VM, ensure you have:

- [ ] Azure VM with Ubuntu/Debian (recommended: 4GB RAM, 20GB disk)
- [ ] Docker and Docker Compose installed on the VM
- [ ] Ports 4200, 8080, 8081, 8082, 8083, 8761, 8888 available
- [ ] Git installed on the VM
- [ ] SSH access to the Azure VM
- [ ] Domain name or public IP configured (optional)

## Azure VM Setup

### 1. Connect to Your Azure VM

```bash
ssh username@your-azure-vm-ip
```

### 2. Install Docker

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to the docker group
sudo usermod -aG docker $USER

# Apply the new group membership
newgrp docker

# Verify installation
docker --version
docker compose version
```

### 3. Configure Firewall Rules

```bash
# Allow necessary ports
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 4200/tcp  # Frontend
sudo ufw allow 8080/tcp  # API Gateway
sudo ufw allow 8761/tcp  # Eureka (optional, for monitoring)
sudo ufw enable
```

### 4. Clone the Repository

```bash
cd ~
git clone https://github.com/your-repo/angular-springboot-microsevice.git
cd angular-springboot-microsevice
```

## Deployment with Docker Compose

### 1. Run Pre-Deployment Validation

Before deploying, run the pre-deployment check script:

```bash
chmod +x pre-deployment-check.sh
./pre-deployment-check.sh
```

This script will:
- Verify Docker installation
- Check port availability
- Validate docker-compose.yml
- Check disk space and memory
- Verify all required files exist

### 2. Build and Start the Application

```bash
# Build all Docker images (this will take several minutes)
docker compose build --no-cache

# Start all services in detached mode
docker compose up -d

# View logs to monitor startup
docker compose logs -f
```

### 3. Wait for Services to Initialize

The services will take approximately 2-3 minutes to fully initialize. You can monitor the startup process:

```bash
# Watch all services
docker compose logs -f

# Watch specific service
docker compose logs -f eureka-server
docker compose logs -f api-gateway

# Check running containers
docker compose ps
```

### 4. Verify Service Registration

Once services are running, check Eureka dashboard to verify all services are registered:

```bash
# Open in browser or use curl
curl http://localhost:8761
```

You should see:
- api-gateway
- config-server
- user-service
- menu-service
- order-service

## Testing and Validation

### 1. Run Sanity Tests

The sanity test script performs comprehensive checks on all services:

```bash
chmod +x sanity-test.sh
./sanity-test.sh
```

This script will:
- Wait for all services to be ready
- Check Eureka registrations
- Verify health endpoints
- Test API Gateway connectivity
- Check frontend accessibility
- Validate database connections

**Expected Output:**
- All services should show as "UP"
- All services should be registered with Eureka
- All health endpoints should return 200 OK

### 2. Run API Tests

The API test script performs comprehensive endpoint testing:

```bash
chmod +x api-test.sh
./api-test.sh
```

This script will test:
- User Service: GET, POST, PUT operations
- Menu Service: GET, POST, PUT, DELETE operations
- Order Service: GET, POST, PUT operations
- Integration: Complete order flow
- Performance: Response time measurements

**Expected Results:**
- All API endpoints should respond correctly
- CRUD operations should work
- Integration tests should pass
- Response times should be under 1 second

### 3. Monitor Application Health

Use the health check script for continuous monitoring:

```bash
chmod +x health-check.sh

# Show dashboard once
./health-check.sh dashboard

# Continuous monitoring (refreshes every 30 seconds)
./health-check.sh continuous

# Quick health check (returns 0 if all healthy)
./health-check.sh quick

# Monitor with alerting (logs status changes)
./health-check.sh monitor
```

## Service URLs

Once deployed, access the application at:

| Service | URL | Description |
|---------|-----|-------------|
| Frontend | http://your-vm-ip:4200 | Angular application |
| API Gateway | http://your-vm-ip:8080 | Main API endpoint |
| Eureka Dashboard | http://your-vm-ip:8761 | Service registry |
| Config Server | http://your-vm-ip:8888 | Configuration server |
| User Service | http://your-vm-ip:8081 | Direct access (optional) |
| Menu Service | http://your-vm-ip:8082 | Direct access (optional) |
| Order Service | http://your-vm-ip:8083 | Direct access (optional) |

**Note:** In production, all API calls should go through the API Gateway (port 8080).

## API Examples

### User Management

```bash
# Get all users
curl http://your-vm-ip:8080/api/users

# Create a user
curl -X POST http://your-vm-ip:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com","phone":"1234567890","address":"123 Main St"}'

# Get user by ID
curl http://your-vm-ip:8080/api/users/1
```

### Menu Management

```bash
# Get all menu items
curl http://your-vm-ip:8080/api/menu

# Create a menu item
curl -X POST http://your-vm-ip:8080/api/menu \
  -H "Content-Type: application/json" \
  -d '{"name":"Pizza","description":"Delicious pizza","price":12.99,"category":"Food","available":true}'

# Get menu item by ID
curl http://your-vm-ip:8080/api/menu/1

# Delete menu item
curl -X DELETE http://your-vm-ip:8080/api/menu/1
```

### Order Management

```bash
# Get all orders
curl http://your-vm-ip:8080/api/orders

# Create an order
curl -X POST http://your-vm-ip:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":1,"items":[{"menuItemId":1,"quantity":2}],"deliveryAddress":"123 Main St","status":"PENDING"}'

# Get orders for a user
curl http://your-vm-ip:8080/api/orders/user/1
```

## Monitoring and Health Checks

### Docker Container Status

```bash
# View running containers
docker compose ps

# View container logs
docker compose logs -f [service-name]

# View resource usage
docker stats

# Restart a service
docker compose restart [service-name]
```

### Health Endpoints

Each microservice exposes health endpoints:

```bash
# Eureka Server
curl http://localhost:8761/actuator/health

# Config Server
curl http://localhost:8888/actuator/health

# API Gateway
curl http://localhost:8080/actuator/health

# User Service
curl http://localhost:8081/actuator/health

# Menu Service
curl http://localhost:8082/actuator/health

# Order Service
curl http://localhost:8083/actuator/health
```

### Continuous Monitoring

Set up continuous monitoring with cron:

```bash
# Edit crontab
crontab -e

# Add health check every 5 minutes
*/5 * * * * /path/to/health-check.sh quick || echo "Health check failed" | mail -s "Alert" admin@example.com
```

## Troubleshooting

### Services Not Starting

1. **Check Docker logs:**
   ```bash
   docker compose logs [service-name]
   ```

2. **Common issues:**
   - Services starting before Eureka: Wait 30 seconds and restart
     ```bash
     docker compose restart [service-name]
     ```
   - Out of memory: Increase VM memory or add swap
   - Port conflicts: Check if ports are already in use

### Services Not Registering with Eureka

1. **Check Eureka is running:**
   ```bash
   curl http://localhost:8761/actuator/health
   ```

2. **Check service logs for connection errors:**
   ```bash
   docker compose logs api-gateway
   docker compose logs user-service
   ```

3. **Restart services in order:**
   ```bash
   docker compose restart eureka-server
   sleep 30
   docker compose restart config-server api-gateway user-service menu-service order-service
   ```

### API Gateway Returns 503

This usually means backend services aren't registered:

1. **Check Eureka dashboard:** http://localhost:8761
2. **Verify service health endpoints**
3. **Wait for service registration** (can take up to 60 seconds)

### Frontend Not Loading

1. **Check if container is running:**
   ```bash
   docker compose ps frontend
   ```

2. **Check nginx logs:**
   ```bash
   docker compose logs frontend
   ```

3. **Verify port 4200 is accessible:**
   ```bash
   curl http://localhost:4200
   ```

### Database Connection Issues

The application uses in-memory databases by default. If you see database errors:

1. Check service logs
2. Verify no external database configuration is present
3. Restart the affected service

## Stopping and Cleaning Up

### Stop All Services

```bash
# Stop services (keeps data)
docker compose stop

# Stop and remove containers (keeps images)
docker compose down

# Stop, remove containers and volumes (clean slate)
docker compose down -v

# Remove everything including images
docker compose down -v --rmi all
```

### View Disk Usage

```bash
# Check Docker disk usage
docker system df

# Clean up unused resources
docker system prune -a
```

## Production Considerations

### 1. Security

- [ ] Use HTTPS with SSL/TLS certificates
- [ ] Implement authentication and authorization
- [ ] Use environment variables for sensitive data
- [ ] Restrict Eureka dashboard access
- [ ] Set up firewall rules properly

### 2. Performance

- [ ] Configure resource limits in docker-compose.yml
- [ ] Set up load balancing for API Gateway
- [ ] Configure caching where appropriate
- [ ] Monitor and optimize slow queries

### 3. High Availability

- [ ] Run multiple instances of services
- [ ] Use external service registry (Eureka HA)
- [ ] Implement circuit breakers
- [ ] Set up database replication

### 4. Monitoring

- [ ] Set up centralized logging (ELK stack)
- [ ] Configure application metrics (Prometheus)
- [ ] Set up alerting (Grafana, PagerDuty)
- [ ] Monitor resource usage

### 5. Backup

- [ ] Back up configuration files
- [ ] Back up database (if using persistent storage)
- [ ] Document recovery procedures
- [ ] Test disaster recovery plan

## Support

For issues and questions:

1. Check the [README.md](README.md) for architecture details
2. Review service logs: `docker compose logs [service-name]`
3. Run diagnostics: `./pre-deployment-check.sh`
4. Check health status: `./health-check.sh dashboard`

## Quick Reference Commands

```bash
# Start application
docker compose up -d

# View logs
docker compose logs -f

# Check health
./health-check.sh quick

# Run tests
./sanity-test.sh && ./api-test.sh

# Stop application
docker compose down

# Restart single service
docker compose restart [service-name]

# View resource usage
docker stats

# Clean up
docker system prune -a
```
